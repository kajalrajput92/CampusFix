<?php

namespace Campusfix\Backend\Controllers;

use Campusfix\Backend\Middleware\AuthMiddleware;
use Campusfix\Backend\Services\ProfileService;
use InvalidArgumentException;
use RuntimeException;
use Throwable;

class ProfileController
{
    private ProfileService $profileService;

    public function __construct()
    {
        $this->profileService = new ProfileService();
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

    private function getAuthenticatedUserId(): int
    {
        $user = AuthMiddleware::authenticate();

        return (int) $user->sub;
    }

    private function handleAuthException(RuntimeException $e): array
    {
        $statusCode = http_response_code();

        if ($statusCode !== 401 && $statusCode !== 403) {
            $statusCode = 401;
        }

        http_response_code($statusCode);

        return [
            'success' => false,
            'message' => $statusCode === 403
                ? 'You are not authorized to perform this action.'
                : 'Unauthorized. Invalid or expired token.'
        ];
    }

    // GET /api/profile
    public function show(): array
    {
        try {
            $userId = $this->getAuthenticatedUserId();

            $profile = $this->profileService->getProfile($userId);

            return [
                'success' => true,
                'message' => 'Profile retrieved successfully.',
                'data' => $profile
            ];

        } catch (InvalidArgumentException $e) {
            http_response_code(404);

            return [
                'success' => false,
                'message' => $e->getMessage()
            ];

        } catch (RuntimeException $e) {
            return $this->handleAuthException($e);

        } catch (Throwable $e) {
            error_log($e->getMessage());
            http_response_code(500);

            return [
                'success' => false,
                'message' => 'Internal server error.'
            ];
        }
    }

    // PATCH /api/profile
    public function update(): array
    {
        try {
            $userId = $this->getAuthenticatedUserId();
            $data = $this->getRequestData();

            $profile = $this->profileService->updateProfile(
                $userId,
                $data
            );

            return [
                'success' => true,
                'message' => 'Profile updated successfully.',
                'data' => $profile
            ];

        } catch (InvalidArgumentException $e) {
            http_response_code(422);

            return [
                'success' => false,
                'message' => $e->getMessage()
            ];

        } catch (RuntimeException $e) {
            return $this->handleAuthException($e);

        } catch (Throwable $e) {
            error_log($e->getMessage());
            http_response_code(500);

            return [
                'success' => false,
                'message' => 'Internal server error.'
            ];
        }
    }

    // PATCH /api/profile/password
    public function changePassword(): array
    {
        try {
            $userId = $this->getAuthenticatedUserId();
            $data = $this->getRequestData();

            $this->profileService->changePassword(
                $userId,
                $data
            );

            return [
                'success' => true,
                'message' => 'Password changed successfully.'
            ];

        } catch (InvalidArgumentException $e) {
            http_response_code(422);

            return [
                'success' => false,
                'message' => $e->getMessage()
            ];

        } catch (RuntimeException $e) {
            return $this->handleAuthException($e);

        } catch (Throwable $e) {
            error_log($e->getMessage());
            http_response_code(500);

            return [
                'success' => false,
                'message' => 'Internal server error.'
            ];
        }
    }
}
