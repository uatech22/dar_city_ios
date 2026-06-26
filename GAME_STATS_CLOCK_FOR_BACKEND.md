# Game Stats — Clock / Timer (Backend fix required)

**To:** Backend developer  
**From:** Dar City mobile team  
**Re:** Live stats session clock behaviour on `POST .../events`  
**Related spec:** [GAME_STATS_API_FROM_BACKEND.md](./GAME_STATS_API_FROM_BACKEND.md)

---

## Summary

The coach live console runs the **game clock on the tablet** (ticks every second while running). When the coach logs a stat (points, rebound, foul, etc.), the app calls:

`POST /api/coach/game-stats/sessions/{sessionId}/events`

**Problem we saw:** After logging any stat (not only fouls), the session clock in the database resets to the period default (e.g. `600` seconds / 10:00). That is wrong.

**Agreed product rules:**

| Action | Effect on clock |
|--------|-----------------|
| Score (made/miss), rebound, assist, steal, block, turnover, substitution | **No change** — keep current time and running/paused state |
| **Foul** | **Pause only** — set `clock_running = false`, **do not** reset `clock_remaining_seconds` |
| Next period (menu) / `PATCH .../period` with `advance` | Reset to regulation (600s) or OT (300s), pause |
| Edit clock / play–pause (`PATCH .../clock`) | Apply what the client sends |
| Period chip H1–H4 / ET on mobile | **Feed filter only** — does **not** call period API |

---

## What the mobile app sends now (updated)

Every `POST .../events` request includes the **coach’s current clock** from the device:

### Example — 3-point make (clock running at 7:42)

```http
POST /api/coach/game-stats/sessions/9001/events
Authorization: Bearer {coach_token}
Content-Type: application/json
```

```json
{
  "action": "score_3_made",
  "player_id": 12,
  "clock_remaining_seconds": 462,
  "clock_running": true
}
```

### Example — foul (pause, same time)

```json
{
  "action": "foul",
  "player_id": 7,
  "clock_remaining_seconds": 462,
  "clock_running": false
}
```

### Example — substitution

```json
{
  "action": "substitution",
  "player_out_id": 7,
  "player_in_id": 9,
  "clock_remaining_seconds": 455,
  "clock_running": true
}
```

### Fields

| Field | Type | Required | Meaning |
|-------|------|----------|---------|
| `action` | string | yes | See main API spec (`score_2_made`, `foul`, etc.) |
| `player_id` | integer | yes* | *Not used for `substitution` |
| `player_out_id` / `player_in_id` | integer | yes for `substitution` | |
| `clock_remaining_seconds` | integer | **yes (mobile always sends)** | Seconds left on coach’s timer at tap time (0–3600) |
| `clock_running` | boolean | **yes (mobile always sends)** | `false` on foul; otherwise current run state |

---

## What the backend must do

### 1. On `POST .../events` — persist client clock

When the request body includes `clock_remaining_seconds` and `clock_running`:

1. **Save them on the session** (`game_stats_sessions` or equivalent).
2. **Do not** overwrite with period default (600 / 300) unless the action is explicitly a period change.
3. Store the same values on the **event row** (for play-by-play: “stat at 07:42 in H2”).

**Pseudocode:**

```
on POST events:
  record stat event with period, player, etc.

  if request has clock_remaining_seconds:
    session.clock_remaining_seconds = request.clock_remaining_seconds
  if request has clock_running:
    session.clock_running = request.clock_running

  if action == 'foul':
    session.clock_running = false   # enforce pause; do NOT reset seconds

  # WRONG — do not do this on normal stats:
  # session.clock_remaining_seconds = period_default(session.period)
```

### 2. Response must reflect saved clock

The `session` object in the response should return the **stored** clock, not a reset value:

```json
{
  "data": {
    "session": {
      "clock_remaining_seconds": 462,
      "clock_label": "07:42",
      "clock_running": true,
      "...": "..."
    }
  }
}
```

If the response resets the clock to `600` while the request sent `462`, the mobile app **ignores** that for the UI (we preserve local time on stat events), but **reports and DB will still be wrong** until the API is fixed.

### 3. When clock **should** reset

Only in these cases:

| Endpoint / action | Clock behaviour |
|-------------------|-----------------|
| `PATCH .../period` with `"advance": true` | `period += 1`, set seconds to 600 (H1–H4) or 300 (OT), `clock_running = false` |
| `PATCH .../period` with `"period": N` | Jump period, same reset rules as above |
| `POST .../sessions` (new session) | Initial period 1, 600 seconds, not running |

**Not** on: `score_*`, `def_reb`, `off_reb`, `assist`, `steal`, `block`, `turnover`, `substitution`.

### 4. Foul rule (server-side)

Even if the client forgets to send `clock_running: false`, the server should:

- Set `clock_running = false` when `action == 'foul'`
- **Keep** `clock_remaining_seconds` unchanged (no reset)

---

## How the mobile clock works (for context)

1. Coach starts/pauses with play–pause button → `PATCH .../clock` (`toggle` or explicit `clock_running`).
2. Coach edits time → `PATCH .../clock` with `clock_remaining_seconds`.
3. While running, the app decrements **locally** every 1 second (no API call each second).
4. On each stat tap, the app sends the **current** seconds + running state in `POST .../events`.
5. Play-by-play feed shows `clock_label` from each event (e.g. `07:42`).

So the **tablet is the source of truth for the clock between PATCH calls**; events must **carry** that state to the server so DB and reports stay in sync.

---

## Quick test checklist (backend)

1. Start session → clock `600`, not running.
2. `PATCH .../clock` → `clock_running: true` → clock counts down on client.
3. `POST .../events` score at ~`550` seconds → DB session still ~`550`, not `600`.
4. `POST .../events` foul → `clock_running = false`, seconds still ~`550`.
5. `POST .../events` another score → seconds unchanged, running stays `false`.
6. `PATCH .../period` advance → seconds reset to `600` (or `300` in OT), not running.
7. `GET .../report` → events show correct `clock_label` per action.

---

## Optional (later)

- Background `PATCH .../clock` every 30s while running for multi-device sync — **not required for v1**.
- WebSocket — **not required for v1**; one coach tablet is enough.

---

## Contact

If the request shape needs to differ (e.g. nested `client_clock` object), tell us and we can adjust the Flutter app — but the server **must** stop resetting the timer on normal stat events and must **honour** foul = pause only.

**Mobile implementation:** `lib/features/game_stats/services/game_stats_service.dart` → `postEvent()`  
**Spec reference:** [GAME_STATS_API_FROM_BACKEND.md](./GAME_STATS_API_FROM_BACKEND.md)
