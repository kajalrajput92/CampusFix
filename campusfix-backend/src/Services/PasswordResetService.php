<?php

namespace Campusfix\Backend\Services;

use Campusfix\Backend\Config\Database;
use Campusfix\Backend\Models\PasswordReset;
use Campusfix\Backend\Models\User;
use PDO;
use InvalidArgumentException;
use RuntimeException;
use Throwable;

class PasswordResetService
{
    private PDO $db;
    private User $userModel;
    private PasswordReset $resetModel;
    private EmailService $emailService;

    public function __construct()
    {
        $this->db = Database::connect();
        $this->userModel = new User();
        $this->resetModel = new PasswordReset();
        $this->emailService = new EmailService();
    }

    // Request a password reset link
    public function forgotPassword(string $email): void
    {
        $email = strtolower(trim($email));

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException(
                'A valid email address is required.'
            );
        }

        $user = $this->userModel->findByEmail($email);

        // Do not reveal whether an email is registered.
        if (!$user || !(int) $user['is_active']) {
            return;
        }

        $token = bin2hex(random_bytes(32));
        $tokenHash = hash('sha256', $token);

        $appUrl = rtrim($_ENV['APP_URL'] ?? '', '/');

        if (!filter_var($appUrl, FILTER_VALIDATE_URL)) {
            throw new RuntimeException('Application URL is not configured.');
        }

        $expiresAt = date('Y-m-d H:i:s', time() + 1800);

        $this->db->beginTransaction();

        try {
            $this->resetModel->invalidatePreviousTokens(
                (int) $user['user_id']
            );

            $this->resetModel->create([
                'user_id' => (int) $user['user_id'],
                'token_hash' => $tokenHash,
                'expires_at' => $expiresAt
            ]);

            $this->db->commit();

        } catch (Throwable $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }

            throw $e;
        }

        $resetLink = $appUrl
            . '/reset-password?token='
            . urlencode($token);

        try {
            $this->emailService->sendPasswordResetEmail(
                $user['email'],
                $user['full_name'],
                $resetLink
            );

        } catch (Throwable $e) {
            // Invalidate the token if email delivery fails.
            $this->resetModel->invalidatePreviousTokens(
                (int) $user['user_id']
            );

            throw new RuntimeException(
                'Unable to send password reset email.'
            );
        }
    }

    // Reset password using a valid one-time token
    public function resetPassword(
        string $token,
        string $newPassword
    ): void {
        if (!preg_match('/^[a-f0-9]{64}$/i', $token)) {
            throw new InvalidArgumentException(
                'Invalid or expired password reset token.'
            );
        }

        if (strlen($newPassword) < 8) {
            throw new InvalidArgumentException(
                'New password must contain at least 8 characters.'
            );
        }

        if (strlen($newPassword) > 72) {
            throw new InvalidArgumentException(
                'New password cannot exceed 72 characters.'
            );
        }

        $tokenHash = hash('sha256', $token);
        $passwordHash = password_hash(
            $newPassword,
            PASSWORD_DEFAULT
        );

        $this->db->beginTransaction();

        try {
            $reset = $this->resetModel->findValidTokenForUpdate(
                $tokenHash
            );

            if (!$reset) {
                throw new InvalidArgumentException(
                    'Invalid or expired password reset token.'
                );
            }

            $userId = (int) $reset['user_id'];

            if (!$this->userModel->updatePassword(
                $userId,
                $passwordHash
            )) {
                throw new RuntimeException(
                    'Unable to update account password.'
                );
            }

            if (!$this->userModel->incrementTokenVersion($userId)) {
                throw new RuntimeException(
                    'Unable to invalidate existing sessions.'
                );
            }

            if (!$this->resetModel->markAsUsed(
                (int) $reset['reset_id']
            )) {
                throw new RuntimeException(
                    'Unable to consume password reset token.'
                );
            }

            $this->db->commit();

        } catch (Throwable $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }

            throw $e;
        }
    }
}
