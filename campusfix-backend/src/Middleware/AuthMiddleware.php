<?php

namespace Campusfix\Backend\Middleware;

use Campusfix\Backend\Helpers\JwtHelper;
use Campusfix\Backend\Models\User;
use Throwable;

class AuthMiddleware
{
    public static function authenticate(): object
    {
        $headers = getallheaders();

        $authHeader = $headers['Authorization']
            ?? $headers['authorization']
            ?? '';

        if (!preg_match('/^Bearer\s+(.+)$/i', $authHeader, $matches)) {
            http_response_code(401);

            throw new \RuntimeException(
                'Authorization token is missing.'
            );
        }

        try {
            $token = JwtHelper::verifyToken(trim($matches[1]));

            $userModel = new User();
            $currentVersion = $userModel->getTokenVersion(
                (int) $token->sub
            );

            $tokenVersion = (int) ($token->token_version ?? 0);

            if (
                $currentVersion === false ||
                $tokenVersion !== $currentVersion
            ) {
                throw new \RuntimeException(
                    'Authentication token has been revoked.'
                );
            }

            return $token;

        } catch (Throwable $e) {
            http_response_code(401);

            throw new \RuntimeException(
                'Invalid, expired or revoked authentication token.'
            );
        }
    }

    public static function authorize(array $allowedRoles): object
    {
        $user = self::authenticate();

        if (!in_array($user->role, $allowedRoles, true)) {
            http_response_code(403);

            throw new \RuntimeException(
                'You do not have permission to access this resource.'
            );
        }

        return $user;
    }
}
