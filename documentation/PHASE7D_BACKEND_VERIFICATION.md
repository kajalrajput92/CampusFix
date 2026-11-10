# Phase 7D Backend Verification Checklist

Core PHP is required by the project. Keep the existing PHP backend; do not replace it with a framework.

## Source inspection checklist

- [x] Entry point: `campusfix-backend/public/index.php` loads Composer autoloading and `.env`, applies exact-origin CORS, dispatches the method/path route table, JSON-encodes controller results, and logs uncaught exceptions.
- [x] Router: `campusfix-backend/routes/api.php`; route key format is `METHOD /api/path`.
- [x] Dependency manifest and lock: `composer.json` and `composer.lock`; dependencies are dotenv, firebase/php-jwt, and PHPMailer.
- [x] Environment template: `.env.example`; database, app URL, CORS, and SMTP placeholders exist. **`JWT_SECRET` is required by `JwtHelper` but is absent from the template.** Add a local random value to ignored `.env`; do not commit it.
- [x] Database connector: `src/Config/Database.php` uses PDO MySQL and native prepared statements. `HealthController` calls the database and returns `database: connected|disconnected` plus server version.
- [x] Authentication: JWT uses HS256; secret must be at least 64 characters. Middleware compares `token_version` and rejects inactive/missing users.
- [x] Upload storage: `storage/uploads/complaints` under backend is created on demand with mode 0750. PHP process needs write access. Backend accepts up to 5 images, 5 MiB each, JPEG/PNG/WebP; PHP `upload_max_filesize` and `post_max_size` must be large enough (for example 6M and 32M). `fileinfo` is used for MIME detection. Stored uploads are not public; API streams authorized images.
- [x] CORS: allowlist comes from `CORS_ALLOWED_ORIGINS`; local React origins are configured in the template. Unknown origins do not receive allow headers; OPTIONS from unknown origins returns 403.
- [x] Errors: controllers return `{success,message,...}` JSON envelopes and status codes; unexpected failures use `error_log`. PHP built-in server output is local diagnostic output. Never paste logs containing sensitive SQL/configuration information into reports.
- [ ] Runtime health, PHP syntax, authentication, uploads, ownership/role checks, and migration-dependent requests: **not run here** (PHP/Composer/MySQL unavailable).

## Target Windows machine checklist

Run from PowerShell after installing PHP 8.1+ (including `pdo_mysql`, `mbstring`, and `fileinfo`; enable `openssl` for SMTP) and Composer 2.x:

```powershell
php -v
php -m
composer --version
composer validate
composer install
Get-Service *mysql*,*maria* -ErrorAction SilentlyContinue
Test-NetConnection 127.0.0.1 -Port 3306
```

Use a disposable local database only. Before migration review, inspect the actual schema as described in [PHASE7D_DATABASE_VERIFICATION.md](PHASE7D_DATABASE_VERIFICATION.md). Do not execute migrations during this checklist.

From `campusfix-backend`:

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env } else { Write-Output '.env already exists; leave it unchanged.' }
```

Edit `.env` locally. Set local-only DB values, exact CORS origins, and `JWT_SECRET` (generate locally with `php -r "echo bin2hex(random_bytes(32)), PHP_EOL;"`). Do not show or share `.env` values. Configure SMTP only with a dedicated test mailbox if password-reset email must be tested.

Check PHP syntax for all backend PHP files:

```powershell
Get-ChildItem src,routes,public,tests -Recurse -Filter *.php | ForEach-Object { php -l $_.FullName }
```

Start the API from `campusfix-backend`:

```powershell
php -S 127.0.0.1:8000 -t public public/index.php
```

In a second PowerShell terminal:

```powershell
curl.exe -i http://127.0.0.1:8000/api/health
```

Expected when PHP dependencies and DB connection work: HTTP 200 JSON with `success: true`, `database: "connected"`, and `database_version`. When the API starts but DB is unavailable, the health action reports `database: "disconnected"`; do not call that a healthy full-stack result.

For role/ownership smoke checks, create dedicated local fixtures and configure the `CAMPUSFIX_TEST_*` variables listed at the top of `campusfix-backend/tests/api_security_smoke.php`. Run:

```powershell
php tests/api_security_smoke.php
```

That script checks admin student access, student/staff role denial, foreign-student complaint access, and staff access to an unassigned complaint. Optional logout testing revokes its supplied disposable token. Do not use real accounts or production tokens.

## Runtime checklist

- [ ] `composer validate` and `composer install` succeed.
- [ ] All PHP files pass `php -l`.
- [ ] Health reports database connected.
- [ ] Login rejects inactive test users and accepts only valid local fixtures.
- [ ] Logout revokes the test JWT; an authenticated request with it then returns 401.
- [ ] Admin/student/staff role and complaint ownership checks match the documented route contracts.
- [ ] Upload and protected image retrieval work for allowed viewers and fail for unauthorized viewers.
- [ ] CORS allows only the configured React origins.
- [ ] PHP logs contain no passwords, tokens, or `.env` values.

Every unchecked runtime item remains unverified until actually run on the target machine.
