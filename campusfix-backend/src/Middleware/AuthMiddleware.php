<?php

namespace Campusfix\Backend\Middleware;

use Campusfix\Backend\Helpers\JwtHelper;
use UnexpectedValueException;
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
            return JwtHelper::verifyToken(trim($matches[1]));
        } catch (Throwable $e) {
            http_response_code(401);

            throw new \RuntimeException(
                'Invalid or expired authentication token.'
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