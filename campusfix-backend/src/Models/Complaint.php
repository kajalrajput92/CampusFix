<?php

namespace Campusfix\Backend\Models;

use Campusfix\Backend\Config\Database;
use PDO;
use InvalidArgumentException;
use Throwable;

class Complaint
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::connect();
    }

    /**
     * Create a new complaint and save its images
     * within the same database transaction.
     */
    public function create(array $data, array $imagePaths = []): int
    {
        $this->db->beginTransaction();

        try {
            // Temporary unique complaint number
            $temporaryNumber = 'CF-TMP-' . bin2hex(random_bytes(8));

            $sql = "
                INSERT INTO complaints (
                    complaint_number,
                    student_id,
                    location_id,
                    department_id,
                    title,
                    description,
                    category,
                    priority,
                    status
                ) VALUES (
                    :complaint_number,
                    :student_id,
                    :location_id,
                    :department_id,
                    :title,
                    :description,
                    :category,
                    :priority,
                    'SUBMITTED'
                )
            ";

            $stmt = $this->db->prepare($sql);

            $stmt->execute([
                'complaint_number' => $temporaryNumber,
                'student_id' => $data['student_id'],
                'location_id' => $data['location_id'],
                'department_id' => $data['department_id'],
                'title' => $data['title'],
                'description' => $data['description'],
                'category' => $data['category'],
                'priority' => $data['priority']
            ]);

            $complaintId = (int) $this->db->lastInsertId();

            // Generate final tracking number
            $complaintNumber = sprintf(
                'CF-%06d',
                $complaintId
            );

            $update = $this->db->prepare("
                UPDATE complaints
                SET complaint_number = :complaint_number
                WHERE complaint_id = :complaint_id
            ");

            $update->execute([
                'complaint_number' => $complaintNumber,
                'complaint_id' => $complaintId
            ]);

            // Record initial complaint status
            $history = $this->db->prepare("
                INSERT INTO complaint_status_history (
                    complaint_id,
                    changed_by,
                    old_status,
                    new_status,
                    remarks
                ) VALUES (
                    :complaint_id,
                    :changed_by,
                    NULL,
                    'SUBMITTED',
                    'Complaint submitted by student.'
                )
            ");

            $history->execute([
                'complaint_id' => $complaintId,
                'changed_by' => $data['student_id']
            ]);

            // Save image paths in the same transaction
            if (!empty($imagePaths)) {
                $imageStmt = $this->db->prepare("
                    INSERT INTO complaint_images (
                        complaint_id,
                        image_path
                    ) VALUES (
                        :complaint_id,
                        :image_path
                    )
                ");

                foreach ($imagePaths as $imagePath) {
                    $imageStmt->execute([
                        'complaint_id' => $complaintId,
                        'image_path' => $imagePath
                    ]);
                }
            }

            $this->db->commit();

            return $complaintId;

        } catch (Throwable $e) {

            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }

            throw $e;
        }
    }

    /**
     * Find complaint by ID.
     */
    public function findById(int $complaintId): array|false
    {
        $sql = "
            SELECT *
            FROM complaints
            WHERE complaint_id = :complaint_id
            LIMIT 1
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            'complaint_id' => $complaintId
        ]);

        return $stmt->fetch();
    }

    /**
     * Get complaints submitted by a student.
     */
    public function findByStudent(int $studentId): array
    {
        $sql = "
            SELECT
                complaint_id,
                complaint_number,
                title,
                category,
                priority,
                status,
                created_at,
                due_at
            FROM complaints
            WHERE student_id = :student_id
            ORDER BY created_at DESC
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            'student_id' => $studentId
        ]);

        return $stmt->fetchAll();
    }

    /**
     * Get complaint details with location.
     */
    public function findDetailsById(
        int $complaintId,
        int $studentId
    ): array|false {

        $sql = "
            SELECT
                c.complaint_id,
                c.complaint_number,
                c.title,
                c.description,
                c.category,
                c.priority,
                c.status,
                c.resolution_notes,
                c.created_at,
                c.updated_at,
                c.resolved_at,
                c.closed_at,
                c.due_at,
                l.building_name,
                l.block_name,
                l.floor_number,
                l.room_number
            FROM complaints c
            INNER JOIN locations l
                ON c.location_id = l.location_id
            WHERE c.complaint_id = :complaint_id
              AND c.student_id = :student_id
            LIMIT 1
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            'complaint_id' => $complaintId,
            'student_id' => $studentId
        ]);

        return $stmt->fetch();
    }

    /**
     * Get complete complaint details for admin.
     */
    public function findAdminDetailsById(
        int $complaintId
    ): array|false {

        $sql = "
            SELECT
                c.complaint_id,
                c.complaint_number,
                c.title,
                c.description,
                c.category,
                c.priority,
                c.status,
                c.resolution_notes,
                c.created_at,
                c.updated_at,
                c.resolved_at,
                c.closed_at,
                c.due_at,

                u.user_id AS student_id,
                u.full_name AS student_name,
                u.email AS student_email,
                u.phone AS student_phone,

                l.building_name,
                l.block_name,
                l.floor_number,
                l.room_number,
                l.description AS location_description,

                (
                    SELECT assigned_user.user_id
                    FROM complaint_assignments ca
                    INNER JOIN users assigned_user
                        ON ca.staff_id = assigned_user.user_id
                    WHERE ca.complaint_id = c.complaint_id
                    ORDER BY ca.assignment_id DESC
                    LIMIT 1
                ) AS staff_id,

                (
                    SELECT assigned_user.full_name
                    FROM complaint_assignments ca
                    INNER JOIN users assigned_user
                        ON ca.staff_id = assigned_user.user_id
                    WHERE ca.complaint_id = c.complaint_id
                    ORDER BY ca.assignment_id DESC
                    LIMIT 1
                ) AS staff_name,

                (
                    SELECT assigned_user.email
                    FROM complaint_assignments ca
                    INNER JOIN users assigned_user
                        ON ca.staff_id = assigned_user.user_id
                    WHERE ca.complaint_id = c.complaint_id
                    ORDER BY ca.assignment_id DESC
                    LIMIT 1
                ) AS staff_email

            FROM complaints c

            INNER JOIN users u
                ON c.student_id = u.user_id

            LEFT JOIN locations l
                ON c.location_id = l.location_id

            WHERE c.complaint_id = :complaint_id
            LIMIT 1
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            'complaint_id' => $complaintId
        ]);

        return $stmt->fetch();
    }

    /**
     * Get complaint status history.
     */
    public function getStatusHistory(int $complaintId): array
    {
        $sql = "
            SELECT
                old_status,
                new_status,
                remarks,
                changed_at
            FROM complaint_status_history
            WHERE complaint_id = :complaint_id
            ORDER BY changed_at ASC, history_id ASC
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            'complaint_id' => $complaintId
        ]);

        return $stmt->fetchAll();
    }

    /**
     * Retrieve images belonging to a complaint.
     */
    public function findImagesByComplaintId(
        int $complaintId
    ): array {

        $sql = "
            SELECT
                image_id,
                image_path,
                uploaded_at
            FROM complaint_images
            WHERE complaint_id = :complaint_id
            ORDER BY image_id ASC
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            'complaint_id' => $complaintId
        ]);

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Update complaint status by assigned staff.
     */
    public function updateStatus(
        int $complaintId,
        int $staffId,
        string $newStatus,
        ?string $resolutionNotes = null
    ): array {

        try {
            $this->db->beginTransaction();

            // Verify current assignment belongs to this staff member.
            $assignmentStmt = $this->db->prepare("
                SELECT assignment_id
                FROM complaint_assignments
                WHERE complaint_id = :complaint_id
                ORDER BY assignment_id DESC
                LIMIT 1
                FOR UPDATE
            ");

            $assignmentStmt->execute([
                'complaint_id' => $complaintId
            ]);

            $assignment = $assignmentStmt->fetch();

            if (!$assignment) {
                throw new InvalidArgumentException(
                    'Complaint is not assigned.'
                );
            }

            $staffStmt = $this->db->prepare("
                SELECT staff_id
                FROM complaint_assignments
                WHERE assignment_id = :assignment_id
                  AND staff_id = :staff_id
            ");

            $staffStmt->execute([
                'assignment_id' => $assignment['assignment_id'],
                'staff_id' => $staffId
            ]);

            if (!$staffStmt->fetch()) {
                throw new InvalidArgumentException(
                    'This complaint is not assigned to you.'
                );
            }

            $complaintStmt = $this->db->prepare("
                SELECT status
                FROM complaints
                WHERE complaint_id = :id
                FOR UPDATE
            ");

            $complaintStmt->execute([
                'id' => $complaintId
            ]);

            $complaint = $complaintStmt->fetch();

            if (!$complaint) {
                throw new InvalidArgumentException(
                    'Complaint not found.'
                );
            }

            $oldStatus = $complaint['status'];

            $allowedTransitions = [
                'ASSIGNED' => ['IN_PROGRESS'],
                'IN_PROGRESS' => ['RESOLVED']
            ];

            if (
                !isset($allowedTransitions[$oldStatus]) ||
                !in_array(
                    $newStatus,
                    $allowedTransitions[$oldStatus],
                    true
                )
            ) {
                throw new InvalidArgumentException(
                    'Invalid complaint status transition.'
                );
            }

            if (
                $newStatus === 'RESOLVED' &&
                trim((string) $resolutionNotes) === ''
            ) {
                throw new InvalidArgumentException(
                    'Resolution notes are required.'
                );
            }

            $updateStmt = $this->db->prepare("
                UPDATE complaints
                SET
                    status = :status,
                    resolution_notes = :notes,
                    resolved_at = CASE
                        WHEN :resolved_status = 'RESOLVED'
                        THEN CURRENT_TIMESTAMP
                        ELSE resolved_at
                    END
                WHERE complaint_id = :id
            ");

            $updateStmt->execute([
                'status' => $newStatus,
                'notes' => $newStatus === 'RESOLVED'
                    ? $resolutionNotes
                    : null,
                'resolved_status' => $newStatus,
                'id' => $complaintId
            ]);

            $historyStmt = $this->db->prepare("
                INSERT INTO complaint_status_history
                (
                    complaint_id,
                    changed_by,
                    old_status,
                    new_status,
                    remarks
                )
                VALUES (
                    :complaint_id,
                    :staff_id,
                    :old_status,
                    :new_status,
                    :remarks
                )
            ");

            $historyStmt->execute([
                'complaint_id' => $complaintId,
                'staff_id' => $staffId,
                'old_status' => $oldStatus,
                'new_status' => $newStatus,
                'remarks' => $resolutionNotes
            ]);

            $this->db->commit();

            return [
                'complaint_id' => $complaintId,
                'old_status' => $oldStatus,
                'new_status' => $newStatus
            ];

        } catch (Throwable $e) {

            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }

            throw $e;
        }
    }

    /**
     * Get all complaints with filters and pagination.
     */
    public function findAll(array $filters = []): array
    {
        $conditions = [];
        $params = [];

        // Status filter
        if (!empty($filters['status'])) {
            $conditions[] = 'c.status = :status';
            $params['status'] = strtoupper(
                trim($filters['status'])
            );
        }

        // Priority filter
        if (!empty($filters['priority'])) {
            $conditions[] = 'c.priority = :priority';
            $params['priority'] = strtoupper(
                trim($filters['priority'])
            );
        }

        // Category filter
        if (!empty($filters['category'])) {
            $conditions[] = 'c.category = :category';
            $params['category'] = trim(
                $filters['category']
            );
        }

        // Search filter
        if (!empty($filters['search'])) {
            $conditions[] = '(
                c.complaint_number LIKE :search_number
                OR c.title LIKE :search_title
                OR u.full_name LIKE :search_student
            )';

            $search = '%' . trim($filters['search']) . '%';

            $params['search_number'] = $search;
            $params['search_title'] = $search;
            $params['search_student'] = $search;
        }

        $whereSql = '';

        if (!empty($conditions)) {
            $whereSql = ' WHERE ' . implode(
                ' AND ',
                $conditions
            );
        }

        // Pagination
        $page = max(
            1,
            (int) ($filters['page'] ?? 1)
        );

        $perPage = min(
            100,
            max(1, (int) ($filters['per_page'] ?? 10))
        );

        $offset = ($page - 1) * $perPage;

        // Total matching complaints
        $countSql = "
            SELECT COUNT(*)
            FROM complaints c
            INNER JOIN users u
                ON c.student_id = u.user_id
            $whereSql
        ";

        $countStmt = $this->db->prepare($countSql);
        $countStmt->execute($params);

        $total = (int) $countStmt->fetchColumn();

        // Fetch complaints
        $sql = "
            SELECT
                c.complaint_id,
                c.complaint_number,
                c.title,
                c.category,
                c.priority,
                c.status,
                c.created_at,
                c.due_at,
                c.resolved_at,
                u.full_name AS student_name,
                u.email AS student_email,
                l.building_name,
                l.block_name,
                l.floor_number,
                l.room_number
            FROM complaints c
            INNER JOIN users u
                ON c.student_id = u.user_id
            LEFT JOIN locations l
                ON c.location_id = l.location_id
            $whereSql
            ORDER BY c.created_at DESC, c.complaint_id DESC
            LIMIT :limit OFFSET :offset
        ";

        $stmt = $this->db->prepare($sql);

        foreach ($params as $key => $value) {
            $stmt->bindValue(
                ':' . $key,
                $value,
                PDO::PARAM_STR
            );
        }

        $stmt->bindValue(
            ':limit',
            $perPage,
            PDO::PARAM_INT
        );

        $stmt->bindValue(
            ':offset',
            $offset,
            PDO::PARAM_INT
        );

        $stmt->execute();

        return [
            'complaints' => $stmt->fetchAll(),
            'pagination' => [
                'total' => $total,
                'page' => $page,
                'per_page' => $perPage,
                'total_pages' => (int) ceil(
                    $total / $perPage
                )
            ]
        ];
    }
}
