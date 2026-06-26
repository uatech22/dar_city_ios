# Dar City — Game Stats API (Coach Live Console)

**Status:** Mobile UI complete (local/dummy engine). Backend endpoints below are required before production wiring.  
**Companion spec:** [API_SPEC_V2.md](./API_SPEC_V2.md) (shared auth, wrappers, `Person` model)  
**Base URL:** `{API_BASE}/api` — same as `ApiConfig.baseUrl` in the Flutter app  
**Auth:** `Authorization: Bearer {coach_token}` on every route in this document  
**Content-Type:** `application/json`  
**Accept:** `application/json`

---

## Mobile flow (3 screens → 1 overlay)

| Step | Screen | Current data source | After wiring |
|------|--------|---------------------|--------------|
| 1 | Match select | `GET /upcoming-matches` + `GET /finished-matches` (client-filtered) | Same + optional dedicated matches endpoint |
| 2 | Starting lineup (pick 5) | `GET /coach/game-stats/matches/{matchId}/roster` | Same + `POST` session |
| 3 | Live console | In-memory `GameStatsLiveController` | Session APIs (events, clock, period, undo) |
| — | Game report (menu) | Built locally from controller | `GET` report or derived from session state |

**Entry:** Coach → More → Game Day → **Game Stats**

---

## Response wrapper (required — same as V2)

**Single object:**
```json
{ "data": { ... } }
```

**List:**
```json
{ "data": [ ... ] }
```

**Error (4xx / 5xx):**
```json
{
  "message": "Human readable error",
  "errors": {
    "field_name": ["Validation message"]
  }
}
```

---

## Business rules (server must enforce)

1. **Coach-only** — reject non-coach tokens with `403`.
2. **Dar City only** — track **DC team score + DC player stats** only. Opponent box score is out of scope for v1 mobile UI.
3. **On-court validation** — scoring and non-sub stats require `player_id` to be in `on_court_player_ids`. Substitutions require `player_out_id` on court and `player_in_id` on bench.
4. **Starting five** — exactly **5** unique player IDs from the match roster when creating a session.
5. **Roster** — only assignable players (`is_active`, not on loan, etc.) — mirror `Person.isAssignableForDrills` filtering on the app.
6. **Foul auto-pause** — recording a `FOUL` event must set `clock_running` to `false`.
7. **Period clock defaults**
   - Regulation periods **1–4:** default `600` seconds (10:00) when period advances or is set.
   - Overtime periods **≥ 5:** default `300` seconds (5:00).
8. **Advance period** — increment period, reset clock to period default, set `clock_running` to `false`.
9. **Undo** — revert the **last committed event** and full derived state (score, on-court, feed, player totals). Return `409` if nothing to undo.
10. **One live session per match** — a match may have at most one `status: "live"` session. Return existing session or `409` on duplicate start (see §4).
11. **Miss events** — do not add team or player points.
12. **Substitution** — one logical action creates **two** feed rows: `SUB OUT` (player leaving) then `SUB IN` (player entering). Swap on-court / bench lists atomically.

---

## Shared enums

### Session status
| Value | Meaning |
|-------|---------|
| `live` | Active stats session |
| `paused` | Optional — clock stopped but session not ended |
| `ended` | Finalized (read-only report) |

### Stat event `action` (request body)

| `action` | Points | Pauses clock | Notes |
|----------|--------|--------------|-------|
| `score_2_made` | +2 DC | no | |
| `score_2_miss` | 0 | no | `is_miss: true` in feed |
| `score_3_made` | +3 DC | no | |
| `score_3_miss` | 0 | no | |
| `score_1_made` | +1 DC | no | Free throw made (`FT`) |
| `score_1_miss` | 0 | no | |
| `def_reb` | 0 | no | |
| `off_reb` | 0 | no | |
| `turnover` | 0 | no | |
| `steal` | 0 | no | |
| `assist` | 0 | no | |
| `block` | 0 | no | |
| `foul` | 0 | **yes** | |
| `substitution` | 0 | no | Requires `player_out_id` + `player_in_id` |

### Feed display `stat` labels (stored on each event)

| Internal action | Feed `stat` string |
|-----------------|-------------------|
| `score_2_made` | `2PT` |
| `score_2_miss` | `2PT MISS` |
| `score_3_made` | `3PT` |
| `score_3_miss` | `3PT MISS` |
| `score_1_made` | `FT` |
| `score_1_miss` | `FT MISS` |
| `def_reb` | `DEF REB` |
| `off_reb` | `OFF REB` |
| `turnover` | `TO` |
| `steal` | `STL` |
| `assist` | `ASST` |
| `block` | `BLK` |
| `foul` | `FOUL` |
| sub out row | `SUB OUT` |
| sub in row | `SUB IN` |

### Period labels (server may store `period` integer; app formats label)

| `period` | `period_label` |
|----------|----------------|
| 1–4 | `H1` … `H4` |
| 5 | `OT` |
| 6+ | `OT2`, `OT3`, … |

---

# Existing endpoints reused (no new work unless you want a filter)

## `GET /upcoming-matches`

Used by match select (via `MatchService.fetchScheduleCalendar`). App keeps fixtures that are **not finished** and **not before today**.

**Response `200` (each item in `data`):**
```json
{
  "id": 42,
  "scheduled_at": "2026-06-22 18:00:00",
  "venue": { "name": "National Indoor Stadium" },
  "home_team": { "name": "Dar City Basketball Club", "short_name": "DC" },
  "away_team": { "name": "UDSM Titans", "short_name": "UDSM" },
  "home_score": null,
  "away_score": null,
  "status": "scheduled"
}
```

| Field | Type | Required |
|-------|------|----------|
| `id` | integer | yes |
| `scheduled_at` | string (datetime) | yes |
| `venue` | object or string | yes |
| `home_team` | object or string | yes |
| `away_team` | object or string | yes |
| `home_score` | integer \| null | no |
| `away_score` | integer \| null | no |
| `status` | string | no (`scheduled`, `finished`, `final`, …) |

## `GET /finished-matches`

Merged into the same calendar list. App treats `status` in `finished` / `final` / `completed` OR both scores present as **past** → hidden from game-stats picker.

---

# New Game Stats endpoints

---

## Screen 1 — Match select (optional dedicated list)

### `GET /coach/game-stats/matches` *(optional)*

Returns only fixtures eligible for live stats (today + upcoming, not finished). If omitted, mobile keeps using `/upcoming-matches` filtering.

**Query params:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `from` | date `YYYY-MM-DD` | today | Include matches on/after this date |
| `limit` | integer | 50 | Max rows |

**Response `200`:**
```json
{
  "data": [
    {
      "id": 42,
      "scheduled_at": "2026-06-22 18:00:00",
      "venue": { "name": "National Indoor Stadium" },
      "home_team": { "name": "Dar City Basketball Club", "short_name": "DC" },
      "away_team": { "name": "UDSM Titans", "short_name": "UDSM" },
      "status": "scheduled",
      "has_live_session": false,
      "live_session_id": null
    }
  ]
}
```

| Field | Type | Required |
|-------|------|----------|
| `has_live_session` | boolean | no |
| `live_session_id` | integer \| null | no |

---

## Screen 2 — Starting lineup

### `GET /coach/game-stats/matches/{matchId}/roster`

**Already called by the app** (`GameStatsService.fetchMatchRoster`). Falls back to `/team/players` if this 404s or returns empty.

**Request:** none

**Response `200`:**
```json
{
  "data": [
    {
      "id": 12,
      "first_name": "Hasheem",
      "last_name": "Thabeet",
      "position": "Center",
      "role_in_team": "player",
      "jersey_number": 23,
      "passport_picture": "players/hasheem.jpg",
      "nationality": "Tanzania",
      "is_active": true,
      "on_loan": false,
      "transfer_status": "active"
    }
  ]
}
```

Use the same **Person** field names as [API_SPEC_V2.md](./API_SPEC_V2.md). Exclude loaned/inactive players server-side when possible.

**Errors:**
| Code | When |
|------|------|
| `404` | Match not found |
| `403` | Not coach / no access |

---

### `GET /coach/game-stats/matches/{matchId}/active-session`

Check for an in-progress session before showing lineup (resume flow).

**Response `200` — session exists:**
```json
{
  "data": {
    "session_id": 9001,
    "status": "live",
    "match_id": 42,
    "created_at": "2026-06-22T17:55:00Z"
  }
}
```

**Response `200` — no session:**
```json
{
  "data": null
}
```

---

### `POST /coach/game-stats/sessions`

Create a live session after coach picks **exactly 5** starters.

**Request body:**
```json
{
  "match_id": 42,
  "starting_five_player_ids": [12, 7, 3, 15, 22]
}
```

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `match_id` | integer | yes | Must be upcoming/today match |
| `starting_five_player_ids` | integer[] | yes | Length **exactly 5**, unique, subset of roster |

**Response `201`:**
```json
{
  "data": {
    "session": { "...full GameStatsSession object — see § Models..." }
  }
}
```

**Errors:**
| Code | When |
|------|------|
| `409` | Live session already exists for this match |
| `422` | Wrong starter count, player not on roster, match finished |

---

## Screen 3 — Live console

All live actions return the **full session snapshot** so the app can replace local state in one round-trip.

### `GET /coach/game-stats/sessions/{sessionId}`

Load / refresh full session (reconnect, pull-to-refresh).

**Response `200`:**
```json
{
  "data": {
    "session": { "...GameStatsSession..." }
  }
}
```

**Recommended poll interval on live console:** none (optimistic POST per tap). Match select uses **50s** slow refresh per `ApiConfig.refreshIntervalSlow`.

---

### `POST /coach/game-stats/sessions/{sessionId}/events`

Record one coach action (score, miss, stat, substitution).

**Request body — scoring / stat:**
```json
{
  "action": "score_3_made",
  "player_id": 12
}
```

**Request body — substitution:**
```json
{
  "action": "substitution",
  "player_out_id": 12,
  "player_in_id": 9
}
```

| Field | Type | Required |
|-------|------|----------|
| `action` | string | yes — see enum table |
| `player_id` | integer | yes for all except `substitution` |
| `player_out_id` | integer | required for `substitution` |
| `player_in_id` | integer | required for `substitution` |

**Response `200`:**
```json
{
  "data": {
    "session": { "...updated GameStatsSession..." },
    "event": {
      "id": 55001,
      "action": "score_3_made",
      "stat": "3PT",
      "player_id": 12,
      "player_name": "H. Thabeet",
      "jersey_number": 23,
      "period": 2,
      "period_label": "H2",
      "clock_label": "07:42",
      "clock_remaining_seconds": 462,
      "is_miss": false,
      "count": 3,
      "created_at": "2026-06-22T18:22:11Z"
    }
  }
}
```

**Errors:**
| Code | `message` example |
|------|-------------------|
| `422` | `Player must be on court.` |
| `422` | `Pick a player from the bench.` |
| `409` | `Session has ended.` |

---

### `POST /coach/game-stats/sessions/{sessionId}/undo`

Revert the last event.

**Request:** empty body `{}`

**Response `200`:**
```json
{
  "data": {
    "session": { "...reverted GameStatsSession..." },
    "undone_event_id": 55001
  }
}
```

**Response `409`:**
```json
{
  "message": "Nothing to undo."
}
```

---

### `PATCH /coach/game-stats/sessions/{sessionId}/clock`

Toggle, set remaining time, or explicit run state.

**Request — toggle (menu / play-pause button):**
```json
{
  "toggle": true
}
```

**Request — set time (edit clock dialog):**
```json
{
  "clock_remaining_seconds": 600,
  "clock_running": false
}
```

**Request — start/stop explicitly:**
```json
{
  "clock_running": true
}
```

| Field | Type | Required |
|-------|------|----------|
| `toggle` | boolean | no — flips `clock_running` |
| `clock_remaining_seconds` | integer | no — `0` … `3600` |
| `clock_running` | boolean | no |

**Response `200`:**
```json
{
  "data": {
    "session": { "...updated session with clock fields..." }
  }
}
```

**Note:** Client ticks clock locally every 1s while running. Server is source of truth on each PATCH/POST. Optional: accept `PATCH` every 30s with `clock_remaining_seconds` for drift correction.

---

### `PATCH /coach/game-stats/sessions/{sessionId}/period`

Advance or jump to a period (feed filter + game period).

**Request — next period (menu):**
```json
{
  "advance": true
}
```

**Request — set period (feed period chip H1–H4 / ET):**
```json
{
  "period": 3
}
```

| Field | Type | Required |
|-------|------|----------|
| `advance` | boolean | no — `period += 1`, reset clock, pause |
| `period` | integer | no — `>= 1`; resets clock to regulation/OT default, pauses |

**Response `200`:**
```json
{
  "data": {
    "session": { "...updated session..." }
  }
}
```

---

### `GET /coach/game-stats/sessions/{sessionId}/feed`

Optional paginated play-by-play (if feed list grows large).

**Query:**

| Param | Type | Default |
|-------|------|---------|
| `period` | integer | all — use `5` for extra-time filter (period ≥ 5) |
| `page` | integer | 1 |
| `per_page` | integer | 50 |

**Response `200`:**
```json
{
  "data": {
    "events": [ { "...GameStatsFeedEvent..." } ],
    "meta": { "page": 1, "per_page": 50, "total": 128 }
  }
}
```

Mobile can skip this initially and use `session.feed` from the main session object.

---

### `GET /coach/game-stats/sessions/{sessionId}/report`

Game report overlay (menu → **View game report**).

**Response `200`:**
```json
{
  "data": {
    "match_id": 42,
    "opponent_label": "UDSM",
    "team_score": 68,
    "period": 4,
    "period_label": "H4",
    "clock_label": "02:15",
    "clock_running": false,
    "team_totals": {
      "points": 68,
      "fg_made": 24,
      "fg_att": 52,
      "ft_made": 14,
      "ft_att": 18,
      "rebounds": 31,
      "assists": 15,
      "steals": 8,
      "blocks": 4,
      "turnovers": 12,
      "fouls": 18
    },
    "players": [
      {
        "player": { "...Person..." },
        "points": 22,
        "fg_made": 8,
        "fg_att": 14,
        "ft_made": 4,
        "ft_att": 5,
        "def_reb": 3,
        "off_reb": 1,
        "assists": 4,
        "steals": 2,
        "blocks": 1,
        "turnovers": 2,
        "fouls": 3,
        "on_court": true
      }
    ]
  }
}
```

Can be computed from session + events; no separate storage required if `GET session` is complete.

---

### `POST /coach/game-stats/sessions/{sessionId}/end`

Finalize session (optional for v1 — mobile can simply leave screen).

**Request:**
```json
{
  "finalize": true
}
```

**Response `200`:**
```json
{
  "data": {
    "session_id": 9001,
    "status": "ended",
    "team_score": 68,
    "ended_at": "2026-06-22T20:05:00Z"
  }
}
```

---

# Models

## `GameStatsSession` (core snapshot)

Returned by create, get, event, undo, clock, and period endpoints.

```json
{
  "id": 9001,
  "match_id": 42,
  "status": "live",
  "team_score": 68,
  "period": 2,
  "period_label": "H2",
  "clock_remaining_seconds": 462,
  "clock_label": "07:42",
  "clock_running": true,
  "on_court_player_ids": [12, 7, 3, 15, 22],
  "bench_player_ids": [9, 11, 14, 18, 20, 25, 27],
  "roster_player_ids": [12, 7, 3, 15, 22, 9, 11, 14, 18, 20, 25, 27],
  "on_court": [ { "...Person..." } ],
  "bench": [ { "...Person..." } ],
  "roster": [ { "...Person..." } ],
  "match": {
    "id": 42,
    "scheduled_at": "2026-06-22 18:00:00",
    "venue": { "name": "National Indoor Stadium" },
    "home_team": { "name": "Dar City Basketball Club", "short_name": "DC" },
    "away_team": { "name": "UDSM Titans", "short_name": "UDSM" }
  },
  "feed": [ { "...GameStatsFeedEvent..." } ],
  "player_stat_totals": {
    "12": {
      "3PT": 3,
      "2PT": 4,
      "FT": 2,
      "DEF REB": 5,
      "FOUL": 2
    }
  },
  "can_undo": true,
  "created_at": "2026-06-22T17:55:00Z",
  "updated_at": "2026-06-22T18:22:11Z"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | integer | yes | Session PK |
| `match_id` | integer | yes | |
| `status` | string | yes | `live`, `ended` |
| `team_score` | integer | yes | DC points only |
| `period` | integer | yes | 1-based |
| `period_label` | string | yes | `H1`–`H4`, `OT`, … |
| `clock_remaining_seconds` | integer | yes | |
| `clock_label` | string | yes | `MM:SS` or `HH:MM:SS` |
| `clock_running` | boolean | yes | |
| `on_court_player_ids` | integer[] | yes | Length 5 during play |
| `bench_player_ids` | integer[] | yes | |
| `roster_player_ids` | integer[] | yes | Full match-day squad |
| `on_court` / `bench` / `roster` | Person[] | yes | Embedded players for mobile pickers |
| `match` | object | yes | Same shape as schedule match |
| `feed` | array | yes | Newest first (index 0 = latest) |
| `player_stat_totals` | object | yes | Keys: player ID strings → stat label → count |
| `can_undo` | boolean | yes | |
| `created_at` | ISO8601 | yes | |
| `updated_at` | ISO8601 | yes | |

---

## `GameStatsFeedEvent`

```json
{
  "id": 55001,
  "session_id": 9001,
  "action": "score_3_made",
  "stat": "3PT",
  "player_id": 12,
  "player_name": "H. Thabeet",
  "jersey_number": 23,
  "period": 2,
  "period_label": "H2",
  "clock_label": "07:42",
  "clock_remaining_seconds": 462,
  "is_miss": false,
  "count": 3,
  "created_at": "2026-06-22T18:22:11Z"
}
```

| Field | Type | Required |
|-------|------|----------|
| `id` | integer | yes |
| `action` | string | yes |
| `stat` | string | yes | Display label |
| `player_id` | integer | yes |
| `player_name` | string | yes | Short name e.g. `H. Thabeet` |
| `jersey_number` | integer | yes |
| `period` | integer | yes |
| `period_label` | string | yes |
| `clock_label` | string | yes |
| `is_miss` | boolean | yes |
| `count` | integer \| null | no — running per-player total for this stat; `null` for SUB rows |
| `created_at` | ISO8601 | yes |

---

# Suggested database tables

```
game_stats_sessions
  id, match_id, coach_user_id, status, team_score,
  period, clock_remaining_seconds, clock_running,
  created_at, updated_at, ended_at

game_stats_session_players
  session_id, player_id, is_starter, is_on_court, sort_order

game_stats_events
  id, session_id, action, player_id, secondary_player_id,
  stat, period, clock_remaining_seconds, is_miss, count,
  created_at, sequence_number

game_stats_event_undo_stack
  (optional — or derive undo from events soft-delete / sequence)
```

---

# Mobile wiring checklist (for when backend is ready)

| Mobile method (to add) | HTTP | Endpoint |
|------------------------|------|----------|
| `fetchMatchRoster` | GET | `/coach/game-stats/matches/{matchId}/roster` ✅ already |
| `fetchActiveSession` | GET | `/coach/game-stats/matches/{matchId}/active-session` |
| `createSession` | POST | `/coach/game-stats/sessions` |
| `fetchSession` | GET | `/coach/game-stats/sessions/{sessionId}` |
| `postEvent` | POST | `/coach/game-stats/sessions/{sessionId}/events` |
| `undo` | POST | `/coach/game-stats/sessions/{sessionId}/undo` |
| `patchClock` | PATCH | `/coach/game-stats/sessions/{sessionId}/clock` |
| `patchPeriod` | PATCH | `/coach/game-stats/sessions/{sessionId}/period` |
| `fetchReport` | GET | `/coach/game-stats/sessions/{sessionId}/report` |
| `endSession` | POST | `/coach/game-stats/sessions/{sessionId}/end` |

Replace `GameStatsLiveController` local mutations with API calls + `setState` from response `session`. Keep local 1s clock tick between syncs, or disable local tick and rely on server time.

---

# Full lifecycle example

### 1. List roster
```http
GET /api/coach/game-stats/matches/42/roster
Authorization: Bearer {token}
```

### 2. Start session
```http
POST /api/coach/game-stats/sessions
Content-Type: application/json

{
  "match_id": 42,
  "starting_five_player_ids": [12, 7, 3, 15, 22]
}
```

### 3. Record 3PT make
```http
POST /api/coach/game-stats/sessions/9001/events

{ "action": "score_3_made", "player_id": 12 }
```

### 4. Record foul (clock auto-pauses)
```http
POST /api/coach/game-stats/sessions/9001/events

{ "action": "foul", "player_id": 7 }
```

### 5. Substitution
```http
POST /api/coach/game-stats/sessions/9001/events

{ "action": "substitution", "player_out_id": 7, "player_in_id": 9 }
```

### 6. View report
```http
GET /api/coach/game-stats/sessions/9001/report
```

### 7. Undo last action
```http
POST /api/coach/game-stats/sessions/9001/undo
```

---

# Endpoint index

| # | Screen / action | Method | Endpoint |
|---|-----------------|--------|----------|
| — | Schedule (reused) | GET | `/upcoming-matches` |
| — | Schedule (reused) | GET | `/finished-matches` |
| 1 | Match list (optional) | GET | `/coach/game-stats/matches` |
| 2 | Match roster | GET | `/coach/game-stats/matches/{matchId}/roster` |
| 2 | Resume check | GET | `/coach/game-stats/matches/{matchId}/active-session` |
| 2 | Start session | POST | `/coach/game-stats/sessions` |
| 3 | Load session | GET | `/coach/game-stats/sessions/{sessionId}` |
| 3 | Record stat | POST | `/coach/game-stats/sessions/{sessionId}/events` |
| 3 | Undo | POST | `/coach/game-stats/sessions/{sessionId}/undo` |
| 3 | Clock toggle/set | PATCH | `/coach/game-stats/sessions/{sessionId}/clock` |
| 3 | Period next/set | PATCH | `/coach/game-stats/sessions/{sessionId}/period` |
| 3 | Feed (optional) | GET | `/coach/game-stats/sessions/{sessionId}/feed` |
| 3 | Game report | GET | `/coach/game-stats/sessions/{sessionId}/report` |
| 3 | End session | POST | `/coach/game-stats/sessions/{sessionId}/end` |

**Total new endpoints: 11** (10 required + 1 optional matches list; feed optional)

---

# Out of scope (v1)

- Opponent player stats
- Print / PDF export (mobile deferred)
- WebSocket live sync (multi-device); POST-per-tap is sufficient for single coach tablet
- Pushing DC score to public `live-match` fan endpoint (future integration)

---

# Version

| Date | Version | Notes |
|------|---------|-------|
| 2026-06-22 | 1.0 | Initial spec from completed Flutter game-stats UI |
