<?php

namespace Campusfix\Backend\Controllers;

use Campusfix\Backend\Config\Database;
use Campusfix\Backend\Middleware\AuthMiddleware;
use Throwable;

class StaffController
{
    public function complaintDetails(): array
    {
        try {
            $staff = AuthMiddleware::authorize(['STAFF']);
            $id = filter_var($_GET['id'] ?? null, FILTER_VALIDATE_INT);
            if ($id === false || $id === null || $id <= 0) {
                http_response_code(422);
                return ['success' => false, 'message' => 'Valid complaint ID is required.'];
            }
            $result = (new \Campusfix\Backend\Services\ComplaintService())->getStaffComplaintDetails($id, (int) $staff->sub);
            return ['success' => true, 'message' => 'Assigned complaint details retrieved successfully.', 'data' => $result];
        } catch (\InvalidArgumentException $e) {
            http_response_code(404);
            return ['success' => false, 'message' => $e->getMessage()];
        } catch (Throwable $e) {
            error_log($e->getMessage());
            if (http_response_code() < 400) http_response_code(500);
            return ['success' => false, 'message' => 'Unable to retrieve assigned complaint details.'];
        }
    }

    /**
     * Get complaints assigned to authenticated staff.
     */
    public function myAssignments(): array
    {
        try {
            $staff = AuthMiddleware::authorize(['STAFF']);

            $db = Database::connect();

            $sql = "
                SELECT
                    c.complaint_id,
                    c.complaint_number,
                    c.title,
                    c.description,
                    c.category,
                    c.priority,
                    c.status,
                    c.created_at,
                    ca.assigned_at
                FROM complaint_assignments ca
                INNER JOIN complaints c
                    ON ca.complaint_id = c.complaint_id
                WHERE ca.staff_id = :staff_id
                  AND ca.assignment_id = (
                      SELECT MAX(ca2.assignment_id)
                      FROM complaint_assignments ca2
                      WHERE ca2.complaint_id = c.complaint_id
                  )
                ORDER BY ca.assigned_at DESC
            ";

            $stmt = $db->prepare($sql);

            $stmt->execute([
                'staff_id' => (int) $staff->sub
            ]);

            return [
                'success' => true,
                'message' => 'Assigned complaints retrieved successfully.',
                'data' => $stmt->fetchAll()
            ];

        } catch (Throwable $e) {
            error_log($e->getMessage());

            if (http_response_code() < 400) {
                http_response_code(500);
            }

            return [
                'success' => false,
                'message' => 'Unable to retrieve assigned complaints.'
            ];
        }
    }

    public function updateComplaintStatus(): array
{
    try {
        $staff = AuthMiddleware::authorize(['STAFF']);

        $data = json_decode(
            file_get_contents('php://input'),
            true
        );

        if (!is_array($data)) {
            throw new \InvalidArgumentException(
                'Invalid JSON request body.'
            );
        }

        $complaintId = (int) ($data['complaint_id'] ?? 0);
        $status = strtoupper(trim($data['status'] ?? ''));
        $resolutionNotes = $data['resolution_notes'] ?? null;

        if ($complaintId <= 0) {
            throw new \InvalidArgumentException(
                'Valid complaint ID is required.'
            );
        }

        $service = new \Campusfix\Backend\Services\ComplaintService();

        $result = $service->updateComplaintStatus(
            $complaintId,
            (int) $staff->sub,
            $status,
            $resolutionNotes
        );

        return [
            'success' => true,
            'message' => 'Complaint status updated successfully.',
            'data' => $result
        ];

    } catch (\InvalidArgumentException $e) {
        http_response_code(422);

        return [
            'success' => false,
            'message' => $e->getMessage()
        ];

    } catch (Throwable $e) {
        error_log($e->getMessage());

        if (http_response_code() < 400) {
            http_response_code(500);
        }

        return [
            'success' => false,
            'message' => 'Unable to update complaint status.'
        ];
    }
}
}
