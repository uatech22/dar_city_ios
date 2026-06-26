# Direct 1:1 Chat API — Option B (staff ↔ player private threads)

**For:** Laravel backend team  
**Mobile:** Flutter `darcity` app (player shell + coach shell)  
**Base URL:** `{API_BASE}/api` (see `lib/config/api_config.dart`)  
**Auth:** `Authorization: Bearer {token}` + `Accept: application/json` + `Content-Type: application/json`

This document defines the **API contract** needed to replace the current **shared team inbox** (one thread per player, all staff see everything) with **private 1:1 conversations** between each player and each staff member.

**Code reference (current implementation):**

| Area | File |
|------|------|
| Player chat screen | `lib/features/player/screens/player_chart_view_screen.dart` |
| Player chat service | `lib/features/player/services/player_chat_service.dart` |
| Coach chat hub | `lib/features/coach/screens/coach_chart_hub_screen.dart` |
| Coach thread screen | `lib/features/coach/screens/coach_player_chat_screen.dart` |
| Coach chat service | `lib/features/coach/services/coach_chat_service.dart` |
| Message model | `lib/features/player/models/chat_message.dart` |
| Legacy spec | `API_SPEC_V2.md` — Screen #2 and Screen #10 |

---

## 1. Product goal

| Requirement | Option B behaviour |
|-------------|-------------------|
| Multiple staff can message players | Yes — coach × 4, sports manager, admin, etc. |
| Player knows **who** sent a message | Every message shows **real name + role label** |
| Staff privacy | Coach A **cannot** read messages between Coach B and the same player |
| Player experience | Player has a **Chats** inbox: one thread per staff contact |
| Staff experience | Staff sees only **their own** threads (one row per player they have messaged or may message) |

**Not in scope for v1 (unless you add later):** group chats, team-wide broadcast (use existing announcements), messages between staff members.

---

## 2. Current API vs required change

### Current (shared thread — Option A)

| Endpoint | Problem |
|----------|---------|
| `GET /player/chat/coach/messages` | Single inbox — no staff identity in URL; all staff messages mixed |
| `GET /coach/chat/conversations/{playerId}/messages` | One thread per **player**, shared by **all** staff |
| `POST` variants above | Same shared thread |

### Required (private 1:1 — Option B)

| Concept | Change |
|---------|--------|
| Conversation key | Unique per **`(team_id, player_id, staff_user_id)`** (or `staff_person_id`) |
| Player app | List conversations → open one thread by `conversation_id` |
| Staff app | List **only own** conversations → open thread by `conversation_id` |
| Messages | Always scoped to `conversation_id`; enforce participant check on every request |

**Recommendation:** Introduce **`conversation_id`** as the primary resource ID in URLs. Do not rely on `playerId` alone on the staff side (ambiguous when multiple staff exist).

---

## 3. Suggested database model

### Table: `chat_conversations`

| Column | Type | Notes |
|--------|------|-------|
| `id` | bigint PK | Returned as `conversation_id` |
| `team_id` | bigint FK | Team scope |
| `player_user_id` | bigint FK | Auth user of the player |
| `player_person_id` | bigint FK nullable | Link to `people` row (for roster display) |
| `staff_user_id` | bigint FK | Auth user of the staff member |
| `staff_person_id` | bigint FK nullable | Link to `people` row |
| `last_message_id` | bigint FK nullable | Denormalized for list sorting |
| `last_message_at` | timestamp nullable | ISO sort key |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |

**Unique index:** `UNIQUE(team_id, player_user_id, staff_user_id)`

### Table: `chat_messages`

| Column | Type | Notes |
|--------|------|-------|
| `id` | bigint PK | |
| `conversation_id` | bigint FK | |
| `sender_user_id` | bigint FK | Who sent it |
| `body` | text | Required unless voice |
| `voice_message_url` | string nullable | |
| `sent_at` | timestamp | |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |

### Table: `chat_conversation_reads` (recommended)

Tracks per-user read cursor for unread badges.

| Column | Type | Notes |
|--------|------|-------|
| `conversation_id` | bigint FK | |
| `user_id` | bigint FK | Reader |
| `last_read_message_id` | bigint FK nullable | |
| `last_read_at` | timestamp | |

**Unique index:** `UNIQUE(conversation_id, user_id)`

### Optional: `chat_message_reactions`

Only if you keep emoji reactions from the legacy spec.

---

## 4. Who can chat with whom (authorization)

### Staff allowed to use coach-chat endpoints

Users with **coach shell** access on the team (same rule as mobile role routing):

- `coach` / `coach_role`
- `sports-manager`
- `super-administrator`
- Other internal staff roles you assign chat permission to

Store allowed roles in config or a `can_chat_with_players` flag on the person/user record.

### Rules (enforce on every endpoint)

| Actor | Allowed |
|-------|---------|
| **Player** | List/create conversations only with staff on **their team** |
| **Player** | Read/send only in conversations where they are `player_user_id` |
| **Staff** | List/create conversations only with players on **their team** |
| **Staff** | Read/send only in conversations where they are `staff_user_id` |
| **Staff A** | **403** if they request Staff B's `conversation_id` |
| **Fan / unlinked user** | **403** on all chat routes |

### Create conversation behaviour

`POST` to open a thread should be **idempotent**:

- If `(team, player, staff)` already exists → return existing `conversation_id` (**200**)
- If new → create row → return (**201**)

---

## 5. Response wrapper (same as rest of API)

**List:**
```json
{
  "data": [ ... ]
}
```

**Single object:**
```json
{
  "data": { ... }
}
```

**Error:**
```json
{
  "message": "Human readable error",
  "errors": {
    "field_name": ["Validation message"]
  }
}
```

---

## 6. Shared object shapes

### 6.1 Conversation (list item)

Used in both player and staff conversation lists.

```json
{
  "conversation_id": 42,
  "team_id": 1,
  "player_id": 12,
  "player_person_id": 88,
  "player_name": "Hasheem Thabeet",
  "player_avatar_url": "https://cdn.example/players/88.jpg",
  "staff_id": 3,
  "staff_person_id": 5,
  "staff_user_id": 3,
  "staff_name": "Mohamed Ali",
  "staff_role_label": "Head Coach",
  "staff_avatar_url": "https://cdn.example/staff/5.jpg",
  "last_message": "Practice is at 6 PM. Be on time.",
  "last_message_at": "2024-11-20T18:30:00Z",
  "last_message_sender_side": "staff",
  "unread_count": 2
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `conversation_id` | integer | yes | Primary key for thread URLs |
| `team_id` | integer | yes | |
| `player_id` | integer | yes | Player **user** id (auth id) |
| `player_person_id` | integer | no | Roster / people table id |
| `player_name` | string | yes | Display name |
| `player_avatar_url` | string \| null | no | |
| `staff_id` | integer | yes | Staff **user** id (same as `staff_user_id`) |
| `staff_person_id` | integer | no | |
| `staff_user_id` | integer | yes | Duplicate of `staff_id` is OK for clarity |
| `staff_name` | string | yes | Full name — **never** generic `"Coach"` |
| `staff_role_label` | string | yes | e.g. `Head Coach`, `Assistant Coach`, `Sports Manager`, `Super Administrator` |
| `staff_avatar_url` | string \| null | no | |
| `last_message` | string | no | Preview text; empty if no messages yet |
| `last_message_at` | string (ISO 8601) \| null | no | |
| `last_message_sender_side` | string | no | `staff` \| `player` — who sent last message |
| `unread_count` | integer | no | Default `0`; count for **authenticated** user only |

**Player list endpoint** returns the same object (player sees `staff_*` fields for each row).  
**Staff list endpoint** returns the same object (staff sees `player_*` fields for each row).  
You may omit irrelevant side fields per role, but keeping one shape simplifies mobile parsing.

### 6.2 Chat message

```json
{
  "id": 101,
  "conversation_id": 42,
  "sender_id": 3,
  "sender_person_id": 5,
  "sender_name": "Mohamed Ali",
  "sender_role": "staff",
  "sender_role_label": "Head Coach",
  "sender_avatar_url": "https://cdn.example/staff/5.jpg",
  "body": "Practice is at 6 PM. Be on time.",
  "sent_at": "2024-11-20T18:30:00Z",
  "is_mine": true,
  "is_seen": false,
  "reactions": {
    "👍": 1
  },
  "voice_message_url": null
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | integer | yes | |
| `conversation_id` | integer | yes | |
| `sender_id` | integer | yes | Sender **user** id |
| `sender_person_id` | integer | no | |
| `sender_name` | string | yes | Real name |
| `sender_role` | string | yes | `staff` \| `player` (see §6.3) |
| `sender_role_label` | string | yes for staff | Human label; for player messages use `Player` or position |
| `sender_avatar_url` | string \| null | no | |
| `body` | string | yes* | *Required if no `voice_message_url` |
| `sent_at` | string (ISO 8601) | yes | |
| `is_mine` | boolean | yes | Relative to **authenticated** user |
| `is_seen` | boolean | no | Has the **other** participant read this message? |
| `reactions` | object | no | Emoji → count |
| `voice_message_url` | string \| null | no | |

### 6.3 Sender role enums

| Field | Allowed values | Purpose |
|-------|----------------|---------|
| `sender_role` | `staff`, `player` | Bubble alignment / filtering |
| `sender_role_label` | free string | UI subtitle — **this is what distinguishes 4 coaches** |

**Map from `people.role_in_team` (examples):**

| `role_in_team` | `sender_role_label` |
|----------------|----------------------|
| `coach` | `Head Coach` (or use job title field if you have one) |
| `assistant-coach` | `Assistant Coach` |
| `sports-manager` | `Sports Manager` |
| `super-administrator` | `Administrator` |
| `player` | `Player` or position e.g. `Guard` |

### 6.4 Staff contact (player — new thread picker)

Optional endpoint so players can start a chat before any message exists.

```json
{
  "staff_id": 3,
  "staff_person_id": 5,
  "staff_name": "Mohamed Ali",
  "staff_role_label": "Head Coach",
  "staff_avatar_url": "https://...",
  "conversation_id": null,
  "has_existing_conversation": false
}
```

If a conversation already exists, set `conversation_id` and `has_existing_conversation: true`.

---

## 7. Player endpoints

**Auth:** player (and prospect if they have player shell)

### 7.1 List staff contacts (start new chat)

#### `GET /player/chat/contacts`

Returns staff on the player's team that the player is allowed to message.

**Response `200`:**
```json
{
  "data": [
    {
      "staff_id": 3,
      "staff_person_id": 5,
      "staff_name": "Mohamed Ali",
      "staff_role_label": "Head Coach",
      "staff_avatar_url": "https://...",
      "conversation_id": 42,
      "has_existing_conversation": true
    },
    {
      "staff_id": 7,
      "staff_person_id": 9,
      "staff_name": "Sarah Kim",
      "staff_role_label": "Sports Manager",
      "staff_avatar_url": null,
      "conversation_id": null,
      "has_existing_conversation": false
    }
  ]
}
```

Sort: `staff_role_label` then `staff_name` (or fixed role priority).

---

### 7.2 List my conversations

#### `GET /player/chat/conversations`

**Query params (optional):**

| Param | Type | Description |
|-------|------|-------------|
| `page` | integer | Default `1` |
| `per_page` | integer | Default `20`, max `50` |

**Response `200`:**
```json
{
  "data": [
    {
      "conversation_id": 42,
      "team_id": 1,
      "player_id": 12,
      "player_person_id": 88,
      "player_name": "Hasheem Thabeet",
      "player_avatar_url": "https://...",
      "staff_id": 3,
      "staff_person_id": 5,
      "staff_user_id": 3,
      "staff_name": "Mohamed Ali",
      "staff_role_label": "Head Coach",
      "staff_avatar_url": "https://...",
      "last_message": "See you at practice",
      "last_message_at": "2024-11-20T18:30:00Z",
      "last_message_sender_side": "staff",
      "unread_count": 1
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total": 3
  }
}
```

Only conversations where `player_id` = authenticated player.

Sort: `last_message_at` DESC (nulls last).

---

### 7.3 Open or create conversation with staff

#### `POST /player/chat/conversations`

**Request body:**
```json
{
  "staff_id": 7
}
```

| Field | Type | Required |
|-------|------|----------|
| `staff_id` | integer | yes — staff **user** id from contacts list |

**Response `201`** (created) or **`200`** (already exists):
```json
{
  "data": {
    "conversation_id": 55,
    "team_id": 1,
    "player_id": 12,
    "staff_id": 7,
    "staff_name": "Sarah Kim",
    "staff_role_label": "Sports Manager",
    "staff_avatar_url": null,
    "created_at": "2024-11-21T10:00:00Z"
  }
}
```

**Errors:**

| Status | When |
|--------|------|
| `403` | Staff not on player's team or staff not chat-enabled |
| `404` | `staff_id` not found |
| `422` | Missing `staff_id` |

---

### 7.4 Get messages in a conversation

#### `GET /player/chat/conversations/{conversationId}/messages`

**Path:** `conversationId` (integer)

**Query params (optional):**

| Param | Type | Description |
|-------|------|-------------|
| `before_id` | integer | Cursor pagination — messages older than this id |
| `limit` | integer | Default `50`, max `100` |

**Response `200`:**
```json
{
  "data": [
    {
      "id": 201,
      "conversation_id": 42,
      "sender_id": 3,
      "sender_person_id": 5,
      "sender_name": "Mohamed Ali",
      "sender_role": "staff",
      "sender_role_label": "Head Coach",
      "sender_avatar_url": "https://...",
      "body": "Great work today.",
      "sent_at": "2024-11-20T09:15:00Z",
      "is_mine": false,
      "is_seen": true,
      "reactions": null,
      "voice_message_url": null
    },
    {
      "id": 202,
      "conversation_id": 42,
      "sender_id": 12,
      "sender_person_id": 88,
      "sender_name": "Hasheem Thabeet",
      "sender_role": "player",
      "sender_role_label": "Player",
      "sender_avatar_url": "https://...",
      "body": "Thanks, Coach!",
      "sent_at": "2024-11-20T09:18:00Z",
      "is_mine": true,
      "is_seen": true,
      "reactions": null,
      "voice_message_url": null
    }
  ]
}
```

Messages sorted **`sent_at` ASC** (oldest first) for chat UI.

**Errors:**

| Status | When |
|--------|------|
| `403` | Authenticated player is not a participant |
| `404` | Unknown `conversationId` |

---

### 7.5 Send message

#### `POST /player/chat/conversations/{conversationId}/messages`

**Request body:**
```json
{
  "body": "Thanks, I'll be there.",
  "voice_message_url": null
}
```

| Field | Type | Required |
|-------|------|----------|
| `body` | string | yes* |
| `voice_message_url` | string | no |

**Response `201`:** single message object (inside `data`), with `is_mine: true`.

Side effects:

- Update `chat_conversations.last_message_*`
- Increment unread for staff participant
- Push notification to staff (recommended)

---

### 7.6 Mark conversation as read

#### `POST /player/chat/conversations/{conversationId}/read`

**Request body (optional):**
```json
{
  "last_read_message_id": 202
}
```

If omitted, mark all messages as read.

**Response `200`:**
```json
{
  "data": {
    "success": true,
    "unread_count": 0
  }
}
```

---

## 8. Staff endpoints (coach shell)

**Auth:** coach shell users (`coach`, `sports-manager`, `super-administrator`, etc.)

All list/thread operations are scoped to **`staff_user_id = authenticated user`**.

### 8.1 List my conversations with players

#### `GET /coach/chat/conversations`

Replaces the legacy list but **only returns threads where the logged-in staff member is a participant**.

**Query params:** same pagination as §7.2

**Response `200`:** array of **Conversation** objects (§6.1), sorted by `last_message_at` DESC.

**Critical rule:** Coach Mohamed sees only his rows. Coach James does **not** appear in Mohamed's list for the same player unless Mohamed has his own `conversation_id`.

---

### 8.2 Open or create conversation with player

#### `POST /coach/chat/conversations`

**Request body:**
```json
{
  "player_id": 12
}
```

| Field | Type | Required |
|-------|------|----------|
| `player_id` | integer | yes — player **user** id |

**Response `201` / `200`:** conversation summary (same as §7.3 but with player fields emphasized).

**Errors:**

| Status | When |
|--------|------|
| `403` | Player not on staff member's team |
| `404` | Player not found |

---

### 8.3 Get messages

#### `GET /coach/chat/conversations/{conversationId}/messages`

Same as §7.4, but `is_mine` is relative to the **authenticated staff** user.

**Privacy check:** conversation must have `staff_user_id = auth id`. Otherwise **403**.

---

### 8.4 Send message

#### `POST /coach/chat/conversations/{conversationId}/messages`

Same body and response as §7.5.

`sender_role` = `staff`, `sender_role_label` from staff's `role_in_team`, `sender_name` from staff profile.

---

### 8.5 Mark as read

#### `POST /coach/chat/conversations/{conversationId}/read`

Same as §7.6.

---

## 9. Privacy enforcement checklist (backend)

Implement middleware or policy on **every** chat route:

```
1. Load conversation by conversation_id
2. If not found → 404
3. If auth user is player → require auth.id == conversation.player_user_id
4. If auth user is staff   → require auth.id == conversation.staff_user_id
5. Else → 403
6. For POST message → also verify sender_id will be set to auth.id (never trust client sender)
```

**Never** return messages from a conversation where the requester is not a participant.

**Never** infer a thread from `player_id` alone on staff routes (legacy behaviour).

---

## 10. Unread counts & notifications

### Unread count

For each conversation list item:

```
unread_count = COUNT(messages WHERE conversation_id = X
                     AND sender_user_id != auth.id
                     AND id > reader.last_read_message_id)
```

### Push notifications (recommended)

| Event | Notify |
|-------|--------|
| Player sends message | Staff participant (`staff_user_id`) |
| Staff sends message | Player participant (`player_user_id`) |

Payload should include: `conversation_id`, `sender_name`, `sender_role_label`, message preview.

---

## 11. Migration from legacy endpoints

### Legacy routes (deprecate)

| Method | Legacy endpoint | Status |
|--------|-----------------|--------|
| GET | `/player/chat/coach/messages` | **Deprecate** |
| POST | `/player/chat/coach/messages` | **Deprecate** |
| GET | `/coach/chat/conversations` | **Replace** (same path, new semantics) |
| GET | `/coach/chat/conversations/{playerId}/messages` | **Deprecate** — use `conversationId` |
| POST | `/coach/chat/conversations/{playerId}/messages` | **Deprecate** |

### Suggested rollout

1. Ship new tables + new endpoints behind feature flag.
2. Mobile app switches to new routes (player: conversation list + thread; coach: `conversation_id` threads).
3. Legacy shared messages:
   - **Option 1 (clean):** Archive old messages as read-only "Team chat archive" (one-time export).
   - **Option 2 (split):** For each old message, set `staff_user_id = sender` and create per-sender conversations (only works if `sender_id` was stored correctly).
4. Return **`410 Gone`** or **`404`** on legacy routes after mobile release + grace period.

---

## 12. Error codes (standard)

| HTTP | `message` example | When |
|------|-------------------|------|
| `401` | Unauthenticated | Missing/invalid token |
| `403` | You do not have access to this conversation | Wrong participant |
| `404` | Conversation not found | Invalid id |
| `404` | Staff member not found | Bad `staff_id` |
| `422` | The body field is required | Validation |
| `429` | Too many messages | Rate limit (optional) |

---

## 13. Mobile app changes (after backend is ready)

No code in this doc — listed so backend knows what Flutter will consume.

| Screen | Change |
|--------|--------|
| Player tab **Coach** → **Chats** | Conversation list + contact picker |
| Player thread | `GET/POST .../conversations/{id}/messages` |
| Coach Team Chat hub | List shows only **own** `conversation_id` rows |
| Coach thread | Navigate with `conversationId` instead of `playerId` only |
| Message bubbles | Show `sender_name · sender_role_label · time` on incoming |
| Coach outgoing bubble | Show own name + role (not generic "Coach" avatar) |

**New mobile models:**

- `ChatConversation` — add `conversation_id`, `staff_role_label`, `staff_name`, etc.
- `ChatMessage` — add `sender_role_label`, `conversation_id`, `sender_avatar_url`
- `StaffContact` — for player new-chat picker

---

## 14. Endpoint summary

| # | Method | Endpoint | Auth | Purpose |
|---|--------|----------|------|---------|
| 1 | GET | `/player/chat/contacts` | player | Staff directory for new chats |
| 2 | GET | `/player/chat/conversations` | player | Inbox |
| 3 | POST | `/player/chat/conversations` | player | Open/create thread with `staff_id` |
| 4 | GET | `/player/chat/conversations/{conversationId}/messages` | player | Message history |
| 5 | POST | `/player/chat/conversations/{conversationId}/messages` | player | Send |
| 6 | POST | `/player/chat/conversations/{conversationId}/read` | player | Mark read |
| 7 | GET | `/coach/chat/conversations` | staff | Inbox (own threads only) |
| 8 | POST | `/coach/chat/conversations` | staff | Open/create thread with `player_id` |
| 9 | GET | `/coach/chat/conversations/{conversationId}/messages` | staff | Message history |
| 10 | POST | `/coach/chat/conversations/{conversationId}/messages` | staff | Send |
| 11 | POST | `/coach/chat/conversations/{conversationId}/read` | staff | Mark read |

---

## 15. Example flows

### Player opens chat with Sports Manager (first time)

```
1. GET /player/chat/contacts
   → Sarah Kim, conversation_id: null

2. POST /player/chat/conversations  { "staff_id": 7 }
   → conversation_id: 55

3. POST /player/chat/conversations/55/messages  { "body": "Hello" }
   → message id 301, is_mine: true

4. GET /player/chat/conversations/55/messages
   → [301]
```

### Coach Mohamed messages player (existing thread)

```
1. GET /coach/chat/conversations
   → row: conversation_id 42, player Hasheem, unread 0

2. GET /coach/chat/conversations/42/messages
   → full thread (only Mohamed ↔ Hasheem)

3. POST /coach/chat/conversations/42/messages  { "body": "..." }
```

### Coach James cannot spy on Mohamed's thread

```
GET /coach/chat/conversations/42/messages   (auth = James)
→ 403 Forbidden
```

---

## 16. Acceptance criteria (backend QA)

- [ ] Two staff members messaging the same player create **two** `chat_conversations` rows.
- [ ] Staff A cannot read conversation between Staff B and the same player.
- [ ] Player sees **separate** inbox rows per staff member.
- [ ] Every message includes non-empty `sender_name` and `sender_role_label` for staff.
- [ ] `is_mine` is correct for both player and staff tokens.
- [ ] `unread_count` only counts messages the other party sent since last read.
- [ ] Idempotent `POST /.../conversations` does not duplicate rows.
- [ ] Legacy shared-thread data handled per migration plan (§11).

---

## 17. Questions for backend to confirm

1. Use **`user_id`** or **`person_id`** in conversation keys? (Mobile can use either if consistent; recommend both in response.)
2. Do **`prospect`** users get player chat access before full roster link?
3. Should **super-administrator** see all team conversations (this doc assumes **no** — strict 1:1 privacy)?
4. Push provider (FCM) token registration — existing endpoint or new?
5. Retention policy for messages (delete after N days)?

---

*Document version: 1.0 — Option B direct 1:1 chat. Share with backend; mobile implementation waits on these routes being live.*
