<?php

namespace Campusfix\Backend\Services;

use Campusfix\Backend\Config\Database;
use Campusfix\Backend\Models\User;
use InvalidArgumentException;
use RuntimeException;
use Throwable;

class ProfileService
{
    private User $userModel;

    public function __construct()
    {
        $this->userModel = new User();
    }

    // Get the authenticated user's profile
    public function getProfile(int $userId): array
    {
        $profile = $this->userModel->findProfileById($userId);

        if (!$profile) {
            throw new InvalidArgumentException('User profile not found.');
        }

        return $profile;
    }

    // Update profile name and phone
    public function updateProfile(int $userId, array $data): array
    {
        $fullName = trim($data['full_name'] ?? '');
        $phone = trim($data['phone'] ?? '');

        if ($fullName === '') {
            throw new InvalidArgumentException('Full name is required.');
        }

        if (mb_strlen($fullName) > 150) {
            throw new InvalidArgumentException('Full name cannot exceed 150 characters.');
        }

        if ($phone !== '' && mb_strlen($phone) > 20) {
            throw new InvalidArgumentException('Phone cannot exceed 20 characters.');
        }

        $this->userModel->updateProfile(
            $userId,
            $fullName,
            $phone === '' ? null : $phone
        );

        return $this->getProfile($userId);
    }

    // Change password and invalidate existing sessions
    public function changePassword(int $userId, array $data): void
    {
        $currentPassword = $data['current_password'] ?? '';
        $newPassword = $data['new_password'] ?? '';

        if (!is_string($currentPassword) || $currentPassword === '') {
            throw new InvalidArgumentException('Current password is required.');
        }

        if (!is_string($newPassword) || strlen($newPassword) < 8) {
            throw new InvalidArgumentException('New password must be at least 8 characters.');
        }

        if (strlen($newPassword) > 72) {
            throw new InvalidArgumentException('New password cannot exceed 72 characters.');
        }

        $user = $this->userModel->findById($userId);

        if (!$user) {
            throw new InvalidArgumentException('User not found.');
        }

        if (!password_verify($currentPassword, $user['password_hash'])) {
            throw new InvalidArgumentException('Current password is incorrect.');
        }

        if (password_verify($newPassword, $user['password_hash'])) {
            throw new InvalidArgumentException('New password must be different from current password.');
        }

        $passwordHash = password_hash($newPassword, PASSWORD_DEFAULT);

        $db = Database::connect();
        $db->beginTransaction();

        try {
            if (!$this->userModel->updatePassword($userId, $passwordHash)) {
                throw new RuntimeException('Unable to update account password.');
            }

            if (!$this->userModel->incrementTokenVersion($userId)) {
                throw new RuntimeException('Unable to invalidate existing sessions.');
            }

            $db->commit();

        } catch (Throwable $e) {
            if ($db->inTransaction()) {
                $db->rollBack();
            }

            throw $e;
        }
    }
}
