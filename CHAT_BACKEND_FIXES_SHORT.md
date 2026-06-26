# Chat API — backend fixes needed (short)

**To:** Backend team  
**From:** Dar City mobile  
**Test account:** `amasu@sports.com` (user id **117**, role `sports-manager`)  
**Full spec:** `CHAT_DIRECT_1TO1_API.md`

Mobile coach chat is wired. One **critical bug** blocks correct threads; a few smaller items below.

---

## 1. Critical: wrong `conversation_id` (coach side)

**Rule (agreed):** Until real `chat_conversations` rows exist, `conversation_id` in URLs = **the other participant’s `users.id`**.

| Viewer | Thread key in URL |
|--------|-------------------|
| Coach / staff | **Player’s** `users.id` |
| Player | **Staff’s** `users.id` |

**What we see today (broken):**

```json
POST /api/coach/chat/conversations  { "player_id": 42 }
→ { "conversation_id": 117, "player_id": 42, ... }
```

`117` = logged-in staff (Amasu), not the player (`42`).  
Same in contacts/inbox:

```json
GET /api/coach/chat/contacts
→ { "player_user_id": 112, "player_name": "...", "conversation_id": 117, ... }
```

**Result:** `GET /coach/chat/conversations/117/messages` → **403** / “no access”.

**Fix:** For coach routes, set `conversation_id` = **`player_user_id`** (or `player_id` if that field is the user id). Never the staff auth id.

**Affected endpoints:**

- `POST /api/coach/chat/conversations`
- `GET /api/coach/chat/contacts`
- `GET /api/coach/chat/conversations` (inbox list)
- `GET/POST /api/coach/chat/conversations/{id}/messages` — `{id}` must be **player user id**

*Mobile has a temporary workaround (uses `player_user_id` / `player_id` and ignores bad `conversation_id`). Please fix server so responses match the contract.*

---

## 2. ID fields — be consistent

Use these names everywhere (contacts, inbox, POST response, messages):

| Field | Meaning |
|-------|---------|
| `player_user_id` | Player’s **`users.id`** (use for `POST` body `player_id` and thread URL on coach side) |
| `player_person_id` | Optional — `people.id` for roster only |
| `staff_id` / `staff_user_id` | Staff **`users.id`** (thread URL on player side) |

**`POST /coach/chat/conversations`** body:

```json
{ "player_id": 42 }
```

`player_id` must be **`users.id`**, not `people.id`.

---

## 3. Staff profile: `team_id` on `/profile` or auth user

For `sports-manager` (no `people` row), profile returns:

```json
{ "id": 117, "role": "sports-manager", "team_id": null, "person_id": null }
```

If chat is team-scoped, resolve **team_id** for sports managers / super admins (same as roster/contacts logic) so permissions and contact lists stay consistent.

---

## 4. Coach contacts endpoint

Confirm live:

`GET /api/coach/chat/contacts`

Each row should include at minimum:

```json
{
  "player_user_id": 112,
  "player_name": "Hasheem …",
  "player_role_label": "Point Guard",
  "player_avatar_url": null,
  "conversation_id": 112,
  "has_existing_conversation": false
}
```

(`conversation_id` = player user id when a thread exists.)

---

## 5. Message payload (both sides)

Every message in list + send response:

```json
{
  "id": 101,
  "conversation_id": 42,
  "sender_id": 117,
  "sender_name": "Amasu Suleyy",
  "sender_role": "staff",
  "sender_role_label": "Sports Manager",
  "body": "Hello",
  "sent_at": "2026-06-22T10:00:00Z",
  "is_mine": true
}
```

`is_mine` must be relative to the **authenticated** user.

---

## 6. Privacy (1:1)

- Staff A must **not** read staff B’s thread with the same player.
- `GET /coach/chat/conversations` → only rows where `staff_user_id` = auth id.
- `GET /coach/chat/conversations/{playerUserId}/messages` → 403 if that staff member has no thread with that player.

---

## 7. Quick QA checklist

- [ ] `POST /coach/chat/conversations` with `player_id: 42` → `conversation_id` is **42**, not 117  
- [ ] `GET /coach/chat/conversations/42/messages` works for staff 117  
- [ ] `GET /coach/chat/conversations/117/messages` returns **403** (staff id is not a valid thread key)  
- [ ] Inbox + contacts use player user id as `conversation_id`  
- [ ] Player side: `conversation_id` = staff user id (mirror of above)  
- [ ] Sports manager without `people` row can message players on their team  

---

## 8. Optional (later)

- Real `chat_conversations` table with numeric `conversation_id` (then update mobile once — we can switch when you document the migration).  
- `POST .../read` for unread counts.  
- Push notifications on new message.

---

*Questions → reply with sample JSON for one coach inbox row, one contact row, one POST open response, and one message list.*
