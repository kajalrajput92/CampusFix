# Phase 7D Local Runtime Runbook (Windows)

This runbook preserves the current workspace. Do not reset, clean, discard, overwrite, commit, or push existing changes. The backend is Core PHP. No database schema is supplied; therefore this runbook deliberately does not execute migrations or invent table DDL.

## 1. Record the current repository state

From the repository root:

```powershell
git status --short --branch
git branch --show-current
git log -1 --format="%H%n%s%n%ci"
git diff --cached --name-status
git diff --name-status
git ls-files --others --exclude-standard
```

Record staged, modified, and untracked paths before testing. Preserve them; do not use `git reset`, `git clean`, or checkout/revert commands.

## 2. Check installed toolchains

```powershell
php -v
php -m
composer --version
mysql --version
node --version
npm.cmd --version
dart --version
flutter --version
flutter doctor -v
```

Missing commands block the corresponding steps; do not report unavailable checks as passing. PHP needs `pdo_mysql`, `mbstring`, and `fileinfo`; use `openssl` when testing SMTP. Flutter’s Dart must satisfy `campusfix-mobile/pubspec.yaml` (`^3.13.2`).

## 3. Check local MySQL, then inspect the actual schema

Do not connect to a production host. Select a dedicated disposable local database containing only test data. Identify a local service without guessing its name:

```powershell
Get-Service *mysql*,*maria* -ErrorAction SilentlyContinue
Test-NetConnection 127.0.0.1 -Port 3306
```

If the local service is stopped, start only the service name verified above (Service Control Manager may require elevation). Connect with a local development account; `-p` prompts for the secret:

```powershell
mysql -h 127.0.0.1 -u campusfix_dev -p campusfix_dev
```

Run the read-only schema inspection sequence in [PHASE7D_DATABASE_VERIFICATION.md](PHASE7D_DATABASE_VERIFICATION.md): `SHOW TABLES`, `SHOW CREATE TABLE`, and `information_schema` column/index/FK queries. Record actual types and signedness. The repository’s SQL/query references are not a substitute for deployed DDL.

## 4. Review migration compatibility without applying migrations

Review:

- `database/migrations/2026_11_05_password_recovery.sql`
- `database/migrations/2026_11_10_complaint_priority_history.sql`
- `database/migrations/2026_11_10_complaint_priority_history.down.sql`
- `documentation/DATABASE_SCHEMA_GAPS.md`

Compare key column types, signedness, duplicate objects, indexes, existing `token_version`, and delete rules with the actual local schema. Do not execute migrations until every mismatch/duplicate-object issue is resolved and explicitly approved for disposable verification. No migration is being authorized by this runbook.

## 5. Install backend dependencies

In one terminal, from repository root:

```powershell
cd campusfix-backend
composer validate
composer install
```

Use the committed `composer.lock`. Stop if Composer reports PHP/extensions/lockfile errors; record the exact output without changing dependency versions as a workaround.

## 6. Configure a local backend `.env`

From `campusfix-backend`:

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env } else { Write-Output '.env already exists; leave it unchanged.' }
```

Edit `.env` locally only; do not paste it into messages or commit it. Set the disposable local DB values and `CORS_ALLOWED_ORIGINS=http://localhost:5173,http://127.0.0.1:5173`. Add `JWT_SECRET` (required by `JwtHelper`, at least 64 characters) using a locally generated random value:

```powershell
php -r "echo bin2hex(random_bytes(32)), PHP_EOL;"
```

SMTP variables are only needed for password-reset email. Use dedicated local test mail credentials if needed; never use production values.

## 7. Start the Core PHP API

From `campusfix-backend`, start a terminal and leave it running:

```powershell
php -S 127.0.0.1:8000 -t public public/index.php
```

The router entry point is `public/index.php`; health handling uses the database connection.

## 8. Verify API health and authentication

In another terminal:

```powershell
curl.exe -i http://127.0.0.1:8000/api/health
```

Expected full health result is HTTP 200 JSON with `success: true` and `database: "connected"`. The JSON includes DB server version. If `database` is `disconnected`, stop full-stack testing and fix local connection/schema setup. Verify authentication interactively with a dedicated local test account only; do not put secrets in shell history, screenshots, or logs.

After creating only dedicated local test fixtures, the backend smoke check can run from `campusfix-backend`:

```powershell
php tests/api_security_smoke.php
```

Configure required `CAMPUSFIX_TEST_*` environment variables for disposable STUDENT/STAFF/ADMIN fixtures. Optional `CAMPUSFIX_TEST_LOGOUT_TOKEN` is revoked, so use a disposable token. Never use real accounts.

## 9. Start React Admin and test admin login

In a third terminal, from repository root:

```powershell
cd campusfix-admin
```

Dependencies are already installed in this workspace; for a clean checkout use `npm ci`. Create local `.env` from `.env.example` only if it does not already exist; otherwise leave it unchanged. Confirm the API proxy target, then run:

```powershell
npm run dev -- --host 127.0.0.1
```

Open `http://127.0.0.1:5173`. Verify ADMIN login and role rejection, session restoration, and logout using dedicated local data. Inspect browser Network and Console; the React dev page loading does not prove API integration.

## 10. Run Flutter analysis and tests

In a fourth terminal, from repository root:

```powershell
cd campusfix-mobile
flutter doctor -v
flutter pub get
dart format lib test
flutter analyze
flutter test
```

Record every command’s exit code and output. Do not claim Android/device behavior from these checks alone.

## 11. Build the Android debug APK

After analysis/tests and Android toolchain setup:

```powershell
flutter build apk --debug
```

Expected artifact: `campusfix-mobile/build/app/outputs/flutter-apk/app-debug.apk`.

## 12. Test role workflows using dedicated local fixtures

Use the Android emulator’s default `http://10.0.2.2:8000/api`; use a reachable LAN URL for a physical test device, supplied as `--dart-define=API_BASE_URL=...` without credentials.

- STUDENT: login; submit complaint with and without permitted images; list/detail only own complaints; access only own image; feedback only when eligible; mark own notification read; logout and verify revoked-token rejection.
- STAFF: login; list only current assignments; access assigned detail/image; reject unassigned complaint/image; update allowed status; mark own notification read; logout.
- ADMIN: login to React; reject non-admin role; assign complaint; manage student/staff records; apply allowed status/priority changes; respect department reference deletion rules; inspect feedback/notifications; access an image as authorized admin; logout and verify token revocation.
- Cross-role: attempt ADMIN-only and STAFF-only endpoints with other role tokens; expect 403. Unauthenticated/expired/revoked requests should be 401. Owner/assignment-scoped missing records should not disclose other users’ data.

Never use production credentials or live records.

## 13. Record failures and unresolved issues

Capture tool versions, command, exit code, HTTP status, and sanitized error text. Do not include passwords, JWTs, `.env`, SMTP secrets, real personal data, or unredacted server logs. Keep automated tests, manual browser testing, manual mobile/device testing, and source-only checks clearly distinguished. Schema/migration compatibility remains unresolved until authoritative DDL is inspected.
