<?php

namespace Campusfix\Backend\Controllers;

use Campusfix\Backend\Middleware\AuthMiddleware;
use Campusfix\Backend\Services\AssignmentService;
use InvalidArgumentException;
use Throwable;
use Campusfix\Backend\Services\StaffService;
use Campusfix\Backend\Config\Database;
use Campusfix\Backend\Services\AdminUserService;
use Campusfix\Backend\Services\ConflictException;
use PDOException;

class AdminController
{
    private AssignmentService $assignmentService;

    public function __construct()
    {
        $this->assignmentService = new AssignmentService();
    }

    /**
     * Assign complaint to staff.
     */
    public function assignComplaint(): array
    {
        try {
            // Only ADMIN can assign complaints.
            $admin = AuthMiddleware::authorize(['ADMIN']);

            $rawInput = file_get_contents('php://input');
            $data = json_decode($rawInput, true);

            if (!is_array($data)) {
                throw new InvalidArgumentException(
                    'A valid JSON request body is required.'
                );
            }

            $complaintId = filter_var(
                $data['complaint_id'] ?? null,
                FILTER_VALIDATE_INT
            );

            $staffId = filter_var(
                $data['staff_id'] ?? null,
                FILTER_VALIDATE_INT
            );

            if (
                $complaintId === false ||
                $complaintId === null ||
                $complaintId <= 0 ||
                $staffId === false ||
                $staffId === null ||
                $staffId <= 0
            ) {
                throw new InvalidArgumentException(
                    'Valid complaint ID and staff ID are required.'
                );
            }

            $result = $this->assignmentService->assign(
                $complaintId,
                $staffId,
                (int) $admin->sub
            );

            http_response_code(200);

            return [
                'success' => true,
                'message' => 'Complaint assigned successfully.',
                'data' => $result
            ];

        } catch (InvalidArgumentException $e) {
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
                'message' => 'Unable to assign complaint.'
            ];
        }
    }
    public function dashboardStats(): array
{
    try {
        $admin = AuthMiddleware::authorize(['ADMIN']);

        $db = \Campusfix\Backend\Config\Database::connect();

        $complaintStmt = $db->query("
            SELECT
                COUNT(*) AS total_complaints,
                SUM(status = 'SUBMITTED') AS submitted,
                SUM(status = 'UNDER_REVIEW') AS under_review,
                SUM(status = 'ASSIGNED') AS assigned,
                SUM(status = 'IN_PROGRESS') AS in_progress,
                SUM(status = 'RESOLVED') AS resolved,
                SUM(status = 'CLOSED') AS closed,
                SUM(status = 'REJECTED') AS rejected
            FROM complaints
        ");

        $complaints = $complaintStmt->fetch();

        $userStmt = $db->query("
            SELECT
                COUNT(*) AS total_users,
                SUM(role = 'STUDENT') AS students,
                SUM(role = 'STAFF') AS staff,
                SUM(role = 'ADMIN') AS admins
            FROM users
            WHERE is_active = 1
        ");

        $users = $userStmt->fetch();

        return [
            'success' => true,
            'message' => 'Dashboard statistics retrieved successfully.',
            'data' => [
                'complaints' => $complaints,
                'users' => $users
            ]
        ];

    } catch (Throwable $e) {
        error_log($e->getMessage());

        if (http_response_code() < 400) {
            http_response_code(500);
        }

        return [
            'success' => false,
            'message' => 'Unable to retrieve dashboard statistics.'
        ];
    }
}
public function allComplaints(): array
{
    try {
        AuthMiddleware::authorize(['ADMIN']);

        $filters = [
            'status' => $_GET['status'] ?? null,
            'priority' => $_GET['priority'] ?? null,
            'category' => $_GET['category'] ?? null,
            'search' => $_GET['search'] ?? null,
            'page' => $_GET['page'] ?? 1,
            'per_page' => $_GET['per_page'] ?? 10
        ];

        $service = new \Campusfix\Backend\Services\ComplaintService();

        $result = $service->getAllComplaints($filters);

        return [
            'success' => true,
            'message' => 'Complaints retrieved successfully.',
            'data' => $result['complaints'],
            'pagination' => $result['pagination']
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
            'message' => 'Unable to retrieve complaints.'
        ];
    }
}
public function complaintDetails(): array
{
    try {
        AuthMiddleware::authorize(['ADMIN']);

        $complaintId = filter_var(
            $_GET['id'] ?? null,
            FILTER_VALIDATE_INT
        );

        if ($complaintId === false || $complaintId === null || $complaintId <= 0) {
            throw new \InvalidArgumentException(
                'Valid complaint ID is required.'
            );
        }

        $service = new \Campusfix\Backend\Services\ComplaintService();

        $result = $service->getAdminComplaintDetails(
            $complaintId
        );

        return [
            'success' => true,
            'message' => 'Complaint details retrieved successfully.',
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
            'message' => 'Unable to retrieve complaint details.'
        ];
    }
}

    /**
     * Get all staff with filters and pagination.
     */
    public function staffList(): array
    {
        try {
            AuthMiddleware::authorize(['ADMIN']);

            $filters = [
                'search' => $_GET['search'] ?? '',
                'is_active' => $_GET['is_active'] ?? null,
                'page' => $_GET['page'] ?? 1,
                'per_page' => $_GET['per_page'] ?? 10
            ];

            $service = new StaffService();
            $result = $service->getAllStaff($filters);

            return [
                'success' => true,
                'message' => 'Staff members retrieved successfully.',
                'data' => $result['staff'],
                'pagination' => $result['pagination']
            ];

        } catch (InvalidArgumentException $e) {
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
                'message' => 'Unable to retrieve staff members.'
            ];
        }
    }

    /**
     * Get individual staff details.
     */
    public function staffDetails(): array
    {
        try {
            AuthMiddleware::authorize(['ADMIN']);

            $staffId = filter_var(
                $_GET['id'] ?? null,
                FILTER_VALIDATE_INT
            );

            if (
                $staffId === false ||
                $staffId === null ||
                $staffId <= 0
            ) {
                throw new InvalidArgumentException(
                    'Valid staff ID is required.'
                );
            }

            $service = new StaffService();
            $result = $service->getStaffDetails($staffId);

            return [
                'success' => true,
                'message' => 'Staff details retrieved successfully.',
                'data' => $result
            ];

        } catch (InvalidArgumentException $e) {
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
                'message' => 'Unable to retrieve staff details.'
            ];
        }
    }

    /**
     * Activate or deactivate a staff account.
     */
    public function updateStaffStatus(): array
    {
        try {
            AuthMiddleware::authorize(['ADMIN']);

            $rawInput = file_get_contents('php://input');
            $data = json_decode($rawInput, true);

            if (!is_array($data)) {
                throw new InvalidArgumentException(
                    'A valid JSON request body is required.'
                );
            }

            $staffId = filter_var(
                $data['staff_id'] ?? null,
                FILTER_VALIDATE_INT
            );

            if (
                $staffId === false ||
                $staffId === null ||
                $staffId <= 0
            ) {
                throw new InvalidArgumentException(
                    'Valid staff ID is required.'
                );
            }

            if (!array_key_exists('is_active', $data)) {
                throw new InvalidArgumentException(
                    'is_active field is required.'
                );
            }

            $service = new StaffService();

            $result = $service->changeStaffStatus(
                $staffId,
                $data['is_active']
            );

            return [
                'success' => true,
                'message' => 'Staff status updated successfully.',
                'data' => $result
            ];

        } catch (InvalidArgumentException $e) {
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
                'message' => 'Unable to update staff status.'
            ];
        }
    }

    public function students(): array
    {
        try {
            AuthMiddleware::authorize(['ADMIN']);
            $result = (new AdminUserService())->students($_GET);
            return ['success' => true, 'message' => 'Students retrieved successfully.', 'data' => $result['students'], 'pagination' => $result['pagination']];
        } catch (InvalidArgumentException $e) {
            http_response_code(422);
            return ['success' => false, 'message' => $e->getMessage()];
        } catch (Throwable $e) {
            error_log($e->getMessage());
            if (http_response_code() < 400) http_response_code(500);
            return ['success' => false, 'message' => 'Unable to retrieve students.'];
        }
    }

    public function studentDetails(): array
    {
        try {
            AuthMiddleware::authorize(['ADMIN']);
            $id = filter_var($_GET['id'] ?? null, FILTER_VALIDATE_INT);
            if ($id === false || $id === null || $id <= 0) {
                http_response_code(422);
                return ['success' => false, 'message' => 'Valid student ID is required.'];
            }
            return ['success' => true, 'message' => 'Student details retrieved successfully.', 'data' => (new AdminUserService())->student($id)];
        } catch (InvalidArgumentException $e) {
            http_response_code(404);
            return ['success' => false, 'message' => $e->getMessage()];
        } catch (Throwable $e) {
            error_log($e->getMessage());
            if (http_response_code() < 400) http_response_code(500);
            return ['success' => false, 'message' => 'Unable to retrieve student details.'];
        }
    }

    public function studentComplaints(): array
    {
        try {
            AuthMiddleware::authorize(['ADMIN']);
            $id = filter_var($_GET['student_id'] ?? null, FILTER_VALIDATE_INT);
            if ($id === false || $id === null || $id <= 0) {
                http_response_code(422);
                return ['success' => false, 'message' => 'Valid student_id is required.'];
            }
            $result = (new AdminUserService())->studentComplaints($id, $_GET);
            return ['success' => true, 'message' => 'Student complaints retrieved successfully.', 'data' => $result['complaints'], 'pagination' => $result['pagination']];
        } catch (InvalidArgumentException $e) {
            http_response_code(404);
            return ['success' => false, 'message' => $e->getMessage()];
        } catch (Throwable $e) {
            error_log($e->getMessage());
            if (http_response_code() < 400) http_response_code(500);
            return ['success' => false, 'message' => 'Unable to retrieve student complaints.'];
        }
    }

    public function updateStudentStatus(): array
    {
        try {
            AuthMiddleware::authorize(['ADMIN']);
            $data = json_decode(file_get_contents('php://input'), true);
            if (!is_array($data)) throw new InvalidArgumentException('A valid JSON request body is required.');
            $id = filter_var($data['student_id'] ?? null, FILTER_VALIDATE_INT);
            if ($id === false || $id === null || $id <= 0 || !array_key_exists('is_active', $data)) throw new InvalidArgumentException('Valid student_id and is_active are required.');
            $student = (new AdminUserService())->changeStudentStatus($id, $data['is_active']);
            return ['success' => true, 'message' => 'Student status updated successfully. Existing sessions were revoked.', 'data' => $student];
        } catch (InvalidArgumentException $e) {
            http_response_code(422);
            return ['success' => false, 'message' => $e->getMessage()];
        } catch (Throwable $e) {
            error_log($e->getMessage());
            if (http_response_code() < 400) http_response_code(500);
            return ['success' => false, 'message' => 'Unable to update student status.'];
        }
    }

    public function createStaff(): array
    {
        try {
            AuthMiddleware::authorize(['ADMIN']);
            $data = json_decode(file_get_contents('php://input'), true);
            if (!is_array($data)) throw new InvalidArgumentException('A valid JSON request body is required.');
            $staff = (new AdminUserService())->createStaff($data);
            http_response_code(201);
            return ['success' => true, 'message' => 'Staff account created successfully.', 'data' => $staff];
        } catch (ConflictException|PDOException $e) {
            http_response_code(409);
            return ['success' => false, 'message' => $e instanceof ConflictException ? $e->getMessage() : 'Email or employee ID already exists.'];
        } catch (InvalidArgumentException $e) {
            http_response_code(422);
            return ['success' => false, 'message' => $e->getMessage()];
        } catch (Throwable $e) {
            error_log($e->getMessage());
            if (http_response_code() < 400) http_response_code(500);
            return ['success' => false, 'message' => 'Unable to create staff account.'];
        }
    }

    public function updateStaff(): array
    {
        try {
            AuthMiddleware::authorize(['ADMIN']);
            $data = json_decode(file_get_contents('php://input'), true);
            if (!is_array($data)) throw new InvalidArgumentException('A valid JSON request body is required.');
            $id = filter_var($data['staff_id'] ?? null, FILTER_VALIDATE_INT);
            if ($id === false || $id === null || $id <= 0) throw new InvalidArgumentException('Valid staff_id is required.');
            $staff = (new AdminUserService())->updateStaff($id, $data);
            return ['success' => true, 'message' => 'Staff account updated successfully. Existing sessions were revoked.', 'data' => $staff];
        } catch (ConflictException|PDOException $e) {
            http_response_code(409);
            return ['success' => false, 'message' => $e instanceof ConflictException ? $e->getMessage() : 'Email or employee ID already exists.'];
        } catch (InvalidArgumentException $e) {
            http_response_code(422);
            return ['success' => false, 'message' => $e->getMessage()];
        } catch (Throwable $e) {
            error_log($e->getMessage());
            if (http_response_code() < 400) http_response_code(500);
            return ['success' => false, 'message' => 'Unable to update staff account.'];
        }
    }

    public function updateComplaintStatus(): array
    {
        try {
            $admin = AuthMiddleware::authorize(['ADMIN']);
            $data = json_decode(file_get_contents('php://input'), true);
            if (!is_array($data)) throw new InvalidArgumentException('A valid JSON request body is required.');
            $id = filter_var($data['complaint_id'] ?? null, FILTER_VALIDATE_INT);
            if ($id === false || $id === null || $id <= 0) throw new InvalidArgumentException('Valid complaint_id is required.');
            $result = (new \Campusfix\Backend\Services\ComplaintService())->updateAdminStatus($id, (int) $admin->sub, (string) ($data['status'] ?? ''), isset($data['remarks']) ? (string) $data['remarks'] : null);
            return ['success' => true, 'message' => 'Complaint status updated successfully.', 'data' => $result];
        } catch (ConflictException $e) {
            http_response_code(409);
            return ['success' => false, 'message' => $e->getMessage()];
        } catch (InvalidArgumentException $e) {
            http_response_code($e->getMessage() === 'Complaint not found.' ? 404 : 422);
            return ['success' => false, 'message' => $e->getMessage()];
        } catch (Throwable $e) {
            error_log($e->getMessage());
            if (http_response_code() < 400) http_response_code(500);
            return ['success' => false, 'message' => 'Unable to update complaint status.'];
        }
    }

    public function updateComplaintPriority(): array
    {
        try {
            $admin = AuthMiddleware::authorize(['ADMIN']);
            $data = json_decode(file_get_contents('php://input'), true);
            if (!is_array($data)) throw new InvalidArgumentException('A valid JSON request body is required.');
            $id = filter_var($data['complaint_id'] ?? null, FILTER_VALIDATE_INT);
            if ($id === false || $id === null || $id <= 0) throw new InvalidArgumentException('Valid complaint_id is required.');
            $result = (new \Campusfix\Backend\Services\ComplaintService())->updateAdminPriority($id, (int) $admin->sub, (string) ($data['priority'] ?? ''));
            return ['success' => true, 'message' => 'Complaint priority updated successfully.', 'data' => $result];
        } catch (ConflictException $e) {
            http_response_code(409);
            return ['success' => false, 'message' => $e->getMessage()];
        } catch (InvalidArgumentException $e) {
            http_response_code($e->getMessage() === 'Complaint not found.' ? 404 : 422);
            return ['success' => false, 'message' => $e->getMessage()];
        } catch (Throwable $e) {
            error_log($e->getMessage());
            if (http_response_code() < 400) http_response_code(500);
            return ['success' => false, 'message' => 'Unable to update complaint priority.'];
        }
    }

}
