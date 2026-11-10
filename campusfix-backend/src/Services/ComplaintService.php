<?php

namespace Campusfix\Backend\Services;

use Campusfix\Backend\Config\Database;
use Campusfix\Backend\Models\Complaint;
use InvalidArgumentException;
use PDO;
use Throwable;

class ComplaintService
{
    private Complaint $complaintModel;
    private PDO $db;
    private ImageUploadService $imageUploadService;
    private NotificationService $notificationService;

    public function __construct()
    {
        $this->complaintModel = new Complaint();
        $this->db = Database::connect();
        $this->imageUploadService = new ImageUploadService();
        $this->notificationService = new NotificationService();
    }

    /**
     * Submit a complaint with optional images.
     */
    public function submit(
        int $studentId,
        array $data,
        array $files = []
    ): array {

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

        $allowedPriorities = [
            'LOW',
            'MEDIUM',
            'HIGH',
            'URGENT'
        ];

        if (!in_array($priority, $allowedPriorities, true)) {
            throw new InvalidArgumentException(
                'Invalid complaint priority.'
            );
        }

        // Verify that the selected location exists.
        $locationCheck = $this->db->prepare(
            'SELECT location_id FROM locations WHERE location_id = :id'
        );

        $locationCheck->execute([
            'id' => $locationId
        ]);

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

            $departmentCheck->execute([
                'id' => $departmentId
            ]);

            if (!$departmentCheck->fetch()) {
                throw new InvalidArgumentException(
                    'Selected department does not exist.'
                );
            }
        }

        $imagePaths = [];

        try {
            // Upload images only when files are supplied.
            if (!empty($files)) {
                $imagePaths = $this->imageUploadService->upload(
                    $files
                );
            }

            // Create complaint and image records atomically.
            $complaintId = $this->complaintModel->create(
                [
                    'student_id' => $studentId,
                    'location_id' => $locationId,
                    'department_id' => $departmentId,
                    'title' => $title,
                    'description' => $description,
                    'category' => $category,
                    'priority' => $priority
                ],
                $imagePaths
            );

        } catch (Throwable $e) {

            // Remove physical files if database insertion fails.
            if (!empty($imagePaths)) {
                $this->imageUploadService->deleteFiles(
                    $imagePaths
                );
            }

            throw $e;
        }

        $complaint = $this->complaintModel->findById(
            $complaintId
        );

        // Send complaint submission notification to student.
        try {
            $this->notificationService->createNotification([
                'user_id' => $studentId,
                'complaint_id' => $complaintId,
                'type' => 'COMPLAINT_SUBMITTED',
                'title' => 'Complaint Submitted',
                'message' => 'Your complaint '
                    . $complaint['complaint_number']
                    . ' has been submitted successfully.'
            ]);

        } catch (Throwable $e) {
            error_log(
                'Complaint notification failed: ' . $e->getMessage()
            );
        }

        return [
            'complaint_id' => $complaintId,
            'complaint_number' => $complaint['complaint_number'],
            'title' => $complaint['title'],
            'status' => $complaint['status'],
            'priority' => $complaint['priority'],
            'created_at' => $complaint['created_at'],
            'images' => $this->complaintModel->findImagesByComplaintId(
                $complaintId
            )
        ];
    }

    /**
     * Get complaints submitted by a student.
     */
    public function getStudentComplaints(int $studentId): array
    {
        return $this->complaintModel->findByStudent(
            $studentId
        );
    }

    /**
     * Get complaint details for a student.
     */
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

        $images = $this->complaintModel->findImagesByComplaintId(
            $complaintId
        );

        return [
            'complaint' => $complaint,
            'images' => $images,
            'status_history' => $history
        ];
    }

    /**
     * Update complaint status by assigned staff.
     */
    public function updateComplaintStatus(
        int $complaintId,
        int $staffId,
        string $status,
        ?string $resolutionNotes = null
    ): array {

        $allowedStatuses = [
            'IN_PROGRESS',
            'RESOLVED'
        ];

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

        // Update complaint status and commit database transaction.
        $result = $this->complaintModel->updateStatus(
            $complaintId,
            $staffId,
            $status,
            $resolutionNotes
        );

        // Send notification to student after successful status update.
        try {
            $stmt = $this->db->prepare("
                SELECT student_id, complaint_number
                FROM complaints
                WHERE complaint_id = :complaint_id
                LIMIT 1
            ");

            $stmt->execute([
                'complaint_id' => $complaintId
            ]);

            $complaint = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($complaint) {
                $isResolved = $status === 'RESOLVED';

                $this->notificationService->createNotification([
                    'user_id' => (int) $complaint['student_id'],
                    'complaint_id' => $complaintId,
                    'type' => $isResolved
                        ? 'COMPLAINT_RESOLVED'
                        : 'COMPLAINT_IN_PROGRESS',
                    'title' => $isResolved
                        ? 'Complaint Resolved'
                        : 'Complaint Work Started',
                    'message' => $isResolved
                        ? 'Your complaint '
                            . $complaint['complaint_number']
                            . ' has been resolved successfully.'
                        : 'Work has started on your complaint '
                            . $complaint['complaint_number']
                            . '.'
                ]);
            }

        } catch (Throwable $e) {
            error_log(
                'Complaint status notification failed: '
                . $e->getMessage()
            );
        }

        return $result;
    }

    /**
     * Get all complaints with filters and pagination.
     */
    public function getAllComplaints(
        array $filters = []
    ): array {

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
            $status = strtoupper(
                trim($filters['status'])
            );

            if (!in_array($status, $allowedStatuses, true)) {
                throw new InvalidArgumentException(
                    'Invalid complaint status filter.'
                );
            }

            $filters['status'] = $status;
        }

        $allowedPriorities = [
            'LOW',
            'MEDIUM',
            'HIGH',
            'URGENT'
        ];

        if (!empty($filters['priority'])) {
            $priority = strtoupper(
                trim($filters['priority'])
            );

            if (!in_array($priority, $allowedPriorities, true)) {
                throw new InvalidArgumentException(
                    'Invalid complaint priority filter.'
                );
            }

            $filters['priority'] = $priority;
        }

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

        if (
            $perPage === false ||
            $perPage < 1 ||
            $perPage > 100
        ) {
            throw new InvalidArgumentException(
                'Per page must be between 1 and 100.'
            );
        }

        $filters['page'] = $page;
        $filters['per_page'] = $perPage;

        return $this->complaintModel->findAll(
            $filters
        );
    }

    /**
     * Get complete complaint details for admin.
     */
    public function getAdminComplaintDetails(
        int $complaintId
    ): array {

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

        $images = $this->complaintModel->findImagesByComplaintId(
            $complaintId
        );

        return [
            'complaint' => $complaint,
            'images' => $images,
            'status_history' => $history,
            'priority_history' => $this->complaintModel->getPriorityHistory($complaintId),
        ];
    }

    public function getStaffComplaintDetails(int $complaintId, int $staffId): array
    {
        $complaint = $this->complaintModel->findStaffDetailsByAssignment($complaintId, $staffId);
        if (!$complaint) throw new InvalidArgumentException('Complaint not found in your current assignments.');
        return [
            'complaint' => $complaint,
            'images' => $this->complaintModel->findImagesByComplaintId($complaintId),
            'status_history' => $this->complaintModel->getStatusHistory($complaintId),
        ];
    }

    public function getAuthorizedImage(int $imageId, string $role, int $userId): array
    {
        if ($imageId <= 0) throw new InvalidArgumentException('Valid image ID is required.');
        $image = $this->complaintModel->findImageForViewer($imageId, $role, $userId);
        if (!$image) throw new InvalidArgumentException('Image not found.');
        $file = $this->imageUploadService->resolveStoredImage((string) $image['image_path']);
        if (!$file) throw new InvalidArgumentException('Image not found.');
        return $file;
    }

    public function updateAdminStatus(int $complaintId, int $adminId, string $status, ?string $remarks): array
    {
        $status = strtoupper(trim($status));
        if (!in_array($status, ['UNDER_REVIEW', 'REJECTED', 'CLOSED'], true)) throw new InvalidArgumentException('Invalid admin complaint status.');
        $remarks = $remarks === null ? null : trim($remarks);
        if ($status === 'REJECTED' && ($remarks === null || $remarks === '')) throw new InvalidArgumentException('Remarks are required when rejecting a complaint.');
        if ($remarks !== null && mb_strlen($remarks) > 2000) throw new InvalidArgumentException('Remarks must not exceed 2000 characters.');
        if ($complaintId <= 0 || $adminId <= 0) throw new InvalidArgumentException('Invalid complaint or administrator ID.');
        return $this->complaintModel->updateAdminStatus($complaintId, $adminId, $status, $remarks ?: null);
    }

    public function updateAdminPriority(int $complaintId, int $adminId, string $priority): array
    {
        $priority = strtoupper(trim($priority));
        if (!in_array($priority, ['LOW', 'MEDIUM', 'HIGH', 'URGENT'], true)) throw new InvalidArgumentException('Invalid complaint priority.');
        if ($complaintId <= 0 || $adminId <= 0) throw new InvalidArgumentException('Invalid complaint or administrator ID.');
        return $this->complaintModel->updatePriority($complaintId, $adminId, $priority);
    }
}
