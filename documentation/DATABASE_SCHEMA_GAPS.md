# CampusFix Database Schema Gaps — Do Not Apply Migrations Yet

## Recovery result

No authoritative base schema was recoverable from the current repository or Git refs inspected on 2026-11-10. Repository search found only:

- `database/migrations/2026_11_05_password_recovery.sql`
- `database/migrations/2026_11_10_complaint_priority_history.sql`
- `database/migrations/2026_11_10_complaint_priority_history.down.sql`

Git history contains the password recovery migration but no base schema export, `CREATE TABLE` script, ERD, or schema documentation. The migration files are not a complete schema. No database client/server is installed, no local backend `.env` or database is available, and port 3306 was closed. No migration was executed.

The following are **application query references**, not recovered schema definitions. They must not be treated as proof of actual SQL types, nullability, indexes, constraints, engine, or deployed migration state.

## Tables referenced by the application

| Table | Example identifiers/fields referenced in backend source | Missing authoritative details |
|---|---|---|
| `users` | `user_id`, `department_id`, `full_name`, `email`, `password_hash`, `phone`, `role`, `enrollment_number`, `employee_id`, `is_active`, `token_version`, timestamps | Actual `user_id` type/signedness, all column definitions/defaults, role constraints, email uniqueness, department FK, and whether `token_version` is in the base schema or migration state. |
| `complaints` | `complaint_id`, `student_id`, `department_id`, `location_id`, `complaint_number`, title/description/category, priority/status, resolution fields, timestamps | Actual primary/foreign-key types, indexes, enums/check constraints, defaults, delete rules, and status/priority history expectations. |
| `complaint_assignments` | assignment/complaint/staff/admin IDs, `assigned_at`; latest assignment is selected by greatest `assignment_id` | Full column types, uniqueness/indexes, FK rules, reassignment history semantics, and whether assignment IDs are monotonic. |
| `complaint_status_history` | complaint/actor IDs, old/new status, remarks, `changed_at` | Actual schema, actor FK, indexes, nullability, retention/delete behavior. |
| `complaint_images` | image/complaint IDs and `image_path` | Actual key types, uniqueness/indexes, path length, FK/delete rules. |
| `departments` | `department_id`, name, description, timestamps | Actual column definitions, constraints, indexes, and key type. |
| `locations` | `location_id`, building/block/floor/room/description fields | Actual column definitions, constraints, indexes, and whether complaint references prevent deletion. |
| `feedback` | feedback/complaint/student IDs, rating/comments, timestamps | Actual key types, uniqueness enforcing one feedback per complaint, rating constraints, FK rules. |
| `notifications` | notification/user/complaint IDs, title/message/read state, timestamps | Actual types, indexes, nullability, and cascade behavior. |
| `password_resets` | Defined by the 2026-11-05 migration: reset ID, user ID, token hash, expiry/use/creation timestamps | Whether this migration ran, whether an object already exists with another definition, and whether `users.user_id` is compatible with the declared FK. |
| `complaint_priority_history` | Defined by the Phase 7 migration: history ID, complaint ID, actor ID, old/new priority, `changed_at` | Whether the table already exists and whether the declared FKs match real key types. The rollback deletes this table and its audit history. |

Other source queries reference authentication/session, profile, feedback, notification, catalog, and password reset columns; exact schema recovery must inspect the complete SQL source alongside the original schema, not just the examples above.

## Migration review and unresolved compatibility

### `2026_11_05_password_recovery.sql`

- Adds `users.token_version INT UNSIGNED NOT NULL DEFAULT 0`. Compatibility depends on the actual `users` table and whether that column already exists. The `ALTER TABLE ... ADD COLUMN` is not idempotent.
- Creates `password_resets` with `user_id BIGINT UNSIGNED` and a cascading FK to `users(user_id)`. MySQL requires compatible referencing/referenced integer types and signedness; the actual referenced type is unknown.
- Adds unique index on `token_hash`, plus indexes on `user_id` and `expires_at`; no existing schema/index collision check is possible.
- `CREATE TABLE IF NOT EXISTS` will leave a pre-existing table unchanged, even if its shape is incompatible.
- No rollback migration is present. Reversing it would require deciding how to handle live reset tokens and `token_version`; dropping these without reviewing active app use is unsafe.

### `2026_11_10_complaint_priority_history.sql`

- Creates a new InnoDB table; creation does not intentionally rewrite complaint/user records.
- Both complaint and actor IDs are declared `BIGINT UNSIGNED`; actual key definitions are unknown, so FK compatibility is unverified.
- The `(complaint_id, changed_at)` and `changed_by` indexes support the source query’s per-complaint chronological history and actor FK lookups. Index names and any pre-existing table were not checked against a live schema.
- FK behavior cascades priority audit rows when a complaint is deleted and restricts deleting an actor referenced by audit rows. Product/data-retention compatibility has not been confirmed.

### `2026_11_10_complaint_priority_history.down.sql`

- Contains only `DROP TABLE complaint_priority_history`.
- It does not touch the base complaint/user tables, but permanently deletes every priority audit row. It is only appropriate as rollback of this migration on the same disposable database after explicitly accepting audit loss.
- It is not safe to run if this table predates the migration or contains data that must be retained.

## Information needed before safe migration or integration testing

Obtain an authoritative, versioned schema export or DDL from the project owner, plus migration/deployment history. Verify:

1. Exact type and signedness of `users.user_id`, `complaints.complaint_id`, and every related FK column.
2. All columns, nullability, defaults, collations, indexes, unique constraints, and primary keys for the tables listed above.
3. InnoDB engine and existing FK targets/delete rules.
4. Whether `users.token_version`, `password_resets`, or `complaint_priority_history` already exist and whether their migrations ran.
5. Existing complaint status/priority constraints, allowed values, and audit-history conventions.
6. A dedicated disposable local MySQL database and test fixture plan with no real user data.

Until then, do not fabricate a schema, import an unknown dump, or run either migration. This document intentionally records the gap rather than substituting guessed DDL.
