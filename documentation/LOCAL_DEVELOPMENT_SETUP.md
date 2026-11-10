# CampusFix Local Development Setup

This guide documents the existing repository setup. It does not provide a replacement database schema. The original schema was not present in the working tree or reachable Git history; see [DATABASE_SCHEMA_GAPS.md](DATABASE_SCHEMA_GAPS.md). Do not run migrations until the actual base schema has been recovered and checked.

## Environment inventory (2026-11-10)

| Tool | Observed state |
|---|---|
| PHP CLI and extensions | Missing. Version and extension availability could not be queried. The code needs PHP 8.1+ syntax, `PDO` with `pdo_mysql`, `mbstring`, and `fileinfo`; enable `openssl` for SMTP/TLS. |
| Composer | Missing. `campusfix-backend/composer.lock` exists; no `vendor/autoload.php`. |
| MySQL/MariaDB client/server | `mysql`, `mysqld`, and `mariadb` commands missing; TCP 3306 was closed. No backend `.env` exists. |
| Dart / Flutter | Missing. `campusfix-mobile/pubspec.yaml` requires Dart `^3.13.2`; no SDK dependency resolution was attempted. |
| Node.js / npm | Node `v24.14.0`, npm `11.9.2`. |
| React dependencies | Installed in `campusfix-admin/node_modules`; lockfile is present. `npm install` completed in Phase 7B. |
| React dev server | Responded HTTP 200 on port 5173 at the last check. |

## Required software and references

- PHP 8.1 or newer, CLI SAPI, with `pdo_mysql`, `mbstring`, and `fileinfo`; enable `openssl` for password-reset email transport. The PHP 8.1 floor follows PHP syntax used in the backend (including string-key array unpacking). Install a supported Windows build from [PHP Windows downloads](https://www.php.net/downloads.php?os=windows) and follow the [PHP installation manual](https://www.php.net/manual/en/install.php). See the PHP docs for [PDO](https://www.php.net/manual/en/pdo.installation.php), [PDO MySQL](https://www.php.net/manual/en/ref.pdo-mysql.php), and [fileinfo](https://www.php.net/manual/en/fileinfo.installation.php).
- Composer 2.x. Install with the [official Composer instructions](https://getcomposer.org/doc/00-intro.md).
- MySQL-compatible server with InnoDB, foreign keys, and `utf8mb4` support. The repository does not state a tested server version; confirm compatibility once the original schema is available. [Official MySQL Community downloads](https://dev.mysql.com/downloads/) include the Windows installer.
- Flutter SDK with bundled Dart satisfying the `^3.13.2` constraint in `campusfix-mobile/pubspec.yaml`; Android Studio and Android SDK are needed for Android builds. Follow [Flutter install](https://docs.flutter.dev/install) and check with `flutter doctor`.
- Node.js and npm. The observed Node 24/npm 11 setup works with the installed admin dependencies. Use the [official Node.js downloads](https://nodejs.org/en/download) if needed.

## Backend setup

From the repository root, after PHP and Composer are installed:

```powershell
cd campusfix-backend
composer install
if (-not (Test-Path .env)) { Copy-Item .env.example .env } else { Write-Output '.env already exists; leave it unchanged.' }
```

Edit only the local `.env` (it is ignored by Git). Set the database connection to a **disposable local development database**, and add a locally generated `JWT_SECRET` of at least 64 characters. For example, after PHP is installed:

```powershell
php -r "echo bin2hex(random_bytes(32)), PHP_EOL;"
```

Use the resulting value only in the local `.env`. Do not use production credentials. Configure `CORS_ALLOWED_ORIGINS` for the local React origin, normally `http://localhost:5173,http://127.0.0.1:5173`. SMTP values are only needed to test password-reset email; use a dedicated test mailbox and app credential, never a personal or production secret.

**Database prerequisite:** obtain and review the real base schema before creating tables or applying migrations. No schema import command can safely be provided until its source, table types, and foreign keys are verified. Never point this application at a production database for local setup.

Start the backend API from `campusfix-backend`:

```powershell
php -S 127.0.0.1:8000 -t public public/index.php
```

After dependencies, local `.env`, and disposable database are configured, verify:

```powershell
Invoke-WebRequest http://127.0.0.1:8000/api/health
```

The health route reports API and database connection state; a successful HTTP response alone is not proof the database is connected.

## Database setup and migrations

1. Recover the original base schema from its source project/maintainer or a known-good development export.
2. Confirm the types and signedness of `users.user_id` and `complaints.complaint_id`, the existing `users.token_version` state, table engines, referenced keys, and whether either migration has already been applied.
3. Create a dedicated disposable database and import only the reviewed base schema into it.
4. Review both migrations in [DATABASE_SCHEMA_GAPS.md](DATABASE_SCHEMA_GAPS.md). Test forward and rollback behavior only against disposable data. The priority rollback deliberately drops its audit table and its audit records.

No migration has been run in this workspace.

## Flutter setup

From `campusfix-mobile`:

```powershell
flutter doctor
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

The app defaults to `http://10.0.2.2:8000/api`, appropriate for an Android emulator talking to a host-machine API. For a physical device, use the host's reachable LAN address and configure the firewall/API bind address accordingly, for example:

```powershell
flutter run --dart-define=API_BASE_URL=http://<host-lan-ip>:8000/api
```

Do not put credentials or tokens in `--dart-define` values.

## React admin setup

Dependencies and `package-lock.json` are already present. From `campusfix-admin`:

```powershell
npm ci
npm run lint
npm run typecheck
npm test
npm run build
npm run dev -- --host 127.0.0.1
```

The Vite proxy is configured by `VITE_API_PROXY_TARGET`; `.env.example` points it to `http://localhost:8000`. To use it, create a local `.env` from the example. The admin app is served at `http://127.0.0.1:5173` by default. A working browser login requires the PHP API and a dedicated local ADMIN test account.

## API and integration verification

After the original schema is recovered and the disposable DB is populated only with dedicated test fixtures:

```powershell
cd campusfix-backend
php tests/api_security_smoke.php
```

The smoke script requires its documented `CAMPUSFIX_TEST_*` environment variables; use disposable STUDENT, STAFF, ADMIN tokens and fixture IDs only. Run the manual integration scenarios from the Phase 7B checklist with those accounts. Never print tokens or passwords in logs or reports.

## Troubleshooting

- **`php`, `composer`, `dart`, or `flutter` not recognized:** install the official SDK/tool, add its executable directory to the user PATH, open a fresh terminal, and rerun `Get-Command` / `flutter doctor`.
- **Composer cannot install:** check PHP version/extensions and network access, then retry `composer install` using the committed lockfile.
- **Database connection fails:** verify MySQL is running, the disposable DB exists, local `.env` connection values match it, and `pdo_mysql` is enabled. Never solve this by using production credentials.
- **`/api/health` says database disconnected:** inspect local PHP logs and DB connectivity; do not interpret the API-running message as database success.
- **React API requests fail:** start the PHP server, confirm the Vite proxy target and backend CORS allowlist, then inspect the browser Network panel. `npm run dev` alone only serves the frontend.
- **Migration FK/type mismatch:** stop. Compare the exact deployed-development schema types and signedness before changing or applying a migration.
- **Android emulator cannot reach API:** use `10.0.2.2` for the host loopback; physical devices require a reachable host address and firewall rule.

## Current verification status

React dependencies are installed, the React checks passed during Phase 7B, and the local Vite page returned HTTP 200. PHP, Composer, MySQL, Dart, and Flutter were absent at inventory time. Backend setup, migration tests, Flutter checks, and full-stack testing therefore remain pending.
