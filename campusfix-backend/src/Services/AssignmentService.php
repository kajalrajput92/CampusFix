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

    public function __construct()
    {
        $this->db = Database::connect();
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
                SELECT complaint_id, status
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