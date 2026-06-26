# Mobile app — login role routing (frontend + backend contract)

This document explains **what the Flutter app does** after login, **which API fields it reads**, and **what the backend must return** so users land in the correct app shell (Fan, Player, or Coach).

**Code reference:** `lib/navigation/role_navigation.dart`

---

## 1. Three app shells

After login (or app reopen with a saved token), the user is sent to **one** of these roots:

| Shell | Widget | Who should get it |
|-------|--------|-------------------|
| **Fan** | `RootScreen` | Fans, sponsors, guests, unlinked users |
| **Player** | `PlayerRootScreen` | Players, prospects |
| **Coach** | `CoachRootScreen` | Coach, sports-manager, super-administrator, staff, medic, internal team |

**Coach shell requirement (product):** These roles must all see the **same coach UI**:

- `coach` / `coach_role`
- `sports-manager`
- `super-administrator`

---

## 2. When routing runs

| Moment | What happens |
|--------|----------------|
| **Login** | `POST /auth/login` → app parses `user` → saves role + `person_id` → navigates to shell |
| **Cold start** | App has token → `GET /profile` → re-resolves role → opens correct shell |
| **Logout** | Clears token, role, `person_id`, `team_id` |

**Important:** User must **log out and log in again** after role fixes on the backend (old `fan` role may be cached on the device).

---

## 3. What the frontend does (step by step)

### A. Login (`POST /auth/login`)

```
1. AuthService.login() calls POST /auth/login
2. On success, saves token
3. RoleNavigation.persistRoleFromResponse(data):
   a. Reads data.user (or data.data.user)
   b. Collects role candidates from all fields (see §4)
   c. Picks best shell role (coach beats player beats fan)
   d. If still "fan" BUT person_id is set → calls GET /coach/dashboard
      - If 200 → treat as coach shell
   e. Saves resolved role to secure storage (user_role)
   f. Saves person_id, team_id if present
4. Navigator opens RoleNavigation.homeForRole(savedRole)
```

### B. Cold start (app reopen)

```
1. AppBootstrap sees saved token
2. RoleNavigation.resolveAuthenticatedHome():
   a. GET /profile
   b. Same role resolution as login (including coach dashboard probe)
   c. Updates saved role
   d. Opens correct shell
```

### C. Role → shell mapping

The app **normalizes** role strings (lowercase, spaces/underscores → hyphens), then maps:

| Normalized role | Shell |
|-----------------|-------|
| `coach`, `coach-role`, `staff`, `medic`, `sports-manager`, `super-administrator`, `internal-team`, anything containing `coach` / `sports`+`manager` / `super`+`admin` | **Coach** |
| `player`, `prospect` | **Player** |
| `sponsor` | **Fan** (sponsor tab experience) |
| Anything else (including `fan`) | **Fan** |

**Priority when multiple roles exist:** Coach shell roles win over player, then sponsor, then fan.

---

## 4. API fields the frontend reads

From **`user`** on login and **`GET /profile`**:

| Field | Type | Used for |
|-------|------|----------|
| `app_role` | string | Primary routing hint (`coach` / `player` / `fan`) |
| `role` | string **or** `{ name, slug, key }` | Signup role or Spatie role object |
| `role_in_team` | string | From `people` table — **high priority for coach** |
| `roles` | string[] or `{ name }[]` | Spatie / multi-role lists |
| `role_name` | string | Optional alias |
| `primary_role` | string | Optional alias |
| `person_id` | int | Links user to `people`; enables coach API probe |
| `team_id` | int | Team context (not used for shell choice) |

**`role_in_team` values that force coach shell:** `coach`, `staff`, `medic`

**String roles that force coach shell:** `sports-manager`, `super-administrator`, `coach`, `coach_role`, `staff`, etc. (see code for full list)

---

## 5. What the backend SHOULD return (recommended)

### Ideal login response for sports-manager / super-admin / coach

```json
{
  "success": true,
  "token": "1|xxxxxxxx",
  "user": {
    "id": 45,
    "name": "Simon Joe Mirondo",
    "email": "sai@darcity.com",
    "phone": "0757000000",
    "role": "fan",
    "app_role": "coach",
    "role_in_team": "staff",
    "person_id": 80,
    "team_id": 25,
    "team_name": "Dar City Basketball",
    "roles": ["sports-manager"],
    "passport": null
  }
}
```

### Minimum fix for staff accounts (pick one)

**Option A — simplest (recommended):** Set `app_role` on login/profile sync:

```json
"app_role": "coach"
```

**Option B — V2 spec:** Keep `app_role` as `coach|player|fan` and set `role_in_team`:

```json
"app_role": "coach",
"role_in_team": "staff"
```

**Option C — Spatie role name:** Include the admin role in `roles` or nested `role`:

```json
"roles": ["sports-manager"]
```

or

```json
"role": { "name": "sports-manager", "slug": "sports-manager" }
```

**Option D — link to people + coach APIs:** If `app_role` stays `fan`, you **must** provide:

```json
"person_id": 80,
"role_in_team": "staff"
```

and ensure `GET /coach/dashboard` returns **200** for that token. The app will probe this endpoint as a last resort.

---

## 6. Profile endpoint (`GET /profile`)

Must return the **same role fields** as login, inside `user` or at top level:

```json
{
  "user": {
    "name": "...",
    "email": "...",
    "role": "fan",
    "app_role": "coach",
    "role_in_team": "staff",
    "person_id": 80,
    "roles": ["sports-manager"]
  }
}
```

If profile only returns `"role": "fan"` with no `app_role`, `role_in_team`, or `roles`, the app will route to **Fan** (unless coach dashboard probe succeeds).

---

## 7. Fallback: coach dashboard probe

If resolved role is **fan** but `person_id` is present, the app calls:

```
GET /api/coach/dashboard
Authorization: Bearer {token}
```

| Response | App behavior |
|----------|----------------|
| **200** | Route to **Coach** shell |
| **401 / 403** | Stay on **Fan** shell |

This is a safety net when the backend sends `role: fan` but the user actually has coach API access.

---

## 8. Why sports-manager may still see Fan today

Common backend issues:

| Problem | Example | Result |
|---------|---------|--------|
| Only `role: fan` returned | Signup role never updated | Fan shell |
| `app_role` missing or `fan` | Staff user not synced on login | Fan shell |
| `sports-manager` only in DB role table | Not included in login JSON | Fan shell |
| `role` is object but `name` not sent | `{ "id": 3 }` without `name` | Fan shell |
| No `person_id` | User not linked to `people` | Fan shell (probe skipped) |
| `person_id` set but `/coach/dashboard` 403 | Middleware blocks staff | Fan shell |
| Stale app cache | User logged in before fix | Fan until logout + login |

---

## 9. Backend checklist (action items)

For **sports-manager**, **super-administrator**, and **coach_role** users:

- [ ] On `POST /auth/login`, include full `user` object (not token only)
- [ ] Set **`app_role": "coach"`** for all three roles (easiest fix)
- [ ] OR set **`role_in_team"`** to `coach` / `staff` / `medic`
- [ ] OR include **`roles": ["sports-manager"]`** (or `super-administrator`)
- [ ] Set **`person_id`** (integer) when user is linked to `people`
- [ ] Mirror the same fields on **`GET /profile`**
- [ ] Ensure **`GET /coach/dashboard`** returns 200 for those users
- [ ] Do **not** rely only on `users.role = fan` from signup if they are staff

---

## 10. How to debug together

1. Backend: log full JSON from `POST /auth/login` for the sports-manager account (redact token).
2. Mobile (debug build): look for log lines:
   ```
   RoleNavigation: login user=... candidates=[...] role_in_team=... person_id=... -> coach
   ```
   or
   ```
   RoleNavigation: /coach/dashboard OK — routing person_id=... to coach shell
   ```
3. Compare API output to §5 — at least one coach signal must be present.

---

## 11. Quick reference — who fixes what

| Issue | Owner |
|-------|--------|
| Wrong shell after login | Backend login payload **or** mobile (if fields are correct) |
| `app_role` not set for staff | **Backend** — sync on login |
| `roles` / `sports-manager` not in JSON | **Backend** — add to login + profile |
| No `person_id` for staff user | **Backend** — link user to `people` |
| Coach APIs 403 for sports-manager | **Backend** — middleware / permissions |
| Old fan shell after backend fix | **User** — logout + login again |

---

## 12. Related files (mobile)

| File | Purpose |
|------|---------|
| `lib/navigation/role_navigation.dart` | Role parsing, shell choice, coach probe |
| `lib/navigation/app_bootstrap.dart` | Cold start routing |
| `lib/services/auth_service.dart` | Login + `persistRoleFromResponse` |
| `lib/services/profile_service.dart` | `GET /profile` |
| `lib/services/session_manager.dart` | Persists `user_role`, `person_id` |
| `lib/loginScreen.dart` | Post-login navigation |
| `lib/models/profile.dart` | Profile role fields |

---

**Summary for backend team:** The mobile app does not guess job titles from email. It only routes from **explicit JSON fields** (`app_role`, `role_in_team`, `roles`, nested `role.name`) or from a successful **`/coach/dashboard`** call when `person_id` exists. For sports-manager and super-administrator, return **`app_role: "coach"`** (or `role_in_team: "staff"` + `person_id`) on login and profile — that is the cleanest fix.
