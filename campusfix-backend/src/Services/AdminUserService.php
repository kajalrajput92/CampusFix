<?php

namespace Campusfix\Backend\Services;

use Campusfix\Backend\Models\Department;
use Campusfix\Backend\Models\User;
use Campusfix\Backend\Services\ConflictException;
use InvalidArgumentException;

class AdminUserService
{
    private User $users;
    private Department $departments;

    public function __construct()
    {
        $this->users = new User();
        $this->departments = new Department();
    }

    public function students(array $filters): array
    {
        $search = trim((string) ($filters['search'] ?? ''));
        if (mb_strlen($search) > 100) throw new InvalidArgumentException('Search must not exceed 100 characters.');
        $active = $filters['is_active'] ?? null;
        if ($active !== null && $active !== '') {
            $active = filter_var($active, FILTER_VALIDATE_INT);
            if ($active === false || !in_array($active, [0, 1], true)) throw new InvalidArgumentException('is_active must be 0 or 1.');
        } else $active = null;
        return $this->users->findAllStudents(['search' => $search, 'is_active' => $active] + $this->pagination($filters));
    }

    public function student(int $studentId): array
    {
        if ($studentId <= 0) throw new InvalidArgumentException('Valid student ID is required.');
        $student = $this->users->findStudentDetailsById($studentId);
        if (!$student) throw new InvalidArgumentException('Student not found.');
        return $student;
    }

    public function studentComplaints(int $studentId, array $filters): array
    {
        $this->student($studentId);
        $pagination = $this->pagination($filters);
        return $this->users->findStudentComplaints($studentId, $pagination['page'], $pagination['per_page']);
    }

    public function changeStudentStatus(int $studentId, mixed $value): array
    {
        $active = filter_var($value, FILTER_VALIDATE_INT);
        if ($studentId <= 0 || $active === false || !in_array($active, [0, 1], true)) throw new InvalidArgumentException('Valid student ID and is_active (0 or 1) are required.');
        $this->student($studentId);
        $this->users->updateStudentStatus($studentId, (bool) $active);
        return $this->student($studentId);
    }

    public function createStaff(array $data): array
    {
        $validated = $this->validateStaff($data, true);
        if ($this->users->findByEmail($validated['email'])) throw new ConflictException('Email is already registered.');
        $id = $this->users->create([
            ...$validated,
            'password_hash' => password_hash($validated['password'], PASSWORD_DEFAULT),
            'role' => 'STAFF',
        ]);
        return (new StaffService())->getStaffDetails($id);
    }

    public function updateStaff(int $staffId, array $data): array
    {
        if ($staffId <= 0) throw new InvalidArgumentException('Valid staff ID is required.');
        (new StaffService())->getStaffDetails($staffId);
        $validated = $this->validateStaff($data, false);
        $existing = $this->users->findByEmail($validated['email']);
        if ($existing && (int) $existing['user_id'] !== $staffId) throw new ConflictException('Email is already registered.');
        $this->users->updateStaff($staffId, $validated);
        return (new StaffService())->getStaffDetails($staffId);
    }

    private function validateStaff(array $data, bool $creating): array
    {
        $name = trim((string) ($data['full_name'] ?? ''));
        $email = strtolower(trim((string) ($data['email'] ?? '')));
        $phone = trim((string) ($data['phone'] ?? ''));
        $employeeId = trim((string) ($data['employee_id'] ?? ''));
        if ($name === '' || mb_strlen($name) > 150) throw new InvalidArgumentException('Full name is required and must not exceed 150 characters.');
        if (!filter_var($email, FILTER_VALIDATE_EMAIL) || mb_strlen($email) > 255) throw new InvalidArgumentException('A valid email address is required.');
        if (mb_strlen($phone) > 20) throw new InvalidArgumentException('Phone must not exceed 20 characters.');
        if (mb_strlen($employeeId) > 100) throw new InvalidArgumentException('Employee ID must not exceed 100 characters.');
        $departmentId = $data['department_id'] ?? null;
        if ($departmentId === '' || $departmentId === null) $departmentId = null;
        else {
            $departmentId = filter_var($departmentId, FILTER_VALIDATE_INT);
            if ($departmentId === false || $departmentId <= 0) throw new InvalidArgumentException('Department ID must be a positive integer.');
            $this->departments->findById($departmentId) ?: throw new InvalidArgumentException('Department not found.');
        }
        $result = ['full_name' => $name, 'email' => $email, 'phone' => $phone !== '' ? $phone : null, 'department_id' => $departmentId, 'employee_id' => $employeeId !== '' ? $employeeId : null];
        if ($creating) {
            $password = $data['password'] ?? '';
            if (!is_string($password) || strlen($password) < 8) throw new InvalidArgumentException('Password must contain at least 8 characters.');
            $result['password'] = $password;
        }
        return $result;
    }

    private function pagination(array $filters): array
    {
        $page = filter_var($filters['page'] ?? 1, FILTER_VALIDATE_INT);
        $perPage = filter_var($filters['per_page'] ?? 10, FILTER_VALIDATE_INT);
        if ($page === false || $page < 1) throw new InvalidArgumentException('Invalid page number.');
        if ($perPage === false || $perPage < 1 || $perPage > 100) throw new InvalidArgumentException('Per page must be between 1 and 100.');
        return ['page' => $page, 'per_page' => $perPage];
    }
}
