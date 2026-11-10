<?php

namespace Campusfix\Backend\Controllers;

use Campusfix\Backend\Services\AuthService;
use InvalidArgumentException;
use Throwable;
use Campusfix\Backend\Middleware\AuthMiddleware;
class AuthController
{
    private AuthService $authService;

    public function __construct()
    {
        $this->authService = new AuthService();
    }

    /**
     * Read and validate JSON request body.
     */
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

    /**
     * Student registration API.
     */
    public function register(): array
    {
        try {
            $data = $this->getRequestData();

            $user = $this->authService->register($data);

            http_response_code(201);

            return [
                'success' => true,
                'message' => 'Student registered successfully.',
                'data' => $user
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
                'message' => 'Internal server error.'
            ];
        }
    }

    /**
     * User login API.
     */
    public function login(): array
    {
        try {
            $data = $this->getRequestData();

            $email = $data['email'] ?? '';
            $password = $data['password'] ?? '';

            if (!is_string($email) || !is_string($password)) {
                throw new InvalidArgumentException(
                    'Email and password must be strings.'
                );
            }

            if (trim($email) === '' || $password === '') {
                throw new InvalidArgumentException(
                    'Email and password are required.'
                );
            }

            $result = $this->authService->login(
                $email,
                $password
            );

            return [
                'success' => true,
                'message' => 'Login successful.',
                'data' => $result
            ];

        } catch (InvalidArgumentException $e) {
            http_response_code(401);

            return [
                'success' => false,
                'message' => $e->getMessage()
            ];

        } catch (Throwable $e) {
            error_log($e->getMessage());

            http_response_code(500);

            return [
                'success' => false,
                'message' => 'Internal server error.'
            ];
        }
    }

    public function me(): array
{
    try {
        $user = AuthMiddleware::authenticate();

        return [
            'success' => true,
            'message' => 'Authenticated successfully.',
            'data' => [
                'user_id' => $user->sub,
                'email' => $user->email,
                'role' => $user->role
            ]
        ];

    } catch (Throwable $e) {
        http_response_code(401);

        return [
            'success' => false,
            'message' => 'Unauthorized. Invalid or expired token.'
        ];
    }
}

    public function logout(): array
    {
        try {
            $user = AuthMiddleware::authenticate();
            $this->authService->logout((int) $user->sub);
            return ['success' => true, 'message' => 'Session revoked successfully.', 'data' => null];
        } catch (Throwable $e) {
            if (http_response_code() < 400) http_response_code(500);
            return ['success' => false, 'message' => http_response_code() === 401 ? 'Unauthorized. Invalid or expired token.' : 'Unable to revoke session.'];
        }
    }
}
