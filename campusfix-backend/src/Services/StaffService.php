<?php

namespace Campusfix\Backend\Services;

use Campusfix\Backend\Models\User;
use InvalidArgumentException;

class StaffService
{
    private User $userModel;

    public function __construct()
    {
        $this->userModel = new User();
    }

    // Get all staff with search, active filter and pagination
    public function getAllStaff(array $filters = []): array
    {
        // Validate search
        if (isset($filters['search'])) {
            $filters['search'] = trim($filters['search']);

            if (strlen($filters['search']) > 100) {
                throw new InvalidArgumentException(
                    'Search must not exceed 100 characters.'
                );
            }
        }

        // Validate active filter
        if (isset($filters['is_active']) && $filters['is_active'] !== '') {
            $isActive = filter_var(
                $filters['is_active'],
                FILTER_VALIDATE_INT
            );

            if ($isActive === false || !in_array($isActive, [0, 1], true)) {
                throw new InvalidArgumentException(
                    'is_active must be 0 or 1.'
                );
            }

            $filters['is_active'] = $isActive;
        } else {
            unset($filters['is_active']);
        }

        // Validate pagination
        $page = filter_var(
            $filters['page'] ?? 1,
            FILTER_VALIDATE_INT
        );

        $perPage = filter_var(
            $filters['per_page'] ?? 10,
            FILTER_VALIDATE_INT
        );

        if ($page === false || $page < 1) {
            throw new InvalidArgumentException(
                'Invalid page number.'
            );
        }

        if ($perPage === false || $perPage < 1 || $perPage > 100) {
            throw new InvalidArgumentException(
                'Per page must be between 1 and 100.'
            );
        }

        $filters['page'] = $page;
        $filters['per_page'] = $perPage;

        return $this->userModel->findAllStaff($filters);
    }

    // Get individual staff details
    public function getStaffDetails(int $staffId): array
    {
        if ($staffId <= 0) {
            throw new InvalidArgumentException(
                'Valid staff ID is required.'
            );
        }

        $staff = $this->userModel->findStaffDetailsById($staffId);

        if (!$staff) {
            throw new InvalidArgumentException(
                'Staff member not found.'
            );
        }

        return $staff;
    }

    // Activate or deactivate staff
    public function changeStaffStatus(
        int $staffId,
        mixed $isActive
    ): array {
        if ($staffId <= 0) {
            throw new InvalidArgumentException(
                'Valid staff ID is required.'
            );
        }

        $status = filter_var(
            $isActive,
            FILTER_VALIDATE_INT
        );

        if ($status === false || !in_array($status, [0, 1], true)) {
            throw new InvalidArgumentException(
                'is_active must be either 0 or 1.'
            );
        }

        $staff = $this->userModel->findStaffDetailsById($staffId);

        if (!$staff) {
            throw new InvalidArgumentException(
                'Staff member not found.'
            );
        }

        $newStatus = (bool) $status;
        $currentStatus = (bool) $staff['is_active'];

        if ($newStatus === $currentStatus) {
            throw new InvalidArgumentException(
                'Staff member is already in the requested status.'
            );
        }

        $updated = $this->userModel->updateStaffStatus(
            $staffId,
            $newStatus
        );

        if (!$updated) {
            throw new \RuntimeException(
                'Unable to update staff status.'
            );
        }

        return [
            'staff_id' => $staffId,
            'full_name' => $staff['full_name'],
            'is_active' => (int) $newStatus,
            'status' => $newStatus ? 'ACTIVE' : 'INACTIVE'
        ];
    }
}
