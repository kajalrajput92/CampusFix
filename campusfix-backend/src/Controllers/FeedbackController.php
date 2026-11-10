<?php

namespace Campusfix\Backend\Controllers;

use Campusfix\Backend\Services\FeedbackService;
use Campusfix\Backend\Middleware\AuthMiddleware;
use InvalidArgumentException;
use RuntimeException;
use Throwable;

class FeedbackController
{
    private FeedbackService $feedbackService;

    public function __construct()
    {
        $this->feedbackService = new FeedbackService();
    }

    /**
     * Read and validate JSON request body.
     */
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
     * Handle authentication and authorization exceptions.
     */
    private function handleAuthException(RuntimeException $e): array
    {
        $statusCode = http_response_code();

        if (!in_array($statusCode, [401, 403], true)) {
            $statusCode = 500;
        }

        http_response_code($statusCode);

        return [
            'success' => false,
            'message' => $statusCode === 401
                ? 'Unauthorized. Invalid or missing token.'
                : (
                    $statusCode === 403
                        ? 'Forbidden. You do not have permission.'
                        : 'Internal server error.'
                )
        ];
    }

    /**
     * Student submits feedback for a resolved complaint.
     */
    public function submit(): array
    {
        try {
            $user = AuthMiddleware::authorize(['STUDENT']);
            $data = $this->getRequestData();

            $feedback = $this->feedbackService->submitFeedback(
                (int) $user->sub,
                $data
            );

            http_response_code(201);

            return [
                'success' => true,
                'message' => 'Feedback submitted successfully.',
                'data' => $feedback
            ];

        } catch (InvalidArgumentException $e) {
            http_response_code(422);

            return [
                'success' => false,
                'message' => $e->getMessage()
            ];

        } catch (RuntimeException $e) {
            return $this->handleAuthException($e);

        } catch (Throwable $e) {
            error_log($e->getMessage());
            http_response_code(500);

            return [
                'success' => false,
                'message' => 'Internal server error.'
            ];
        }
    }

    /**
     * Get feedback submitted by the authenticated student.
     */
    public function myFeedback(): array
    {
        try {
            $user = AuthMiddleware::authorize(['STUDENT']);

            $feedback = $this->feedbackService->getStudentFeedback(
                (int) $user->sub
            );

            return [
                'success' => true,
                'message' => 'Your feedback retrieved successfully.',
                'data' => $feedback
            ];

        } catch (RuntimeException $e) {
            return $this->handleAuthException($e);

        } catch (Throwable $e) {
            error_log($e->getMessage());
            http_response_code(500);

            return [
                'success' => false,
                'message' => 'Unable to retrieve feedback.'
            ];
        }
    }

    /**
     * Admin retrieves all feedback with filters and pagination.
     */
    public function index(): array
    {
        try {
            AuthMiddleware::authorize(['ADMIN']);

            $filters = [
                'rating' => $_GET['rating'] ?? '',
                'search' => $_GET['search'] ?? '',
                'page' => $_GET['page'] ?? 1,
                // Keep the old limit query parameter as a compatibility alias.
                'per_page' => $_GET['per_page'] ?? $_GET['limit'] ?? 10
            ];

            $result = $this->feedbackService->getAllFeedback(
                $filters
            );

            return [
                'success' => true,
                'message' => 'Feedback list retrieved successfully.',
                'data' => $result
            ];

        } catch (InvalidArgumentException $e) {
            http_response_code(422);

            return [
                'success' => false,
                'message' => $e->getMessage()
            ];

        } catch (RuntimeException $e) {
            return $this->handleAuthException($e);

        } catch (Throwable $e) {
            error_log($e->getMessage());
            http_response_code(500);

            return [
                'success' => false,
                'message' => 'Unable to retrieve feedback.'
            ];
        }
    }

    /**
     * Admin retrieves feedback details.
     */
    public function show(): array
    {
        try {
            AuthMiddleware::authorize(['ADMIN']);

            $feedbackId = filter_var(
                $_GET['feedback_id'] ?? null,
                FILTER_VALIDATE_INT
            );

            if ($feedbackId === false || $feedbackId <= 0) {
                throw new InvalidArgumentException(
                    'A valid feedback ID is required.'
                );
            }

            $feedback = $this->feedbackService->getFeedbackDetails(
                $feedbackId
            );

            return [
                'success' => true,
                'message' => 'Feedback details retrieved successfully.',
                'data' => $feedback
            ];

        } catch (InvalidArgumentException $e) {
            http_response_code(422);

            return [
                'success' => false,
                'message' => $e->getMessage()
            ];

        } catch (RuntimeException $e) {
            return $this->handleAuthException($e);

        } catch (Throwable $e) {
            error_log($e->getMessage());
            http_response_code(500);

            return [
                'success' => false,
                'message' => 'Unable to retrieve feedback details.'
            ];
        }
    }

    /**
     * Admin retrieves feedback statistics.
     */
    public function stats(): array
    {
        try {
            AuthMiddleware::authorize(['ADMIN']);

            $statistics = $this->feedbackService
                ->getFeedbackStatistics();

            return [
                'success' => true,
                'message' => 'Feedback statistics retrieved successfully.',
                'data' => $statistics
            ];

        } catch (RuntimeException $e) {
            return $this->handleAuthException($e);

        } catch (Throwable $e) {
            error_log($e->getMessage());
            http_response_code(500);

            return [
                'success' => false,
                'message' => 'Unable to retrieve feedback statistics.'
            ];
        }
    }
}
