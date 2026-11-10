<?php
/**
 * Read-mostly integration checks for a disposable/local CampusFix API.
 * Configure credentials and IDs for dedicated test accounts before running.
 */

function requiredEnv(string $key): string
{
    $value = getenv($key);
    if ($value === false || trim($value) === '') {
        fwrite(STDERR, "Missing required environment variable: {$key}\n");
        exit(2);
    }
    return trim($value);
}

function requestApi(string $base, string $path, string $token): array
{
    $headers = "Accept: application/json\r\nAuthorization: Bearer {$token}\r\n";
    $context = stream_context_create(['http' => [
        'method' => 'GET',
        'header' => $headers,
        'ignore_errors' => true,
        'timeout' => 10,
    ]]);
    $body = @file_get_contents(rtrim($base, '/') . $path, false, $context);
    $status = 0;
    foreach ($http_response_header ?? [] as $header) {
        if (preg_match('/^HTTP\/\S+\s+(\d{3})/', $header, $match)) {
            $status = (int) $match[1];
        }
    }
    return [$status, $body === false ? '' : $body];
}

function checkStatus(string $label, int $actual, int $expected): void
{
    if ($actual !== $expected) {
        fwrite(STDERR, "FAIL {$label}: expected HTTP {$expected}, got {$actual}\n");
        exit(1);
    }
    echo "PASS {$label} (HTTP {$actual})\n";
}

$base = requiredEnv('CAMPUSFIX_TEST_BASE_URL');
$studentToken = requiredEnv('CAMPUSFIX_TEST_STUDENT_TOKEN');
$staffToken = requiredEnv('CAMPUSFIX_TEST_STAFF_TOKEN');
$adminToken = requiredEnv('CAMPUSFIX_TEST_ADMIN_TOKEN');
$studentId = rawurlencode(requiredEnv('CAMPUSFIX_TEST_STUDENT_ID'));
$foreignComplaintId = rawurlencode(requiredEnv('CAMPUSFIX_TEST_FOREIGN_COMPLAINT_ID'));
$unassignedComplaintId = rawurlencode(requiredEnv('CAMPUSFIX_TEST_UNASSIGNED_COMPLAINT_ID'));

[$status] = requestApi($base, '/api/admin/students?page=1&per_page=1', $adminToken);
checkStatus('admin can list students', $status, 200);
[$status] = requestApi($base, '/api/admin/students?page=1&per_page=1', $studentToken);
checkStatus('student cannot list all students', $status, 403);
[$status] = requestApi($base, '/api/admin/students?page=1&per_page=1', $staffToken);
checkStatus('staff cannot list all students', $status, 403);
[$status] = requestApi($base, '/api/admin/students/show?id=' . $studentId, $adminToken);
checkStatus('admin can view student detail', $status, 200);
[$status] = requestApi($base, '/api/complaints/show?id=' . $foreignComplaintId, $studentToken);
checkStatus('student cannot view another student complaint', $status, 404);
[$status] = requestApi($base, '/api/staff/complaints/show?id=' . $unassignedComplaintId, $staffToken);
checkStatus('staff cannot view an unassigned complaint', $status, 404);

if (($logoutToken = getenv('CAMPUSFIX_TEST_LOGOUT_TOKEN')) !== false && trim($logoutToken) !== '') {
    $logoutToken = trim($logoutToken);
    $context = stream_context_create(['http' => [
        'method' => 'POST',
        'header' => "Accept: application/json\r\nAuthorization: Bearer {$logoutToken}\r\nContent-Type: application/json\r\n",
        'content' => '{}',
        'ignore_errors' => true,
        'timeout' => 10,
    ]]);
    @file_get_contents(rtrim($base, '/') . '/api/auth/logout', false, $context);
    $status = 0;
    foreach ($http_response_header ?? [] as $header) {
        if (preg_match('/^HTTP\/\S+\s+(\d{3})/', $header, $match)) {
            $status = (int) $match[1];
        }
    }
    checkStatus('dedicated logout token can log out', $status, 200);
    [$status] = requestApi($base, '/api/auth/me', $logoutToken);
    checkStatus('logout revokes its token', $status, 401);
}
