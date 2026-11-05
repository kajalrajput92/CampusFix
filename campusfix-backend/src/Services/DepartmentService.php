<?php

namespace Campusfix\Backend\Services;

use Campusfix\Backend\Models\Department;
use InvalidArgumentException;

class DepartmentService
{
    private Department $departmentModel;

    public function __construct()
    {
        $this->departmentModel = new Department();
    }

    // Get all departments
    public function getAllDepartments(): array
    {
        return $this->departmentModel->findAll();
    }

    // Get department details
    public function getDepartmentDetails(int $departmentId): array
    {
        if ($departmentId <= 0) {
            throw new InvalidArgumentException(
                'Valid department ID is required.'
            );
        }

        $department = $this->departmentModel->findById(
            $departmentId
        );

        if (!$department) {
            throw new InvalidArgumentException(
                'Department not found.'
            );
        }

        return $department;
    }

    // Create department
    public function createDepartment(array $data): array
    {
        $departmentName = trim($data['department_name'] ?? '');
        $description = trim($data['description'] ?? '');

        if (
            $departmentName === '' ||
            strlen($departmentName) > 100
        ) {
            throw new InvalidArgumentException(
                'Department name is required and must not exceed 100 characters.'
            );
        }

        if (strlen($description) > 5000) {
            throw new InvalidArgumentException(
                'Description must not exceed 5000 characters.'
            );
        }

        $departmentId = $this->departmentModel->create([
            'department_name' => $departmentName,
            'description' => $description !== '' ? $description : null
        ]);

        return $this->getDepartmentDetails($departmentId);
    }

    // Update department
    public function updateDepartment(
        int $departmentId,
        array $data
    ): array {
        if ($departmentId <= 0) {
            throw new InvalidArgumentException(
                'Valid department ID is required.'
            );
        }

        $departmentName = trim($data['department_name'] ?? '');
        $description = trim($data['description'] ?? '');

        if (
            $departmentName === '' ||
            strlen($departmentName) > 100
        ) {
            throw new InvalidArgumentException(
                'Department name is required and must not exceed 100 characters.'
            );
        }

        if (strlen($description) > 5000) {
            throw new InvalidArgumentException(
                'Description must not exceed 5000 characters.'
            );
        }

        $existing = $this->departmentModel->findById(
            $departmentId
        );

        if (!$existing) {
            throw new InvalidArgumentException(
                'Department not found.'
            );
        }

        $this->departmentModel->update($departmentId, [
            'department_name' => $departmentName,
            'description' => $description !== '' ? $description : null
        ]);

        return $this->getDepartmentDetails($departmentId);
    }
}
