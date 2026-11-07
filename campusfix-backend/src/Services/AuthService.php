<?php

namespace Campusfix\Backend\Services;

use Campusfix\Backend\Models\User;
use Campusfix\Backend\Helpers\JwtHelper;
use InvalidArgumentException;
use RuntimeException;

class AuthService
{
    private User $userModel;

    public function __construct()
    {
        $this->userModel = new User();
    }

    public function register(array $data): array
    {
        $name = trim($data['full_name'] ?? '');
        $email = strtolower(trim($data['email'] ?? ''));
        $password = $data['password'] ?? '';

        if ($name === '' || $email === '' || $password === '') {
            throw new InvalidArgumentException(
                'Name, email and password are required.'
            );
        }

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException('Invalid email address.');
        }

        if (strlen($password) < 8) {
            throw new InvalidArgumentException(
                'Password must contain at least 8 characters.'
            );
        }

        if ($this->userModel->findByEmail($email)) {
            throw new InvalidArgumentException(
                'Email is already registered.'
            );
        }

        $userId = $this->userModel->create([
            'full_name' => $name,
            'email' => $email,
            'password_hash' => password_hash($password, PASSWORD_DEFAULT),
            'phone' => $data['phone'] ?? null,
            'department_id' => $data['department_id'] ?? null,
            'role' => 'STUDENT',
            'enrollment_number' => $data['enrollment_number'] ?? null
        ]);

        return [
            'user_id' => $userId,
            'full_name' => $name,
            'email' => $email,
            'role' => 'STUDENT'
        ];
    }

    public function login(string $email, string $password): array
    {
        $email = strtolower(trim($email));

        $user = $this->userModel->findByEmail($email);

        if (
            !$user ||
            !password_verify($password, $user['password_hash'])
        ) {
            throw new InvalidArgumentException(
                'Invalid email or password.'
            );
        }

        if (!$user['is_active']) {
            throw new InvalidArgumentException(
                'This account is inactive.'
            );
        }

        $token = JwtHelper::generateToken($user);

        return [
            'access_token' => $token,
            'token_type' => 'Bearer',
            'expires_in' => (int) ($_ENV['JWT_EXPIRY'] ?? 3600),
            'user' => [
                'user_id' => (int) $user['user_id'],
                'full_name' => $user['full_name'],
                'email' => $user['email'],
                'role' => $user['role']
            ]
        ];
    }
}