<?php

namespace Campusfix\Backend\Controllers;

use Campusfix\Backend\Middleware\AuthMiddleware;
use Campusfix\Backend\Services\ComplaintService;
use InvalidArgumentException;
use Throwable;

class ComplaintController
{
    private ComplaintService $complaintService;

    public function __construct()
    {
        $this->complaintService = new ComplaintService();
    }

    private function getRequestData(): array
    {
        $rawInput = file_get_contents('php://input');
        $data = json_decode($rawInput, true);

        if (!is_array($data)) {
            throw new InvalidArgumentException(
                'A valid JSON request body is required.'
            );
        }

        return $data;
    }

    /**
     * Submit a complaint.
     */
    public function submit(): array
    {
        try {
            $user = AuthMiddleware::authorize(['STUDENT']);

            $data = $this->getRequestData();

            $complaint = $this->complaintService->submit(
                (int) $user->sub,
                $data
            );

            http_response_code(201);

            return [
                'success' => true,
                'message' => 'Complaint submitted successfully.',
                'data' => $complaint
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
                'message' => 'Unable to submit complaint.'
            ];
        }
    }

    /**
     * Get complaints of the authenticated student.
     */
    public function myComplaints(): array
    {
        try {
            $user = AuthMiddleware::authorize(['STUDENT']);

            $complaints = $this->complaintService
                ->getStudentComplaints((int) $user->sub);

            return [
                'success' => true,
                'message' => 'Complaints retrieved successfully.',
                'data' => $complaints
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

    /**
 * Get a single complaint with its status history.
 */
public function show(): array
{
    try {
        $user = AuthMiddleware::authorize(['STUDENT']);

        $complaintId = filter_var(
            $_GET['id'] ?? null,
            FILTER_VALIDATE_INT
        );

        if ($complaintId === false || $complaintId === null || $complaintId <= 0) {
            http_response_code(422);

            return [
                'success' => false,
                'message' => 'A valid complaint ID is required.'
            ];
        }

        $result = $this->complaintService->getComplaintDetails(
            $complaintId,
            (int) $user->sub
        );

        return [
            'success' => true,
            'message' => 'Complaint details retrieved successfully.',
            'data' => $result
        ];

    } catch (InvalidArgumentException $e) {
        http_response_code(404);

        return [
            'success' => false,
            'message' => $e->getMessage()
        ];

    } catch (Throwable $e) {
        error_log($e->getMessage());

        http_response_code(500);

        return [
            'success' => false,
            'message' => 'Unable to retrieve complaint details.'
        ];
    }
}
}