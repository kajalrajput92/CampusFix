<?php

require_once dirname(__DIR__) . '/vendor/autoload.php';

use Campusfix\Backend\Config\Database;
use Campusfix\Backend\Config\Environment;

Environment::load();

$email = $argv[1] ?? null;
$password = $argv[2] ?? null;
$fullName = $argv[3] ?? 'Administrator';

if (!$email || !$password) {
    echo "Usage: php bin/create-admin.php <email> <password> [full_name]\n";
    echo "Example: php bin/create-admin.php newadmin@campusfix.com AdminPass@123 \"New Admin\"\n";
    exit(1);
}

try {
    $db = Database::connect();

    $stmt = $db->prepare("SELECT user_id, role FROM users WHERE email = :email");
    $stmt->execute([':email' => $email]);
    $existing = $stmt->fetch();

    $passwordHash = password_hash($password, PASSWORD_BCRYPT);

    if ($existing) {
        $stmt = $db->prepare("
            UPDATE users 
            SET password_hash = :hash, role = 'ADMIN', full_name = :name, is_active = 1 
            WHERE user_id = :id
        ");
        $stmt->execute([
            ':hash' => $passwordHash,
            ':name' => $fullName,
            ':id' => $existing['user_id']
        ]);
        echo "Successfully updated existing user '{$email}' to ADMIN role.\n";
    } else {
        $stmt = $db->prepare("
            INSERT INTO users (full_name, email, password_hash, role, is_active, token_version, created_at, updated_at)
            VALUES (:name, :email, :hash, 'ADMIN', 1, 1, NOW(), NOW())
        ");
        $stmt->execute([
            ':name' => $fullName,
            ':email' => $email,
            ':hash' => $passwordHash
        ]);
        echo "Successfully created new ADMIN user '{$email}'!\n";
    }
} catch (Throwable $e) {
    echo "Error creating admin: " . $e->getMessage() . "\n";
    exit(1);
}
