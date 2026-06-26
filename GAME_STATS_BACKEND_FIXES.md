# Game Stats — backend fixes (matches Flutter app)

**For:** Laravel backend dev  
**App:** `darcity` Flutter coach live console  
**Base URL:** `{API_BASE}/api` (see `lib/config/api_config.dart`)  
**Auth:** `Authorization: Bearer {coach_token}` + `Accept: application/json`

This doc reflects **what the mobile app actually sends and parses today** — not a wish list.

---

## Coach flow (when API is called)

| Step | Screen | API call? |
|------|--------|-----------|
| 1 | Pick match | `GET .../matches/{id}/active-session` (resume only) |
| 2 | Pick match squad (5–12) | **No API** — local only until step 3 |
| 3 | Pick starting 5 + captain → **Start Game** | `POST .../sessions` |
| 4 | Live console | `GET .../sessions/{id}` on SUB tap; stats/subs → `POST .../events` |

**Important:** Squad is sent on **Start Game**, not on step 2 Continue.

---

## Problem summary (from live testing)

| Issue | Symptom in app |
|-------|----------------|
| Create session only saves 5 players | SUB bench empty; session `roster` = 5 |
| Session GET omits full lineup | `match_lineup` / `match_lineups` null; `bench: []` |
| No match-lineups route | All lineup GET paths return **404** |
| Substitution not in action enum | Snackbar: **"Invalid action"** after picking out + in |

---

## 1. Create session — save full match squad

**`POST /api/coach/game-stats/sessions`**

### Request (exact body from app)

```json
{
  "match_id": 77,
  "match_lineup_player_ids": [88, 89, 36, 82, 57, 37, 83, 84, 54, 55, 85],
  "starting_five_player_ids": [88, 89, 36, 82, 57],
  "captain_player_id": 88
}
```

### Validation rules

| Field | Rules |
|-------|--------|
| `match_id` | required |
| `match_lineup_player_ids` | required, **5–12** unique player IDs |
| `starting_five_player_ids` | required, **exactly 5**, subset of `match_lineup_player_ids` |
| `captain_player_id` | required, must be in `starting_five_player_ids` |

### DB (`match_lineups` table)

One row per player in `match_lineup_player_ids`:

| Column | Value |
|--------|--------|
| `match_id` | from request |
| `player_id` | each ID in `match_lineup_player_ids` |
| `is_starting` | 1 if in `starting_five_player_ids` |
| `is_on_court` | 1 if in `starting_five_player_ids` (same 5 at tip-off) |
| `is_captain` | 1 for `captain_player_id` only |

**Verify:** `COUNT(*)` for `match_id` = length of `match_lineup_player_ids` (e.g. 11), not 5.

### Response

Return full session snapshot (see section 2). App unwraps `data.session` or top-level session object.

On duplicate live session: **409** — app then calls `GET active-session` and resumes.

---

## 2. Get session — return full lineup for SUB picker

**`GET /api/coach/game-stats/sessions/{sessionId}`**

App uses this on **SUB button tap** to refresh players before the picker opens.

### What app reads (priority order)

1. **`match_lineups`** or **`match_lineup_players`** — array of table rows (preferred)
2. Else **`match_lineup`** or **`roster`** — full squad list
3. **`on_court`** — 5 active players
4. **`bench`** — squad minus on court (or app derives bench if lineup is complete)

### `match_lineups` row shape (app parser)

Each row:

```json
{
  "player_id": 36,
  "is_on_court": 0,
  "is_starting": 0,
  "is_captain": 0,
  "player": {
    "id": 36,
    "first_name": "Ethan",
    "last_name": "Billy",
    "jersey_number": "10",
    "position": "Shooting Guard",
    "passport_picture": "..."
  }
}
```

- `is_on_court`: `true`, `1`, or `"1"` → player is active on court
- `player` nested object preferred; flat person fields also work

If `match_lineups` is present and non-empty, app builds:
- **lineup** = all rows
- **on_court** = rows where `is_on_court`
- **bench** = lineup − on_court

### Minimum fix if you only change session JSON

```json
{
  "id": 9001,
  "match_id": 77,
  "roster": [ "...all 11 players..." ],
  "on_court": [ "...5 players..." ],
  "bench": [ "...6 players..." ],
  "match_lineups": [ "...all rows with flags..." ]
}
```

**Do not** return only 5 in `roster` when 11 are in `match_lineups`.

### What we saw broken (match 78)

```json
{
  "match_lineup": null,
  "match_lineups": null,
  "roster": [ "...5 only..." ],
  "on_court": [ "...5..." ],
  "bench": [],
  "bench_player_ids": []
}
```

That produces **bench: 0** in the app → SUB unusable.

---

## 3. Optional GET — match lineup by match id

App tries these paths (all **404** today). Implement **one**:

```
GET /api/coach/game-stats/matches/{matchId}/match-lineups   ← preferred
GET /api/coach/game-stats/matches/{matchId}/match_lineups
GET /api/coach/game-stats/matches/{matchId}/lineup
```

Return: JSON **array** of `match_lineups` rows (same shape as section 2), or object with key `data` / `match_lineups` / `lineup`.

---

## 4. Active session (resume)

**`GET /api/coach/game-stats/matches/{matchId}/active-session`**

```json
{ "data": { "session_id": 9001, "status": "live", "match_id": 77 } }
```

No session:

```json
{ "data": null }
```

App also accepts top-level `session_id` without `data` wrapper.

---

## 5. Substitution — fix "Invalid action"

**`POST /api/coach/game-stats/sessions/{sessionId}/events`**

Triggered after coach picks **player out** (on court) then **player in** (bench).

### Request body (exact from app)

App tries `action` in this order until one succeeds: **`substitution`** → **`sub`** → **`substitute`**

```json
{
  "action": "substitution",
  "player_id": 88,
  "secondary_player_id": 36,
  "player_out_id": 88,
  "player_in_id": 36,
  "clock_remaining_seconds": 600,
  "clock_running": true
}
```

| Field | Meaning |
|-------|---------|
| `player_id` | player going **out** (same as `player_out_id`) |
| `secondary_player_id` | player coming **in** (same as `player_in_id`) |
| `player_out_id` / `player_in_id` | aliases for same values |

### Backend must

1. Accept **`substitution`** as a valid `action` (primary — app sends this first)
2. Validate: `player_out_id` is on court; `player_in_id` is in match lineup but not on court
3. Update `match_lineups.is_on_court` (0 for out, 1 for in)
4. Return **full session snapshot** (same shape as GET session)

**Current error:** `Invalid action` = `substitution` not in your allowed actions list.

### Feed (optional but spec-aligned)

One logical sub → two feed lines: `SUB OUT` then `SUB IN`.

---

## 6. Other stat actions (already used by app)

For non-sub events, app sends:

```json
{
  "action": "score_2_made",
  "player_id": 12,
  "clock_remaining_seconds": 580,
  "clock_running": true
}
```

| `action` values |
|-----------------|
| `score_2_made`, `score_2_miss` |
| `score_3_made`, `score_3_miss` |
| `score_1_made`, `score_1_miss` |
| `def_reb`, `off_reb`, `turnover`, `steal`, `assist`, `block`, `foul` |
| `substitution` (see above) |

---

## 7. Quick test checklist

```bash
# 1. Create with 11 players
POST /api/coach/game-stats/sessions
# → DB: 11 rows in match_lineups for match_id

# 2. Read session
GET /api/coach/game-stats/sessions/{id}
# → bench.length === 6 (11 - 5)

# 3. Substitute
POST /api/coach/game-stats/sessions/{id}/events
# body: action substitution, player_out_id, player_in_id
# → 200, not "Invalid action"
# → is_on_court updated in DB
```

---

## 8. Files in Flutter repo (for Cursor cross-check)

| File | Purpose |
|------|---------|
| `lib/features/game_stats/services/game_stats_service.dart` | All API calls + payloads |
| `lib/features/game_stats/models/game_stats_api_session.dart` | Session JSON parsing |
| `lib/features/game_stats/models/game_stats_match_lineup_snapshot.dart` | `match_lineups` row parsing |
| `lib/features/game_stats/screens/game_stats_starting_lineup_screen.dart` | When create session fires |

---

**One-liner for prioritization:**  
Save all `match_lineup_player_ids` on create, return them on GET session (or match-lineups endpoint), and add `substitution` to the events action enum.
