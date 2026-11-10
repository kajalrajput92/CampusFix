# CampusFix Admin Console

React/Vite admin interface for the existing PHP API. Run `npm install`, then `npm run dev`. Configure `VITE_API_BASE_URL` to the API base URL ending in `/api`; for local development, the Vite proxy can forward `/api` requests using `VITE_API_PROXY_TARGET`. See `.env.example`.

The console stores the bearer token in `sessionStorage` for tab-scoped session restoration, then verifies it through `GET /api/auth/me` before rendering protected pages. This browser storage remains readable by same-origin JavaScript; production deployment should serve the frontend/API from a trusted origin, use HTTPS, and apply a restrictive Content Security Policy. The app clears the session after HTTP 401. HTTP 403 is surfaced as a permission error and does not silently sign the user out. Login is shared with other roles, so the UI rejects any response whose `data.user.role` is not `ADMIN`, and confirms the role again with `/auth/me`.

## Audited API contract

Admin endpoints below require `Authorization: Bearer <JWT>` and are authorized by `AuthMiddleware::authorize(['ADMIN'])`, except where noted. JSON success envelopes are `{success:true,message,data:...}`. Error envelopes are `{success:false,message:...}`; validation commonly returns 422, authorization 401/403, and unexpected failures 500. Login is shared across roles, so the frontend checks the returned role before granting console access.

| Method and route | Contract verified from source | Console use |
| --- | --- | --- |
| `POST /api/auth/login` | JSON `email`, `password`; `data.access_token`, `token_type`, `expires_in`, and `user` (`user_id`, `full_name`, `email`, `role`). Invalid credentials return 401. | Login; only ADMIN accepted. |
| `GET /api/auth/me` | Bearer JWT; `data` has `user_id`, `email`, `role`. Authenticated role can be any account; frontend requires ADMIN. | Session restoration and role check. |
| `GET /api/admin/dashboard/stats` | ADMIN; `data.complaints` totals/aliases (`total_complaints`, submitted, under_review, assigned, in_progress, resolved, closed, rejected) and `data.users` totals by role. | Dashboard cards and status counts. |
| `GET /api/admin/complaints` | ADMIN; query `status`, `priority`, `category`, `search`, `page`, `per_page` (1–100; default 10). `data` is a complaint array; `pagination` has `total`, `page`, `per_page`, `total_pages`. | Search, filters, pagination. |
| `GET /api/admin/complaints/show?id={id}` | ADMIN; positive integer `id`; `data.complaint`, `data.images` (`image_path` only), `data.status_history`. | Details and status history. |
| `POST /api/admin/complaints/assign` | ADMIN; JSON positive integer `complaint_id`, `staff_id`; assignment sets status to ASSIGNED. Resolved/closed/rejected or inactive staff are rejected. | Confirmed staff assignment. |
| `GET /api/admin/staff` | ADMIN; `search`, `is_active` (0/1), `page`, `per_page` (1–100; default 10); `data` staff array (including `assigned_complaints`) and `pagination` object. | Staff list, filters, assignment counts. |
| `GET /api/admin/staff/show?id={id}` | ADMIN; positive integer id; `data` staff details. | Detail dialog; sensitive-looking fields are filtered from output. |
| `PATCH /api/admin/staff/status` | ADMIN; JSON `staff_id`, `is_active` (0/1). | Activate/deactivate with confirmation. |
| `GET /api/admin/departments` | ADMIN, STUDENT, STAFF; `data` array. The `/api/departments` alias has the same authorization. | Catalog listing. |
| `GET /api/admin/departments/show?id={id}` | ADMIN; positive integer id; `data` department. | No separate detail call required by UI. |
| `POST /api/admin/departments` | ADMIN; JSON `department_name` (required, max 100), optional `description` (max 5000); 201 and created object. | Create. |
| `PATCH /api/admin/departments/update` | ADMIN; JSON `department_id`, `department_name`, optional `description`; updated object. | Update. |
| `GET /api/admin/locations` | ADMIN, STUDENT, STAFF; `data` array. `/api/locations` is the shared alias. | Catalog listing. |
| `GET /api/admin/locations/show?id={id}` | ADMIN; positive integer id; `data` location. | Catalog item lookup route audited. |
| `POST /api/admin/locations` | ADMIN; JSON `building_name` required (max 150), optional `block_name` max 100, `floor_number` max 20, `room_number` max 30, `description` max 5000; 201. | Create. |
| `PATCH /api/admin/locations/update` | ADMIN; JSON `location_id` and location fields above. | Update. |
| `GET /api/admin/feedback` | ADMIN; query `rating`, `search`, `page`; `data.feedback` array and `data.pagination` (`total`, `page`, `per_page`, `total_pages`). Controller passes `limit`, but model reads `per_page`, so API currently uses default 10. | Search, rating filter, pagination using default page size. |
| `GET /api/admin/feedback/show?feedback_id={id}` | ADMIN; positive integer `feedback_id`; `data` feedback detail. | Feedback detail dialog. |
| `GET /api/admin/feedback/stats` | ADMIN; `data` has `total_feedback`, `average_rating`, and per-star counts. | Dashboard and feedback overview. |
| `GET /api/notifications` | ADMIN allowed; scoped to current JWT user; query `is_read`, `page`, `limit` (1–100; default 20); `data` array (no pagination envelope). | Admin's own notifications. |
| `PATCH /api/notifications/read?notification_id={id}` | ADMIN allowed; positive integer ID; service scopes update to current authenticated user. | Mark one read. |
| `PATCH /api/notifications/read-all` | ADMIN allowed; no body; scopes to current authenticated user. | Mark all read. |
| `DELETE /api/notifications/delete?notification_id={id}` | ADMIN allowed; positive integer ID; service scopes deletion to current authenticated user. | Delete an own-account notification after confirmation. |
| `GET /api/profile` | Any authenticated role, not ADMIN-specific; `data` profile excludes password hash. | Read-only profile after separate ADMIN verification. |

## Phase 7 API additions and limitations

The companion Phase 7 backend work adds admin student list/detail/status and complaint history routes, staff create/edit routes, admin complaint status and priority updates, department deletion guarded against references, complaint image streaming with role and ownership checks, staff assignment-scoped details, and token-revoking logout. The browser uses these routes directly. Status and priority changes are recorded in their respective histories; priority history requires applying `database/migrations/2026_11_10_complaint_priority_history.sql`.

The API still provides account-scoped notifications only; there is no admin-wide feed or broadcast operation. Location deletion is not implemented because the existing schema/API does not provide a safe reference policy. Dashboard data remains aggregate-only, without recent activity or department breakdowns. Cross-origin use requires setting the backend's `CORS_ALLOWED_ORIGINS` to exact trusted origins; the Vite development proxy is available for local use. Feedback pagination accepts both `per_page` and the legacy `limit` parameter.

The backend's base schema and live database were not available during this implementation. Before deployment, confirm the priority history migration's key types and foreign key targets against the actual schema, apply the migration, and exercise the API smoke checks with dedicated test accounts and records. Do not apply the migration to production without a backup and schema review.
