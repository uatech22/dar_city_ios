# Direct 1:1 Chat — Backend handoff for mobile

**To:** Backend team  
**From:** Dar City mobile  
**Date:** June 2026  
**Related spec:** `CHAT_DIRECT_1TO1_API.md` (full contract in repo)

---

## Purpose

We are moving from the old **shared coach inbox** (one thread per player, all staff see the same messages) to **private 1:1 conversations**. Each player should have separate threads with each staff member (coaches, sports manager, super administrator, etc.). Each staff member should only see **their own** messages with a player — not messages sent by other coaches to that same player.

The mobile app will not implement this until the API contract below is confirmed and sample JSON is available for testing.

---

## What we understand from your update

Thank you for the integration notes. We understand the following is in place or planned on the player side:

**Contact list** — `MobileChatService::teamChatMembers()` builds who can be messaged:

- Players and prospects on the same team (with linked accounts)
- Coaches, staff, and medics via `people.role_in_team`
- Sports managers and super administrators via `users.role` / `userRole.slug`, even when they do not have a `people` row

Each contact should include a real display role (e.g. Head Coach, Sports Manager, Super Administrator, or player position).

**Player endpoints:**

| Action | Endpoint |
|--------|----------|
| Inbox | `GET /api/player/chat/conversations` |
| New chat picker | `GET /api/player/chat/contacts` |
| Open thread | `POST /api/player/chat/conversations` with `{ "staff_id": … }` or `{ "player_id": … }` |
| Load messages | `GET /api/player/chat/conversations/{conversationId}/messages` |
| Send message | `POST /api/player/chat/conversations/{conversationId}/messages` with `{ "body": "…" }` |

**Inbox rows** use `contact_type`:

- `staff` → `staff_name`, `staff_role_label`, `staff_avatar_url`
- `player` → `other_player_name`, `other_player_role_label`, `other_player_avatar_url`

**Message bubbles** should use `sender_name`, `sender_role_label`, and `is_mine` — not a generic “Coach” label.

**`conversation_id`** is currently the **other party’s `user_id`** (synthetic until a `chat_conversations` table exists).

This is enough for us to **start the player Chats UI** once we have real response samples (see §5).

---

## What we still need from backend

### 1. Coach / staff endpoints (required for full release)

The player routes above cover half the product. The **coach shell** (Team Chat) still needs equivalent 1:1 routes. Please implement and document:

| Action | Endpoint |
|--------|----------|
| Staff inbox (own threads only) | `GET /api/coach/chat/conversations` |
| Open thread with a player | `POST /api/coach/chat/conversations` with `{ "player_id": … }` |
| Load messages | `GET /api/coach/chat/conversations/{conversationId}/messages` |
| Send message | `POST /api/coach/chat/conversations/{conversationId}/messages` |
| Mark read | `POST /api/coach/chat/conversations/{conversationId}/read` |

**Critical rule:** When Coach Mohamed opens a thread with player 12, he must only see messages between **Mohamed and that player**. Coach James must not see Mohamed’s messages to the same player, and vice versa. The list endpoint must only return conversations where the **authenticated user is a participant**.

### 2. Confirm how `conversation_id` works (synthetic ID)

Using the other user’s `user_id` as `conversation_id` is acceptable **only if** every request is scoped to `(authenticated_user_id, other_user_id)` on the server. Please confirm in writing:

- From a **player** token, `conversation_id = 7` means “my thread with user 7 (staff).”
- From a **staff** token, `conversation_id = 12` means “my thread with user 12 (player),” not any other coach’s thread with that player.
- When the real `chat_conversations` table is added, will `conversation_id` change to a database PK? If yes, give us a migration plan so mobile is not broken in production.

### 3. Mark read and unread counts

Please implement and document:

- `POST /api/player/chat/conversations/{conversationId}/read` (optional body: `{ "last_read_message_id": … }`)
- Same for coach routes
- How `unread_count` on each inbox row is calculated (messages from the other party since last read)

### 4. Sample JSON we need before mobile coding

Please provide **real** (or realistic staging) responses for:

**A. `GET /api/player/chat/contacts`** — at least one staff and one player contact

**B. `GET /api/player/chat/conversations`** — staff row and teammate row (you already shared shapes; we need full fields including `last_message_at` if available)

**C. `GET /api/player/chat/conversations/{id}/messages`** — at least two messages (one staff, one player) with all fields

**D. `POST` send message** — `201` response body

**E. `GET /api/coach/chat/conversations`** — staff inbox row

**F. Coach thread messages** — same message shape as player side

### 5. Message object — required fields

Every message in list and send responses should include:

```json
{
  "id": 101,
  "conversation_id": 7,
  "sender_id": 3,
  "sender_name": "Mohamed Ali",
  "sender_role": "staff",
  "sender_role_label": "Head Coach",
  "sender_avatar_url": "https://…",
  "body": "Practice is at 6 PM.",
  "sent_at": "2024-11-20T18:30:00Z",
  "is_mine": false,
  "is_seen": true,
  "voice_message_url": null,
  "reactions": null
}
```

| Field | Notes |
|-------|--------|
| `sender_name` | Real person name — never generic `"Coach"` for all staff |
| `sender_role_label` | Head Coach, Assistant Coach, Sports Manager, Super Administrator, Player, Guard, etc. |
| `is_mine` | Relative to the **authenticated** user |
| `sent_at` | ISO 8601 |

### 6. Legacy routes — deprecation

Please confirm when these will be removed or return errors:

| Legacy | Replacement |
|--------|-------------|
| `GET /api/player/chat/coach/messages` | `GET /api/player/chat/conversations` + thread by id |
| `POST /api/player/chat/coach/messages` | `POST /api/player/chat/conversations/{id}/messages` |
| `GET /api/coach/chat/conversations/{playerId}/messages` (shared thread) | `GET /api/coach/chat/conversations/{conversationId}/messages` (private) |

We need a short grace period after mobile ships before legacy routes are turned off.

### 7. Product questions to confirm

Please reply with yes/no or short answers:

1. **Player ↔ player chat** — You documented `POST` with `player_id` for teammates. Is that intentional for v1? (Our original spec was player ↔ staff only; we can support both if confirmed.)
2. **Prospects** — Can prospects use player chat, or only full players?
3. **Fans** — Chat is player shell only, not fan accounts?
4. **Staff without `people` row** — Sports manager / super admin: is `staff_id` always the **`users.id`** used in POST and URLs?
5. **Push notifications** — Will you send FCM when a new message arrives? If yes, what payload fields?

---

## Privacy and authorization (non‑negotiable)

These rules must be enforced **on the server**, not in the mobile app:

1. A user may only read or post in conversations where they are a participant.
2. Staff user A must receive **403** if they request a thread between staff user B and a player (even if they guess `conversation_id`).
3. `sender_id` on create must always be the authenticated user — never trust client-sent sender fields.
4. Contacts list must only include users on the **same team** that the requester is allowed to message.

---

## Example inbox rows (for alignment)

**Staff contact (player inbox):**

```json
{
  "conversation_id": 7,
  "contact_type": "staff",
  "staff_id": 7,
  "staff_name": "Sarah Kim",
  "staff_role_label": "Sports Manager",
  "staff_avatar_url": null,
  "last_message": "Practice at 6 PM",
  "last_message_at": "2024-11-20T18:30:00Z",
  "unread_count": 1
}
```

**Teammate (player inbox):**

```json
{
  "conversation_id": 15,
  "contact_type": "player",
  "other_player_id": 15,
  "other_player_name": "John Doe",
  "other_player_role_label": "Guard",
  "other_player_avatar_url": null,
  "last_message": null,
  "last_message_at": null,
  "unread_count": 0
}
```

---

## Error responses

Use the standard API wrapper:

```json
{
  "message": "You do not have access to this conversation."
}
```

| HTTP | When |
|------|------|
| `401` | Missing or invalid token |
| `403` | Not a participant in this conversation |
| `404` | Unknown `conversation_id`, `staff_id`, or `player_id` |
| `422` | Validation (e.g. empty `body`) |

---

## Acceptance checklist (backend QA)

Before we integrate, please verify:

- [ ] Two staff members messaging the same player have **separate** message histories.
- [ ] Staff A cannot read staff B’s messages to the same player (`403`).
- [ ] Player inbox shows **one row per contact** with correct name and role label.
- [ ] Every message returns non-empty `sender_name` and `sender_role_label` for staff senders.
- [ ] `is_mine` is correct for both player and staff tokens.
- [ ] `POST /player/chat/conversations` is idempotent (does not duplicate threads).
- [ ] Coach inbox + thread endpoints work with the same privacy rules.
- [ ] Sample JSON provided for all routes in §4.

---

## Mobile timeline

We will implement in this order once unblocked:

1. Player **Chats** tab — inbox, contact picker, thread, name + role on bubbles  
2. Coach **Team Chat** — private inbox and threads  
3. Remove use of legacy shared-thread endpoints  
4. Rename player tab label from “Coach” to “Chats”

Please reply with: confirmed endpoint list, answers to §7, sample JSON (§4), and expected date for coach routes.

---

*Full endpoint detail, DB suggestions, and flows: see `CHAT_DIRECT_1TO1_API.md` in the mobile repo.*
