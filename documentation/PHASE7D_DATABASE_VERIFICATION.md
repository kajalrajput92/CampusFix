# Phase 7D Database Verification Checklist

## Current result

The actual base schema is unresolved. Repository and reachable Git-history search found no authoritative schema export, DDL, or ERD. See [DATABASE_SCHEMA_GAPS.md](DATABASE_SCHEMA_GAPS.md) for table/query references and migration risks. Do not create guessed tables or run migrations.

## Required information on the target machine

Use a dedicated disposable MySQL database, not production. Obtain its authoritative schema source and deployment/migration record, then inspect:

- Every column, type, signedness, nullability, default, collation, and generated value for `users`, `complaints`, `complaint_assignments`, `complaint_status_history`, `complaint_images`, `departments`, `locations`, `feedback`, and `notifications`.
- Primary, unique, and secondary indexes; all FK targets and `ON DELETE` behavior; storage engine; check/enum constraints.
- Exact `users.user_id` and `complaints.complaint_id` types and matching FK column types.
- Whether `users.token_version`, `password_resets`, and `complaint_priority_history` already exist, whether their migrations were applied, and whether any data is present.
- Existing allowed status/priority values and audit/history retention requirements.
- That all migration tests use disposable fixtures and do not touch real users or complaints.

## Safe inspection sequence

1. Identify the MySQL service and confirm the host/port belong to the disposable local instance:

   ```powershell
   Get-Service *mysql*,*maria* -ErrorAction SilentlyContinue
   mysql --version
   Test-NetConnection 127.0.0.1 -Port 3306
   ```

2. Connect with an explicitly created local development account; `-p` prompts rather than placing a password in shell history. Do not use a production host or credential:

   ```powershell
   mysql -h 127.0.0.1 -u campusfix_dev -p campusfix_dev
   ```

3. Inspect actual object definitions without changing data:

   ```sql
   SHOW TABLES;
   SHOW CREATE TABLE users;
   SHOW CREATE TABLE complaints;
   SHOW CREATE TABLE complaint_assignments;
   SHOW CREATE TABLE complaint_status_history;
   SHOW CREATE TABLE complaint_images;
   SHOW CREATE TABLE departments;
   SHOW CREATE TABLE locations;
   SHOW CREATE TABLE feedback;
   SHOW CREATE TABLE notifications;
   SHOW CREATE TABLE password_resets;
   SHOW CREATE TABLE complaint_priority_history;
   ```

   For a table not present, record “absent”; do not infer its definition from application SQL.

4. Inspect column types, indexes, and foreign keys from metadata:

   ```sql
   SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT, EXTRA
   FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
   ORDER BY TABLE_NAME, ORDINAL_POSITION;

   SELECT TABLE_NAME, INDEX_NAME, NON_UNIQUE, SEQ_IN_INDEX, COLUMN_NAME
   FROM information_schema.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
   ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

   SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME,
          REFERENCED_COLUMN_NAME
   FROM information_schema.KEY_COLUMN_USAGE
   WHERE TABLE_SCHEMA = DATABASE() AND REFERENCED_TABLE_NAME IS NOT NULL
   ORDER BY TABLE_NAME, CONSTRAINT_NAME, ORDINAL_POSITION;
   ```

5. Compare those results with both migration files and [DATABASE_SCHEMA_GAPS.md](DATABASE_SCHEMA_GAPS.md). Record findings without copying credentials or personal data.
6. Do not apply a migration unless its referenced definitions, duplicate-object state, and destructive effects are understood and approved for the disposable DB. Test rollback only against disposable data; priority rollback destroys the newly recorded audit history. Do not run the password recovery migration on a schema where `token_version` may already exist.

## Migration-specific questions

### Password recovery migration

- Confirm `users.user_id` exactly matches `password_resets.user_id BIGINT UNSIGNED` and the referenced key is indexed/primary.
- Confirm `token_version` is absent before applying `ALTER TABLE`; the migration does not guard against it already existing.
- Confirm no incompatible `password_resets` table already exists. `CREATE TABLE IF NOT EXISTS` will not validate or repair an existing table.
- No rollback file exists. Decide how reset tokens and `token_version` should be handled before any manual rollback.

### Priority history migration

- Confirm `users.user_id` and `complaints.complaint_id` match the declared `BIGINT UNSIGNED` foreign key columns.
- Confirm table name and index/constraint names do not conflict with existing objects.
- Review whether deleting a complaint should cascade its priority audit history and whether deleting actors should be restricted.
- Forward creation does not alter base complaint rows. The rollback deletes the entire audit table and all of its rows; use only when that data loss is acceptable in disposable verification.

## Current checklist state

- [x] Source migrations inspected.
- [x] Repository/Git-history schema search performed.
- [ ] Actual base schema recovered.
- [ ] Column/FK/index compatibility confirmed.
- [ ] Disposable MySQL database available.
- [ ] Migration tested on disposable data.
- [ ] Rollback tested on disposable data.

Until all required schema checks are complete, migration compatibility is **not verified**.
