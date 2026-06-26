# Dar City V2 — Complete API Spec (17 Screens)

**Base URL:** `https://darcitybasketball.com/api`  
**Auth:** `Authorization: Bearer {token}` on all routes below.  
**Content-Type:** `application/json`  
**Accept:** `application/json`

---

## Response wrapper (required)

**Single object:**
```json
{
  "data": { ... }
}
```

**List:**
```json
{
  "data": [ ... ]
}
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

**Success action (no body needed):**
```json
{
  "data": {
    "success": true,
    "message": "Optional confirmation message"
  }
}
```

---

## Shared enums & constants

| Field | Allowed values |
|-------|----------------|
| `attendance status` (roster / session) | `present`, `late`, `absent`, `none`, `noshow`, `warning`, `default` |
| `drill assignment status` | `pending`, `in_progress`, `completed`, `overdue` |
| `drill reminder status` | `Not Started`, `In Progress`, `Completed` |
| `sender_role` (chat) | `coach`, `player` |
| `discipline icon_key` | `warning`, `verified`, `schedule`, `fitness_center`, `default` |
| `alert accent_key` | `coral`, `gold`, `blue`, `default` |
| `training session status query` | `upcoming`, `past` |
| `discipline filter query` | `tokens`, `penalties` |

---

## Existing API reused by V2 (already live)

| Method | Endpoint | Used by | Notes |
|--------|----------|---------|-------|
| GET | `/team/players` | Screen #6 Assign Drills (player picker) | Same as Team page — returns `{ "data": [ Person ] }` |

**Person (existing model):**
```json
{
  "id": 1,
  "first_name": "Hasheem",
  "last_name": "Thabeet",
  "position": "Guard",
  "role_in_team": "player",
  "passport_picture": "https://...",
  "nationality": "Tanzania",
  "bio": "...",
  "jersey_number": 23,
  "points": 12,
  "rebounds": 8,
  "assists": 4,
  "height_cm": 213,
  "weight_kg": 120,
  "dob": "1996-01-01"
}
```

---

# COACH — Screens #1–7

---

## Screen #1 — Coach Training Dashboard

### `GET /coach/dashboard`
**Auth:** coach

**Request:** none

**Response `200`:**
```json
{
  "data": {
    "upcoming_training": {
      "scheduled_at": "Tomorrow, 9:00 AM",
      "title": "Team Practice",
      "focus": "Offense and Defense",
      "image_url": null
    },
    "quick_stats": [
      {
        "title": "Average Player Performance",
        "value": "85%",
        "trend": "+5%",
        "trend_up": true
      },
      {
        "title": "Team Attendance",
        "value": "92%",
        "trend": "-2%",
        "trend_up": false
      }
    ],
    "recent_announcements": [
      {
        "id": 1,
        "title": "New Drill Added",
        "author_name": "Coach Anya"
      },
      {
        "id": 2,
        "title": "Game Strategy Update",
        "author_name": "Coach Anya"
      }
    ]
  }
}
```

| Field | Type | Required |
|-------|------|----------|
| `upcoming_training.scheduled_at` | string | yes |
| `upcoming_training.title` | string | yes |
| `upcoming_training.focus` | string | yes |
| `upcoming_training.image_url` | string \| null | no |
| `quick_stats[].title` | string | yes |
| `quick_stats[].value` | string | yes |
| `quick_stats[].trend` | string | yes |
| `quick_stats[].trend_up` | boolean | yes |
| `recent_announcements[].id` | integer | yes |
| `recent_announcements[].title` | string | yes |
| `recent_announcements[].author_name` | string | yes |

---

## Screen #2 — Coach Chart Hub (Team Chat)

### `GET /coach/chat/conversations`
**Auth:** coach

**Request:** none

**Response `200`:**
```json
{
  "data": [
    {
      "player_id": 12,
      "player_name": "Hasheem",
      "last_message": "Coach: Practice is at 6 PM",
      "last_message_at": "10m",
      "player_avatar_url": "https://...",
      "unread_count": 2
    },
    {
      "player_id": 15,
      "player_name": "Solo",
      "last_message": "Coach: Game plan for tomorrow",
      "last_message_at": "20m",
      "player_avatar_url": null,
      "unread_count": 0
    }
  ]
}
```

| Field | Type | Required |
|-------|------|----------|
| `player_id` | integer | yes |
| `player_name` | string | yes |
| `last_message` | string | yes |
| `last_message_at` | string | yes (relative or ISO) |
| `player_avatar_url` | string \| null | no |
| `unread_count` | integer | no (default 0) |

---

### `GET /coach/chat/conversations/{playerId}/messages`
**Auth:** coach

**Path params:** `playerId` (integer)

**Request:** none

**Response `200`:**
```json
{
  "data": [
    {
      "id": 101,
      "sender_id": 3,
      "sender_name": "Coach Mohamed",
      "sender_role": "coach",
      "body": "Hey team, great effort in practice today!",
      "sent_at": "2024-11-20T09:15:00Z",
      "is_mine": true,
      "reactions": {
        "👍": 2,
        "❤️": 1
      },
      "voice_message_url": null,
      "is_seen": true
    },
    {
      "id": 102,
      "sender_id": 12,
      "sender_name": "Hasheem",
      "sender_role": "player",
      "body": "Thanks, Coach! Ready for the next game.",
      "sent_at": "2024-11-20T09:18:00Z",
      "is_mine": false,
      "reactions": {
        "👍": 1,
        "🏀": 1
      },
      "voice_message_url": null,
      "is_seen": true
    }
  ]
}
```

| Field | Type | Required |
|-------|------|----------|
| `id` | integer | yes |
| `sender_id` | integer | yes |
| `sender_name` | string | yes |
| `sender_role` | string | yes (`coach` \| `player`) |
| `body` | string | yes |
| `sent_at` | string (ISO 8601) | yes |
| `is_mine` | boolean | yes (relative to authenticated coach) |
| `reactions` | object (emoji → count) | no |
| `voice_message_url` | string \| null | no |
| `is_seen` | boolean | no |

---

### `POST /coach/chat/conversations/{playerId}/messages`
**Auth:** coach

**Path params:** `playerId` (integer)

**Request body:**
```json
{
  "body": "Practice is at 6 PM. Be on time.",
  "voice_message_url": null
}
```

| Field | Type | Required |
|-------|------|----------|
| `body` | string | yes |
| `voice_message_url` | string | no |

**Response `201`:** same shape as single chat message object above (inside `data`).

---

## Screen #3 — Coach Team Announcement

### `POST /coach/announcements`
**Auth:** coach

**Request body:**
```json
{
  "subject": "Game Strategy Update",
  "body": "Full announcement text for the team...",
  "image_url": "https://example.com/image.jpg",
  "video_url": null,
  "link_url": "https://example.com/link"
}
```

| Field | Type | Required |
|-------|------|----------|
| `subject` | string | yes |
| `body` | string | yes |
| `image_url` | string | no |
| `video_url` | string | no |
| `link_url` | string | no |

**Response `201`:**
```json
{
  "data": {
    "id": 42,
    "subject": "Game Strategy Update",
    "body": "Full announcement text for the team...",
    "published_at": "2024-11-20T10:00:00Z",
    "image_url": "https://example.com/image.jpg",
    "video_url": null,
    "link_url": "https://example.com/link"
  }
}
```

---

### `GET /coach/announcements`
**Auth:** coach

**Request:** none

**Response `200`:**
```json
{
  "data": [
    {
      "id": 42,
      "subject": "Game Strategy Update",
      "body": "Full announcement text...",
      "published_at": "2024-11-20T10:00:00Z",
      "image_url": null,
      "video_url": null,
      "link_url": null
    }
  ]
}
```

---

## Screen #4 — Send Drill Reminders

### `GET /coach/drills/{drillId}/reminders`
**Auth:** coach

**Path params:** `drillId` (integer)

**Request:** none

**Response `200`:**
```json
{
  "data": [
    {
      "player_id": 12,
      "player_name": "Solo Diabate",
      "status": "In Progress",
      "avatar_url": "https://..."
    },
    {
      "player_id": 15,
      "player_name": "Raphiael",
      "status": "Not Started",
      "avatar_url": null
    }
  ]
}
```

| Field | Type | Required |
|-------|------|----------|
| `player_id` | integer | yes |
| `player_name` | string | yes |
| `status` | string | yes |
| `avatar_url` | string \| null | no |

---

### `POST /coach/drills/{drillId}/reminders`
**Auth:** coach

**Path params:** `drillId` (integer)

**Request body:**
```json
{
  "message": "Reminder: complete Shooting Practice before Friday.",
  "player_ids": [12, 15, 18]
}
```

| Field | Type | Required |
|-------|------|----------|
| `message` | string | yes |
| `player_ids` | integer[] | yes |

**Response `200`:**
```json
{
  "data": {
    "success": true,
    "message": "Reminders sent to 3 players",
    "sent_count": 3
  }
}
```

---

## Screen #5 — Add New Drill

### `POST /coach/drills`
**Auth:** coach

**Request body:**
```json
{
  "name": "Shooting Practice",
  "category": "Shooting",
  "objective": "Improve shooting form and consistency",
  "equipment": "Basketballs, cones, shooting machine",
  "setup_instructions": "Place cones at three spots...",
  "execution_steps": "1. Warm up\n2. Form shooting\n3. Game speed reps",
  "priority": "High"
}
```

| Field | Type | Required |
|-------|------|----------|
| `name` | string | yes |
| `category` | string | yes |
| `objective` | string | yes |
| `equipment` | string | yes |
| `setup_instructions` | string | yes |
| `execution_steps` | string | yes |
| `priority` | string | yes (`Low` \| `Medium` \| `High`) |

**Response `201`:**
```json
{
  "data": {
    "id": 7,
    "name": "Shooting Practice",
    "category": "Shooting",
    "objective": "Improve shooting form and consistency",
    "equipment": "Basketballs, cones, shooting machine",
    "setup_instructions": "Place cones at three spots...",
    "execution_steps": "1. Warm up\n2. Form shooting\n3. Game speed reps",
    "priority": "High"
  }
}
```

---

## Screen #6 — Assign Drills

### `GET /coach/drills`
**Auth:** coach

**Request:** none

**Response `200`:**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Dribbling Drill",
      "category": "Ball Handling",
      "objective": null,
      "equipment": null,
      "setup_instructions": null,
      "execution_steps": null,
      "priority": "Medium"
    },
    {
      "id": 2,
      "name": "Shooting Drill",
      "category": "Shooting",
      "objective": null,
      "equipment": null,
      "setup_instructions": null,
      "execution_steps": null,
      "priority": "High"
    }
  ]
}
```

> **Player list for this screen:** use existing `GET /team/players` (see top of doc).

---

### `POST /coach/drills/assign`
**Auth:** coach

**Request body:**
```json
{
  "player_ids": [1, 2, 5, 8, 12],
  "drill_ids": [3, 7],
  "reps": 5,
  "sets": 3,
  "time_minutes": 20,
  "due_date": "2024-11-20"
}
```

| Field | Type | Required |
|-------|------|----------|
| `player_ids` | integer[] | yes (min 1) |
| `drill_ids` | integer[] | yes (min 1) |
| `reps` | integer | yes |
| `sets` | integer | yes |
| `time_minutes` | integer | yes |
| `due_date` | string (ISO date `YYYY-MM-DD`) | yes |

**Response `201`:**
```json
{
  "data": {
    "success": true,
    "message": "Drills assigned successfully",
    "assignments_created": 10,
    "assignment_ids": [101, 102, 103, 104, 105, 106, 107, 108, 109, 110]
  }
}
```

---

## Screen #7 — Manage Training Session

### `GET /coach/training-sessions`
**Auth:** coach

**Query params:**

| Param | Type | Required | Values |
|-------|------|----------|--------|
| `status` | string | no | `upcoming`, `past` |

**Example:** `GET /coach/training-sessions?status=upcoming`

**Request body:** none

**Response `200`:**
```json
{
  "data": [
    {
      "id": 5,
      "title": "Shooting Practice",
      "location": "Court A",
      "scheduled_at": "2024-11-22T09:00:00Z",
      "is_past": false
    },
    {
      "id": 6,
      "title": "Team Scrimmage",
      "location": "Court C",
      "scheduled_at": "2024-11-25T14:00:00Z",
      "is_past": false
    }
  ]
}
```

| Field | Type | Required |
|-------|------|----------|
| `id` | integer | yes |
| `title` | string | yes |
| `location` | string | yes |
| `scheduled_at` | string (ISO 8601) | yes |
| `is_past` | boolean | yes |

---

### `POST /coach/training-sessions`
**Auth:** coach

**Request body:**
```json
{
  "title": "Morning Drill",
  "location": "Court B",
  "scheduled_at": "2024-11-24T08:00:00Z",
  "focus": "Defense and transition"
}
```

| Field | Type | Required |
|-------|------|----------|
| `title` | string | yes |
| `location` | string | yes |
| `scheduled_at` | string (ISO 8601) | yes |
| `focus` | string | no |

**Response `201`:** same object shape as training session item (inside `data`), including `id`.

---

### `PUT /coach/training-sessions/{sessionId}`
**Auth:** coach

**Path params:** `sessionId` (integer)

**Request body:** same as POST above.

**Response `200`:** updated training session object (inside `data`).

---

# PLAYER — Screens #8–11

---

## Screen #8 — View Assigned Drills

### `GET /player/drills/assigned`
**Auth:** player

**Request:** none

**Response `200`:**
```json
{
  "data": [
    {
      "assignment_id": 101,
      "drill_id": 3,
      "drill_name": "Dribbling Drill",
      "due_date": "2024-11-20",
      "reps": 3,
      "sets": 5,
      "time_minutes": 20,
      "status": "pending"
    },
    {
      "assignment_id": 102,
      "drill_id": 7,
      "drill_name": "Shooting Drill",
      "due_date": "2024-11-22",
      "reps": 4,
      "sets": 4,
      "time_minutes": 15,
      "status": "in_progress"
    }
  ]
}
```

| Field | Type | Required |
|-------|------|----------|
| `assignment_id` | integer | yes |
| `drill_id` | integer | yes |
| `drill_name` | string | yes |
| `due_date` | string | yes |
| `reps` | integer | yes |
| `sets` | integer | yes |
| `time_minutes` | integer | yes |
| `status` | string | yes |

---

## Screen #9 — Mark Drill Completed

### `GET /player/drills/completion`
**Auth:** player

**Request:** none

**Response `200`:**
```json
{
  "data": [
    {
      "assignment_id": 101,
      "title": "Crossover Dribble",
      "category": "Dribbling Drill",
      "is_completed": false
    },
    {
      "assignment_id": 102,
      "title": "Jump Shot Practice",
      "category": "Shooting Drill",
      "is_completed": true
    }
  ]
}
```

| Field | Type | Required |
|-------|------|----------|
| `assignment_id` | integer | yes |
| `title` | string | yes |
| `category` | string | yes |
| `is_completed` | boolean | yes |

---

### `PATCH /player/drills/completion`
**Auth:** player

**Request body:**
```json
{
  "assignment_ids": [101, 102],
  "notes": "Completed at home court"
}
```

| Field | Type | Required |
|-------|------|----------|
| `assignment_ids` | integer[] | yes (min 1) |
| `notes` | string | no |

**Response `200`:**
```json
{
  "data": {
    "success": true,
    "message": "2 drills marked complete",
    "updated_count": 2,
    "assignment_ids": [101, 102]
  }
}
```

---

## Screen #10 — Player Chart View (Coach Chat)

### `GET /player/chat/coach/messages`
**Auth:** player

**Request:** none

**Response `200`:** same message array shape as `GET /coach/chat/conversations/{playerId}/messages`, but `is_mine` is relative to the authenticated **player**.

```json
{
  "data": [
    {
      "id": 201,
      "sender_id": 3,
      "sender_name": "Coach Mohamed",
      "sender_role": "coach",
      "body": "Hey team, great effort in practice today!",
      "sent_at": "2024-11-20T09:15:00Z",
      "is_mine": false,
      "reactions": { "👍": 2 },
      "voice_message_url": null,
      "is_seen": null
    },
    {
      "id": 202,
      "sender_id": 12,
      "sender_name": "Hasheem",
      "sender_role": "player",
      "body": "Thanks, Coach!",
      "sent_at": "2024-11-20T09:18:00Z",
      "is_mine": true,
      "reactions": null,
      "voice_message_url": null,
      "is_seen": true
    }
  ]
}
```

---

### `POST /player/chat/coach/messages`
**Auth:** player

**Request body:**
```json
{
  "body": "Thanks, Coach! We're all feeling good.",
  "voice_message_url": null
}
```

**Response `201`:** single chat message object (inside `data`).

---

## Screen #11 — Provide Player Feedback

### `POST /player/feedback`
**Auth:** player

**Request body:**
```json
{
  "category": "Training Session",
  "feedback": "Today's drill was helpful but could use more rest time.",
  "coach_id": 3
}
```

| Field | Type | Required |
|-------|------|----------|
| `category` | string | yes |
| `feedback` | string | yes |
| `coach_id` | integer | no |

**Response `201`:**
```json
{
  "data": {
    "id": 88,
    "category": "Training Session",
    "feedback": "Today's drill was helpful but could use more rest time.",
    "submitted_at": "2024-11-20T11:30:00Z"
  }
}
```

---

# ATTENDANCE — Screens #12–14

---

## Screen #12 — Attendance Management

### `GET /coach/attendance/management`
**Auth:** coach

**Query params:**

| Param | Type | Required |
|-------|------|----------|
| `search` | string | no (filter by name or jersey number) |

**Example:** `GET /coach/attendance/management?search=marcus`

**Response `200`:**
```json
{
  "data": {
    "squad_attendance_rate": "92%",
    "tokens_earned_weekly": 142,
    "pending_penalties": 8,
    "present_count": 24,
    "late_count": 2,
    "absent_count": 1,
    "roster": [
      {
        "player_id": 1,
        "name": "Marcus Reid",
        "details": "#23 · Forward",
        "status": "present",
        "avatar_url": "https://..."
      },
      {
        "player_id": 2,
        "name": "Jalen Smith",
        "details": "#10 · Guard",
        "status": "warning",
        "avatar_url": null
      },
      {
        "player_id": 3,
        "name": "Tariq Johnson",
        "details": "#07 · Center",
        "status": "noshow",
        "avatar_url": null
      }
    ]
  }
}
```

| Field | Type | Required |
|-------|------|----------|
| `squad_attendance_rate` | string | yes (e.g. `"92%"`) |
| `tokens_earned_weekly` | integer | yes |
| `pending_penalties` | integer | yes |
| `present_count` | integer | yes |
| `late_count` | integer | yes |
| `absent_count` | integer | yes |
| `roster[].player_id` | integer | yes |
| `roster[].name` | string | yes |
| `roster[].details` | string | yes |
| `roster[].status` | string | yes |
| `roster[].avatar_url` | string \| null | no |

---

### `POST /coach/attendance/mark-all-present`
**Auth:** coach

**Request body:**
```json
{
  "session_id": 5
}
```

| Field | Type | Required |
|-------|------|----------|
| `session_id` | integer | no (if omitted, marks today's default session) |

**Response `200`:**
```json
{
  "data": {
    "success": true,
    "message": "All players marked present",
    "players_updated": 27
  }
}
```

---

## Screen #13 — Daily Attendance & Token (Player)

### `GET /player/attendance/daily`
**Auth:** player

**Request:** none

**Response `200`:**
```json
{
  "data": {
    "date_label": "MONDAY, OCT 23",
    "player_name": "Ethan Carter",
    "attendance_status": "present",
    "token_balance": 85,
    "penalty_count": 2,
    "streak_days": 5,
    "upcoming_drill": "Shooting Practice — Tomorrow 9:00 AM",
    "coach_note": "Great focus in yesterday's session. Keep it up!"
  }
}
```

| Field | Type | Required |
|-------|------|----------|
| `date_label` | string | yes |
| `player_name` | string | yes |
| `attendance_status` | string | yes |
| `token_balance` | integer | yes |
| `penalty_count` | integer | yes |
| `streak_days` | integer | yes |
| `upcoming_drill` | string | no |
| `coach_note` | string | no |

---

### `POST /player/attendance/check-in`
**Auth:** player

**Request body:** `{}` (empty object) or omit body

**Response `200`:**
```json
{
  "data": {
    "success": true,
    "message": "Check-in recorded",
    "attendance_status": "present",
    "token_awarded": 5,
    "token_balance": 90,
    "streak_days": 6
  }
}
```

---

## Screen #14 — Take Session Attendance

### `GET /coach/attendance/sessions/{sessionId}`
**Auth:** coach

**Path params:** `sessionId` (integer)

**Response `200`:**
```json
{
  "data": {
    "session_id": 5,
    "date_label": "OCTOBER 24, 2023",
    "session_title": "MORNING DRILL",
    "present_rate": "92%",
    "players": [
      {
        "player_id": 1,
        "name": "J. CARTER",
        "details": "#23 • POINT GUARD",
        "status": "present"
      },
      {
        "player_id": 2,
        "name": "M. THOMPSON",
        "details": "#11 • FORWARD",
        "status": "none"
      },
      {
        "player_id": 4,
        "name": "K. DURANT",
        "details": "#35 • FORWARD",
        "status": "late"
      }
    ]
  }
}
```

| Field | Type | Required |
|-------|------|----------|
| `session_id` | integer | yes |
| `date_label` | string | yes |
| `session_title` | string | yes |
| `present_rate` | string | yes |
| `players[].player_id` | integer | yes |
| `players[].name` | string | yes |
| `players[].details` | string | yes |
| `players[].status` | string | yes |

---

### `POST /coach/attendance/sessions/{sessionId}/mark`
**Auth:** coach

**Path params:** `sessionId` (integer)

**Request body:**
```json
{
  "records": [
    { "player_id": 1, "status": "present" },
    { "player_id": 2, "status": "late" },
    { "player_id": 3, "status": "absent" },
    { "player_id": 4, "status": "none" }
  ]
}
```

| Field | Type | Required |
|-------|------|----------|
| `records` | array | yes |
| `records[].player_id` | integer | yes |
| `records[].status` | string | yes |

**Response `200`:**
```json
{
  "data": {
    "success": true,
    "message": "Attendance saved",
    "session_id": 5,
    "present_rate": "92%",
    "records_updated": 4
  }
}
```

---

# DISCIPLINE — Screens #15–17

---

## Screen #15 — Discipline & Merit (Player)

### `GET /player/discipline`
**Auth:** player

**Query params:**

| Param | Type | Required | Values |
|-------|------|----------|--------|
| `filter` | string | no | `tokens`, `penalties` |

**Example:** `GET /player/discipline?filter=penalties`

**Response `200`:**
```json
{
  "data": {
    "token_balance": 75,
    "salary_impact_label": "PROJECTED SALARY IMPACT",
    "salary_impact_value": "+4.2%",
    "history": [
      {
        "id": 1,
        "title": "Unexcused Absence",
        "subtitle": "Oct 24, 2023 • Tuesday Morning Drills",
        "token_change": "-20",
        "is_penalty": true,
        "icon_key": "warning"
      },
      {
        "id": 2,
        "title": "Good Practice",
        "subtitle": "Oct 22, 2023 • Leadership & Focus Award",
        "token_change": "+10",
        "is_penalty": false,
        "icon_key": "verified"
      },
      {
        "id": 3,
        "title": "Early Arrival",
        "subtitle": "Oct 21, 2023 • Arrived 15m early",
        "token_change": "+5",
        "is_penalty": false,
        "icon_key": "schedule"
      }
    ]
  }
}
```

| Field | Type | Required |
|-------|------|----------|
| `token_balance` | integer | yes |
| `salary_impact_label` | string | yes |
| `salary_impact_value` | string | yes |
| `history[].id` | integer | yes |
| `history[].title` | string | yes |
| `history[].subtitle` | string | yes |
| `history[].token_change` | string | yes (e.g. `"+10"`, `"-20"`) |
| `history[].is_penalty` | boolean | yes |
| `history[].icon_key` | string | yes |

---

## Screen #16 — Issue Disciplinary Penalty (Coach)

### `POST /coach/discipline/penalties`
**Auth:** coach

**Request body:**
```json
{
  "player_id": 4,
  "infraction": "Late Arrival",
  "tokens": 15,
  "notes": "Arrived 10 minutes late to morning drill"
}
```

| Field | Type | Required |
|-------|------|----------|
| `player_id` | integer | yes |
| `infraction` | string | yes |
| `tokens` | integer | yes (deduction amount, positive number) |
| `notes` | string | no |

**Suggested `infraction` values:** `Late Arrival`, `Unexcused Absence`, `Poor Conduct`, `Equipment Violation`

**Response `201`:**
```json
{
  "data": {
    "success": true,
    "message": "Penalty issued",
    "penalty_id": 55,
    "player_id": 4,
    "tokens_deducted": 15,
    "new_token_balance": 60
  }
}
```

---

## Screen #17 — Performance & Salary Alerts

### `GET /player/alerts`
**Auth:** player

**Request:** none

**Response `200`:**
```json
{
  "data": [
    {
      "id": 1,
      "category": "SYSTEM LOG",
      "title": "Attendance Logged",
      "message": "Morning Drill session verified. No anomalies detected.",
      "timestamp": "08:45 AM TODAY",
      "accent_key": "coral",
      "icon_key": "calendar_today",
      "show_progress": false,
      "progress_value": null
    },
    {
      "id": 2,
      "category": "REWARD ISSUED",
      "title": "Token Awarded",
      "message": "+15 Exceptional leadership during defensive sets.",
      "timestamp": "10:12 AM TODAY",
      "accent_key": "gold",
      "icon_key": "star",
      "show_progress": false,
      "progress_value": null
    },
    {
      "id": 3,
      "category": "FINANCIAL FORECAST",
      "title": "Salary Adjustment",
      "message": "Projected +4.2% increase for next quarter.",
      "timestamp": "CURRENT TREND: EXCELLENT",
      "accent_key": "blue",
      "icon_key": "trending_up",
      "show_progress": true,
      "progress_value": 0.84
    }
  ]
}
```

| Field | Type | Required |
|-------|------|----------|
| `id` | integer | yes |
| `category` | string | yes |
| `title` | string | yes |
| `message` | string | yes |
| `timestamp` | string | yes |
| `accent_key` | string | yes |
| `icon_key` | string | yes |
| `show_progress` | boolean | no |
| `progress_value` | number (0–1) | no |

---

### `GET /coach/alerts`
**Auth:** coach

**Request:** none

**Response `200`:** same array shape as `GET /player/alerts`, but content is **team-wide / system** alerts for the coach (not player-personal only).

```json
{
  "data": [
    {
      "id": 10,
      "category": "SYSTEM LOG",
      "title": "Attendance Logged",
      "message": "Morning Drill session verified for 12 players. No anomalies detected.",
      "timestamp": "08:45 AM TODAY",
      "accent_key": "coral",
      "icon_key": "calendar_today",
      "show_progress": false,
      "progress_value": null
    },
    {
      "id": 11,
      "category": "DISCIPLINARY ACTION",
      "title": "Penalty Issued",
      "message": "Late arrival penalty applied to Marcus Thompson (-15 tokens).",
      "timestamp": "09:30 AM TODAY",
      "accent_key": "coral",
      "icon_key": "warning",
      "show_progress": false,
      "progress_value": null
    }
  ]
}
```

---

# Endpoint index (all 26 + 1 reused)

| # | Screen | Method | Endpoint | Auth |
|---|--------|--------|----------|------|
| — | Assign Drills (players) | GET | `/team/players` | any |
| 1 | Dashboard | GET | `/coach/dashboard` | coach |
| 2 | Team Chat list | GET | `/coach/chat/conversations` | coach |
| 2 | Team Chat thread | GET | `/coach/chat/conversations/{playerId}/messages` | coach |
| 2 | Team Chat send | POST | `/coach/chat/conversations/{playerId}/messages` | coach |
| 3 | Announcement publish | POST | `/coach/announcements` | coach |
| 3 | Announcement list | GET | `/coach/announcements` | coach |
| 4 | Drill reminders list | GET | `/coach/drills/{drillId}/reminders` | coach |
| 4 | Drill reminders send | POST | `/coach/drills/{drillId}/reminders` | coach |
| 5 | Add drill | POST | `/coach/drills` | coach |
| 6 | Drill picker | GET | `/coach/drills` | coach |
| 6 | Assign drills | POST | `/coach/drills/assign` | coach |
| 7 | Training sessions | GET | `/coach/training-sessions` | coach |
| 7 | Create session | POST | `/coach/training-sessions` | coach |
| 7 | Update session | PUT | `/coach/training-sessions/{sessionId}` | coach |
| 8 | Assigned drills | GET | `/player/drills/assigned` | player |
| 9 | Completion list | GET | `/player/drills/completion` | player |
| 9 | Mark complete | PATCH | `/player/drills/completion` | player |
| 10 | Coach chat | GET | `/player/chat/coach/messages` | player |
| 10 | Coach chat send | POST | `/player/chat/coach/messages` | player |
| 11 | Feedback | POST | `/player/feedback` | player |
| 12 | Attendance mgmt | GET | `/coach/attendance/management` | coach |
| 12 | Mark all present | POST | `/coach/attendance/mark-all-present` | coach |
| 13 | Daily attendance | GET | `/player/attendance/daily` | player |
| 13 | Check-in | POST | `/player/attendance/check-in` | player |
| 14 | Session attendance | GET | `/coach/attendance/sessions/{sessionId}` | coach |
| 14 | Save attendance | POST | `/coach/attendance/sessions/{sessionId}/mark` | coach |
| 15 | Discipline | GET | `/player/discipline` | player |
| 16 | Issue penalty | POST | `/coach/discipline/penalties` | coach |
| 17 | Player alerts | GET | `/player/alerts` | player |
| 17 | Coach alerts | GET | `/coach/alerts` | coach |

---

# Flutter code reference

| Layer | Path |
|-------|------|
| Services | `darcity/lib/features/**/services/` |
| Models | `darcity/lib/features/**/models/` |
| HTTP client | `darcity/lib/features/shared/api/feature_api_client.dart` |
| Single import | `darcity/lib/features/features_api.dart` |

---

# Notes for backend engineer

1. **UI not wired yet** — screens still show demo data; this doc + services are the contract.
2. **Auth** — reuse existing Bearer token from login (`SessionManager`).
3. **Role enforcement** — `/coach/*` = Internal Team only; `/player/*` = Player only.
4. **Dates** — send ISO 8601; app may display friendly labels (`"Tomorrow, 9:00 AM"`).
5. **Lists** — always wrap in `{ "data": [...] }`.
6. **Validation errors** — HTTP 422 with `errors` object (same as existing fan app auth).

---

# Game Stats (Coach Live Console) — separate spec

Mobile UI is **built** (match select → starting five → live console + game report). Live actions still use a **local dummy engine** until backend is ready.

**Full request/response contract:** [GAME_STATS_API.md](./GAME_STATS_API.md) — 11 new endpoints, session model, stat enums, business rules, and mobile wiring checklist.
