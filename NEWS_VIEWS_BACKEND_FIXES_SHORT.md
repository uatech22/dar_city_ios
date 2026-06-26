# News views — backend fixes needed (short)

**To:** Backend team  
**From:** Dar City mobile (fan news tab)  
**Base URL:** `http://192.168.1.6:8000/api`

Fan app shows **likes** and **comments** fine. **Views always show 0** — mobile is ready; API is not.

---

## What we tested (today)

### `GET /api/news` — missing field

Response has `likes_count`, `comments_count`, `is_liked` — **no `views_count`**.

```bash
curl http://192.168.1.6:8000/api/news
# each item should include "views_count": 0  (or higher)
```

### `POST /api/news/{id}/view` — route missing

```bash
curl -X POST http://192.168.1.6:8000/api/news/{news-id}/view \
  -H "Accept: application/json"
# Today: HTTP 404 — route not found
```

---

## What mobile expects

### 1. Add `views_count` to news JSON

On **list** and **detail**:

| Endpoint | Field |
|----------|--------|
| `GET /api/news` | `views_count` on each item in `data[]` |
| `GET /api/news/{id}` | `views_count` on `data` |

```json
{
  "id": "1abc29e4-64b6-4160-9774-31602488014e",
  "title": "...",
  "likes_count": 1,
  "comments_count": 2,
  "views_count": 42,
  "is_liked": false
}
```

Mobile also accepts `view_count` or `views` as fallback — prefer **`views_count`**.

---

### 2. Implement record-view endpoint

**`POST /api/news/{id}/view`**

- Call when a fan opens an article (auth optional; send `Authorization: Bearer` if logged in).
- Increment count (dedupe per user/session if you want — mobile calls once per open).
- Return updated count.

**Response `200` or `201`:**

```json
{
  "success": true,
  "data": {
    "views_count": 43
  }
}
```

---

## Checklist

- [ ] `views_count` on `GET /api/news`
- [ ] `views_count` on `GET /api/news/{id}`
- [ ] `POST /api/news/{id}/view` exists (not 404)
- [ ] POST returns `views_count` in `data`
- [ ] Count increases after opening an article in the app

---

## No mobile change needed

After deploy, fan feed and article detail will show views automatically. User may need to refresh / reopen the app.

**Verify:**

```bash
# 1) List shows views_count
curl -s http://192.168.1.6:8000/api/news | jq '.data[0].views_count'

# 2) Record view works
curl -s -X POST http://192.168.1.6:8000/api/news/{news-id}/view \
  -H "Accept: application/json" | jq '.data.views_count'
```
