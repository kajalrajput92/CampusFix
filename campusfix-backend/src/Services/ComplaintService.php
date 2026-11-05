<?php

namespace Campusfix\Backend\Services;

use Campusfix\Backend\Config\Database;
use Campusfix\Backend\Models\Complaint;
use InvalidArgumentException;
use PDO;

class ComplaintService
{
    private Complaint $complaintModel;
    private PDO $db;

    public function __construct()
    {
        $this->complaintModel = new Complaint();
        $this->db = Database::connect();
    }

    public function submit(int $studentId, array $data): array
    {
        $title = trim($data['title'] ?? '');
        $description = trim($data['description'] ?? '');
        $category = trim($data['category'] ?? '');

        $locationId = filter_var(
            $data['location_id'] ?? null,
            FILTER_VALIDATE_INT
        );

        $departmentId = null;

        if (
            isset($data['department_id']) &&
            $data['department_id'] !== ''
        ) {
            $departmentId = filter_var(
                $data['department_id'],
                FILTER_VALIDATE_INT
            );

            if ($departmentId === false || $departmentId <= 0) {
                throw new InvalidArgumentException(
                    'Invalid department ID.'
                );
            }
        }

        $priority = strtoupper(
            trim($data['priority'] ?? 'MEDIUM')
        );

        if ($title === '' || strlen($title) > 200) {
            throw new InvalidArgumentException(
                'Title is required and must not exceed 200 characters.'
            );
        }

        if ($description === '') {
            throw new InvalidArgumentException(
                'Complaint description is required.'
            );
        }

        if ($category === '' || strlen($category) > 100) {
            throw new InvalidArgumentException(
                'Valid complaint category is required.'
            );
        }

        if ($locationId === false || $locationId <= 0) {
            throw new InvalidArgumentException(
                'Valid campus location is required.'
            );
        }

        $allowedPriorities = ['LOW', 'MEDIUM', 'HIGH', 'URGENT'];

        if (!in_array($priority, $allowedPriorities, true)) {
            throw new InvalidArgumentException(
                'Invalid complaint priority.'
            );
        }

        // Verify that the selected location exists.
        $locationCheck = $this->db->prepare(
            'SELECT location_id FROM locations WHERE location_id = :id'
        );

        $locationCheck->execute(['id' => $locationId]);

        if (!$locationCheck->fetch()) {
            throw new InvalidArgumentException(
                'Selected campus location does not exist.'
            );
        }

        // Verify department if one was provided.
        if ($departmentId !== null) {
            $departmentCheck = $this->db->prepare(
                'SELECT department_id FROM departments WHERE department_id = :id'
            );

            $departmentCheck->execute(['id' => $departmentId]);

            if (!$departmentCheck->fetch()) {
                throw new InvalidArgumentException(
                    'Selected department does not exist.'
                );
            }
        }

        $complaintId = $this->complaintModel->create([
            'student_id' => $studentId,
            'location_id' => $locationId,
            'department_id' => $departmentId,
            'title' => $title,
            'description' => $description,
            'category' => $category,
            'priority' => $priority
        ]);

        $complaint = $this->complaintModel->findById($complaintId);

        return [
            'complaint_id' => $complaintId,
            'complaint_number' => $complaint['complaint_number'],
            'title' => $complaint['title'],
            'status' => $complaint['status'],
            'priority' => $complaint['priority'],
            'created_at' => $complaint['created_at']
        ];
    }

    public function getStudentComplaints(int $studentId): array
    {
        return $this->complaintModel->findByStudent($studentId);
    }

    public function getComplaintDetails(
    int $complaintId,
    int $studentId
): array {

    $complaint = $this->complaintModel->findDetailsById(
        $complaintId,
        $studentId
    );

    if (!$complaint) {
        throw new InvalidArgumentException(
            'Complaint not found.'
        );
    }

    $history = $this->complaintModel->getStatusHistory(
        $complaintId
    );

    return [
        'complaint' => $complaint,
        'status_history' => $history
    ];
}
public function updateComplaintStatus(
    int $complaintId,
    int $staffId,
    string $status,
    ?string $resolutionNotes = null
): array {
    $allowedStatuses = ['IN_PROGRESS', 'RESOLVED'];

    if (!in_array($status, $allowedStatuses, true)) {
        throw new InvalidArgumentException(
            'Invalid complaint status.'
        );
    }

    if ($complaintId <= 0 || $staffId <= 0) {
        throw new InvalidArgumentException(
            'Invalid complaint or staff ID.'
        );
    }

    if (
        $status === 'RESOLVED' &&
        trim((string) $resolutionNotes) === ''
    ) {
        throw new InvalidArgumentException(
            'Resolution notes are required.'
        );
    }

    return $this->complaintModel->updateStatus(
        $complaintId,
        $staffId,
        $status,
        $resolutionNotes
    );
}
public function getAllComplaints(array $filters = []): array
{
    // Validate status
    $allowedStatuses = [
        'SUBMITTED',
        'UNDER_REVIEW',
        'ASSIGNED',
        'IN_PROGRESS',
        'RESOLVED',
        'CLOSED',
        'REJECTED'
    ];

    if (!empty($filters['status'])) {
        $status = strtoupper(trim($filters['status']));

        if (!in_array($status, $allowedStatuses, true)) {
            throw new InvalidArgumentException(
                'Invalid complaint status filter.'
            );
        }

        $filters['status'] = $status;
    }

    // Validate priority
    $allowedPriorities = ['LOW', 'MEDIUM', 'HIGH', 'URGENT'];

    if (!empty($filters['priority'])) {
        $priority = strtoupper(trim($filters['priority']));

        if (!in_array($priority, $allowedPriorities, true)) {
            throw new InvalidArgumentException(
                'Invalid complaint priority filter.'
            );
        }

        $filters['priority'] = $priority;
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
        throw new InvalidArgumentException('Invalid page number.');
    }

    if ($perPage === false || $perPage < 1 || $perPage > 100) {
        throw new InvalidArgumentException(
            'Per page must be between 1 and 100.'
        );
    }

    $filters['page'] = $page;
    $filters['per_page'] = $perPage;

    return $this->complaintModel->findAll($filters);
}

public function getAdminComplaintDetails(int $complaintId): array
{
    if ($complaintId <= 0) {
        throw new InvalidArgumentException(
            'Invalid complaint ID.'
        );
    }

    $complaint = $this->complaintModel->findAdminDetailsById(
        $complaintId
    );

    if (!$complaint) {
        throw new InvalidArgumentException(
            'Complaint not found.'
        );
    }

    $history = $this->complaintModel->getStatusHistory(
        $complaintId
    );

    return [
        'complaint' => $complaint,
        'status_history' => $history
    ];
}
}