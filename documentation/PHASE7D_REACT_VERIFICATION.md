# Phase 7D React Admin Verification Checklist

## Installation and configuration

- [x] Node.js/npm are present: Node `v24.14.0`, npm `11.9.2`.
- [x] React/Vite dependencies and `package-lock.json` are installed/present.
- [x] `.env.example`: `VITE_API_BASE_URL=/api`, `VITE_API_PROXY_TARGET=http://localhost:8000`.
- [ ] Backend unavailable in current environment; API-backed login/modules cannot be manually verified.

From `campusfix-admin`, for a clean install or when dependencies are absent:

```powershell
npm ci
```

Create a local `.env` from `.env.example` only when the PHP API is running and only if `.env` does not already exist; otherwise leave it unchanged. The Vite proxy forwards `/api` to the configured backend target. Do not add credentials to frontend environment variables; these variables are bundled or exposed to browser code.

## Authentication/session behavior

- Login calls `POST /api/auth/login`; browser rejects non-ADMIN role responses.
- Token is stored in tab-scoped `sessionStorage` and verified via `GET /api/auth/me` on session restoration.
- HTTP 401 clears the stored session and dispatches the app unauthorized event; 403 remains a permission error.
- Logout calls `POST /api/auth/logout`, then clears local state.
- Protected complaint images use authenticated `apiBinary` and browser object URLs; they must only load for an authorized admin session.

Use a dedicated local ADMIN test account only. Do not use production credentials.

## Implemented modules

- Overview/dashboard statistics.
- Complaints: filters, detail/history, assignment, status and priority update.
- Students: list/search/status, detail, complaint history.
- Staff: list/detail, create/edit, active state.
- Departments and locations catalogs; department deletion uses backend reference checks; location deletion is not provided.
- Feedback list/detail/statistics.
- Current-admin notifications and profile.

These pages depend on backend routes and compatible database tables. The frontend alone does not verify API authorization or persistence.

## Automated checks

Run from `campusfix-admin`:

```powershell
npm run lint
npm run typecheck
npm test
npm run build
```

Tests currently exercise API client session helpers, JSON bearer/query/body requests, 401 invalidation, protected binary image request, and response data extraction. They are not backend integration tests.

## Local browser checklist

- [ ] Start backend and Vite; verify API proxy and inspect browser Network/Console for CORS, 401, 403, and JSON errors.
- [ ] Admin login rejects STUDENT/STAFF roles; reload restores valid ADMIN session; expired token clears session.
- [ ] Verify student/staff management, complaint assignment/status/priority, department deletion constraints, feedback, notifications, profile, protected image retrieval, and logout against dedicated disposable records.
- [ ] Confirm images fail closed for unauthorized requests and object URLs are released when detail views change.

No browser workflow is marked passed until exercised against the actual local API.
