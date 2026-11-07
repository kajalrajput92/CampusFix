<?php

namespace Campusfix\Backend\Models;

use Campusfix\Backend\Config\Database;
use PDO;

class PasswordReset
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::connect();
    }

    // Create a password reset request
    public function create(array $data): int
    {
        $sql = "
            INSERT INTO password_resets (
                user_id,
                token_hash,
                expires_at
            ) VALUES (
                :user_id,
                :token_hash,
                :expires_at
            )
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            'user_id' => $data['user_id'],
            'token_hash' => $data['token_hash'],
            'expires_at' => $data['expires_at']
        ]);

        return (int) $this->db->lastInsertId();
    }

    // Find a valid reset token
    public function findValidToken(string $tokenHash): array|false
    {
        $sql = "
            SELECT
                reset_id,
                user_id,
                token_hash,
                expires_at,
                used_at
            FROM password_resets
            WHERE token_hash = :token_hash
              AND expires_at > NOW()
              AND used_at IS NULL
            LIMIT 1
        ";

        $stmt = $this->db->prepare($sql);
        $stmt->execute(['token_hash' => $tokenHash]);

        return $stmt->fetch();
    }

    // Invalidate previous unused reset requests
    public function invalidatePreviousTokens(int $userId): void
    {
        $sql = "
            UPDATE password_resets
            SET used_at = NOW()
            WHERE user_id = :user_id
              AND used_at IS NULL
        ";

        $stmt = $this->db->prepare($sql);
        $stmt->execute(['user_id' => $userId]);
    }

    // Mark token as used exactly once
    public function markAsUsed(int $resetId): bool
    {
        $sql = "
            UPDATE password_resets
            SET used_at = NOW()
            WHERE reset_id = :reset_id
              AND used_at IS NULL
              AND expires_at > NOW()
        ";

        $stmt = $this->db->prepare($sql);
        $stmt->execute(['reset_id' => $resetId]);

        return $stmt->rowCount() > 0;
    }

    // Delete expired reset requests
    public function deleteExpiredTokens(): int
    {
        $sql = "
            DELETE FROM password_resets
            WHERE expires_at <= NOW()
        ";

        $stmt = $this->db->prepare($sql);
        $stmt->execute();

        return $stmt->rowCount();
    }
    // Find and lock a valid token inside a transaction
public function findValidTokenForUpdate(string $tokenHash): array|false
{
    $sql = "
        SELECT
            reset_id,
            user_id,
            token_hash,
            expires_at,
            used_at
        FROM password_resets
        WHERE token_hash = :token_hash
          AND expires_at > NOW()
          AND used_at IS NULL
        LIMIT 1
        FOR UPDATE
    ";

    $stmt = $this->db->prepare($sql);
    $stmt->execute(['token_hash' => $tokenHash]);

    return $stmt->fetch();
}
}
