<?php

namespace Campusfix\Backend\Controllers;

use Campusfix\Backend\Services\PasswordResetService;
use InvalidArgumentException;
use Throwable;

class PasswordResetController
{
    private PasswordResetService $passwordResetService;

    public function __construct()
    {
        $this->passwordResetService = new PasswordResetService();
    }

    private function getRequestData(): array
    {
        $rawInput = file_get_contents('php://input');
        $data = json_decode($rawInput, true);

        if (!is_array($data)) {
            throw new InvalidArgumentException(
                'A valid JSON request body is required.'
            );
        }

        return $data;
    }

    // POST /api/auth/forgot-password
    public function forgotPassword(): array
    {
        try {
            $data = $this->getRequestData();
            $email = $data['email'] ?? '';

            if (!is_string($email) || trim($email) === '') {
                throw new InvalidArgumentException(
                    'Email address is required.'
                );
            }

            $this->passwordResetService->forgotPassword($email);

            return [
                'success' => true,
                'message' => 'If an account exists with this email, password reset instructions will be sent.'
            ];

        } catch (InvalidArgumentException $e) {
            http_response_code(422);

            return [
                'success' => false,
                'message' => $e->getMessage()
            ];

        } catch (Throwable $e) {
            error_log($e->getMessage());
            http_response_code(500);

            return [
                'success' => false,
                'message' => 'Unable to process password reset request.'
            ];
        }
    }

    // POST /api/auth/reset-password
    public function resetPassword(): array
    {
        try {
            $data = $this->getRequestData();

            $token = $data['token'] ?? '';
            $newPassword = $data['new_password'] ?? '';

            if (!is_string($token) || !is_string($newPassword)) {
                throw new InvalidArgumentException(
                    'Token and new password must be strings.'
                );
            }

            if ($token === '' || $newPassword === '') {
                throw new InvalidArgumentException(
                    'Token and new password are required.'
                );
            }

            $this->passwordResetService->resetPassword(
                $token,
                $newPassword
            );

            return [
                'success' => true,
                'message' => 'Password has been reset successfully. Please log in again.'
            ];

        } catch (InvalidArgumentException $e) {
            http_response_code(422);

            return [
                'success' => false,
                'message' => $e->getMessage()
            ];

        } catch (Throwable $e) {
            error_log($e->getMessage());
            http_response_code(500);

            return [
                'success' => false,
                'message' => 'Unable to reset password.'
            ];
        }
    }
}
