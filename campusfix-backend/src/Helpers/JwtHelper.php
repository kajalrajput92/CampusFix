<?php

namespace Campusfix\Backend\Helpers;

use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use UnexpectedValueException;

class JwtHelper
{
    private static function getSecret(): string
    {
        $secret = $_ENV['JWT_SECRET'] ?? '';

        if (strlen($secret) < 64) {
            throw new \RuntimeException(
                'JWT secret is missing or invalid.'
            );
        }

        return $secret;
    }


public static function generateToken(array $user): string
{
    $now = time();
    $expiry = (int) ($_ENV['JWT_EXPIRY'] ?? 3600);

    $payload = [
        'iss' => 'CampusFix',
        'iat' => $now,
        'exp' => $now + $expiry,
        'sub' => (string) $user['user_id'],
        'role' => $user['role'],
        'email' => $user['email'],
        'token_version' => (int) ($user['token_version'] ?? 0)
    ];

    return JWT::encode(
        $payload,
        self::getSecret(),
        'HS256'
    );
}


    public static function verifyToken(string $token): object
    {
        return JWT::decode(
            $token,
            new Key(self::getSecret(), 'HS256')
        );
    }
}
