<?php

namespace Campusfix\Backend\Services;

use Campusfix\Backend\Config\Database;
use PDO;
use InvalidArgumentException;
use RuntimeException;
use Throwable;

class AssignmentService
{
    private PDO $db;
    private NotificationService $notificationService;

    public function __construct()
{
    $this->db = Database::connect();
    $this->notificationService = new NotificationService();
}

    /**
     * Assign a complaint to a staff member.
     */
    public function assign(
        int $complaintId,
        int $staffId,
        int $adminId
    ): array {

        try {
            $this->db->beginTransaction();

            // Lock and verify complaint.
            $complaintStmt = $this->db->prepare("
               SELECT
    complaint_id,
    student_id,
    complaint_number,
    title,
    status
FROM complaints
WHERE complaint_id = :id
FOR UPDATE
            ");

            $complaintStmt->execute(['id' => $complaintId]);

            $complaint = $complaintStmt->fetch();

            if (!$complaint) {
                throw new InvalidArgumentException(
                    'Complaint not found.'
                );
            }

            if (in_array(
                $complaint['status'],
                ['RESOLVED', 'CLOSED', 'REJECTED'],
                true
            )) {
                throw new InvalidArgumentException(
                    'This complaint cannot be assigned.'
                );
            }

            // Verify staff account.
            $staffStmt = $this->db->prepare("
                SELECT user_id
                FROM users
                WHERE user_id = :id
                  AND role = 'STAFF'
                  AND is_active = TRUE
            ");

            $staffStmt->execute(['id' => $staffId]);

            if (!$staffStmt->fetch()) {
                throw new InvalidArgumentException(
                    'Active staff member not found.'
                );
            }

            // Verify admin account.
            $adminStmt = $this->db->prepare("
                SELECT user_id
                FROM users
                WHERE user_id = :id
                  AND role = 'ADMIN'
                  AND is_active = TRUE
            ");

            $adminStmt->execute(['id' => $adminId]);

            if (!$adminStmt->fetch()) {
                throw new InvalidArgumentException(
                    'Active admin account not found.'
                );
            }

            // Create assignment record.
            $assignmentStmt = $this->db->prepare("
                INSERT INTO complaint_assignments (
                    complaint_id,
                    staff_id,
                    assigned_by
                ) VALUES (
                    :complaint_id,
                    :staff_id,
                    :admin_id
                )
            ");

            $assignmentStmt->execute([
                'complaint_id' => $complaintId,
                'staff_id' => $staffId,
                'admin_id' => $adminId
            ]);

            $oldStatus = $complaint['status'];

            // Update complaint status.
            $updateStmt = $this->db->prepare("
                UPDATE complaints
                SET status = 'ASSIGNED'
                WHERE complaint_id = :id
            ");

            $updateStmt->execute(['id' => $complaintId]);

            // Record status history.
            $historyStmt = $this->db->prepare("
                INSERT INTO complaint_status_history (
                    complaint_id,
                    changed_by,
                    old_status,
                    new_status,
                    remarks
                ) VALUES (
                    :complaint_id,
                    :admin_id,
                    :old_status,
                    'ASSIGNED',
                    'Complaint assigned to staff.'
                )
            ");

            $historyStmt->execute([
                'complaint_id' => $complaintId,
                'admin_id' => $adminId,
                'old_status' => $oldStatus
            ]);

            $this->db->commit();
            // Notify the student about staff assignment.
try {
    $this->notificationService->createNotification([
        'user_id' => (int) $complaint['student_id'],
        'complaint_id' => $complaintId,
        'type' => 'COMPLAINT_ASSIGNED',
        'title' => 'Complaint Assigned',
        'message' => 'Your complaint '
            . $complaint['complaint_number']
            . ' has been assigned to a staff member.'
    ]);
} catch (Throwable $e) {
    error_log(
        'Student assignment notification failed: '
        . $e->getMessage()
    );
}

// Notify the assigned staff member.
try {
    $this->notificationService->createNotification([
        'user_id' => $staffId,
        'complaint_id' => $complaintId,
        'type' => 'NEW_ASSIGNMENT',
        'title' => 'New Complaint Assigned',
        'message' => 'Complaint '
            . $complaint['complaint_number']
            . ' - '
            . $complaint['title']
            . ' has been assigned to you.'
    ]);
} catch (Throwable $e) {
    error_log(
        'Staff assignment notification failed: '
        . $e->getMessage()
    );
}

            return [
                'complaint_id' => $complaintId,
                'staff_id' => $staffId,
                'status' => 'ASSIGNED'
            ];

        } catch (Throwable $e) {

            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }

            throw $e;
        }
    }
}