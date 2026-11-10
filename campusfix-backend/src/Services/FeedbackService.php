<?php

namespace Campusfix\Backend\Services;

use Campusfix\Backend\Models\Feedback;
use InvalidArgumentException;
use PDOException;

class FeedbackService
{
    private Feedback $feedbackModel;

    public function __construct()
    {
        $this->feedbackModel = new Feedback();
    }

    /**
     * Submit feedback for a resolved complaint.
     */
    public function submitFeedback(
        int $studentId,
        array $data
    ): array {

        $complaintId = filter_var(
            $data['complaint_id'] ?? null,
            FILTER_VALIDATE_INT
        );

        if ($complaintId === false || $complaintId <= 0) {
            throw new InvalidArgumentException(
                'A valid complaint ID is required.'
            );
        }

        $rating = filter_var(
            $data['rating'] ?? null,
            FILTER_VALIDATE_INT
        );

        if (
            $rating === false ||
            $rating < 1 ||
            $rating > 5
        ) {
            throw new InvalidArgumentException(
                'Rating must be between 1 and 5.'
            );
        }

        $comments = isset($data['comments'])
            ? trim((string) $data['comments'])
            : null;

        if ($comments === '') {
            $comments = null;
        }

        if (
            $comments !== null &&
            mb_strlen($comments, 'UTF-8') > 2000
        ) {
            throw new InvalidArgumentException(
                'Feedback comments must not exceed 2000 characters.'
            );
        }

        $complaint = $this->feedbackModel->findEligibleComplaint(
            $complaintId,
            $studentId
        );

        if (!$complaint) {
            throw new InvalidArgumentException(
                'Complaint not found, does not belong to you, or is not resolved.'
            );
        }

        if (
            $this->feedbackModel->findByComplaintId($complaintId)
        ) {
            throw new InvalidArgumentException(
                'Feedback has already been submitted for this complaint.'
            );
        }

        try {
            $feedbackId = $this->feedbackModel->create([
                'complaint_id' => $complaintId,
                'student_id' => $studentId,
                'rating' => $rating,
                'comments' => $comments
            ]);

        } catch (PDOException $e) {

            if (
                $e->getCode() === '23000' ||
                (string) ($e->errorInfo[1] ?? '') === '1062'
            ) {
                throw new InvalidArgumentException(
                    'Feedback has already been submitted for this complaint.'
                );
            }

            throw $e;
        }

        return [
            'feedback_id' => $feedbackId,
            'complaint_id' => $complaintId,
            'rating' => $rating,
            'comments' => $comments
        ];
    }

    /**
     * Get feedback submitted by a student.
     */
    public function getStudentFeedback(int $studentId): array
    {
        return $this->feedbackModel->findByStudent($studentId);
    }

    /**
     * Get all feedback with filters and pagination.
     */
    public function getAllFeedback(array $filters = []): array
    {
        if (
            isset($filters['rating']) &&
            $filters['rating'] !== ''
        ) {
            $rating = filter_var(
                $filters['rating'],
                FILTER_VALIDATE_INT
            );

            if (
                $rating === false ||
                $rating < 1 ||
                $rating > 5
            ) {
                throw new InvalidArgumentException(
                    'Rating filter must be between 1 and 5.'
                );
            }

            $filters['rating'] = $rating;
        }

        if (isset($filters['search'])) {
            $filters['search'] = trim(
                (string) $filters['search']
            );
        }

        $page = filter_var($filters['page'] ?? 1, FILTER_VALIDATE_INT);
        $perPage = filter_var($filters['per_page'] ?? 10, FILTER_VALIDATE_INT);
        if ($page === false || $page < 1) throw new InvalidArgumentException('Invalid page number.');
        if ($perPage === false || $perPage < 1 || $perPage > 100) throw new InvalidArgumentException('Per page must be between 1 and 100.');
        $filters['page'] = $page;
        $filters['per_page'] = $perPage;

        return $this->feedbackModel->findAll($filters);
    }

    /**
     * Get feedback details by ID.
     */
    public function getFeedbackDetails(int $feedbackId): array
    {
        if ($feedbackId <= 0) {
            throw new InvalidArgumentException(
                'A valid feedback ID is required.'
            );
        }

        $feedback = $this->feedbackModel->findDetailsById(
            $feedbackId
        );

        if (!$feedback) {
            throw new InvalidArgumentException(
                'Feedback not found.'
            );
        }

        return $feedback;
    }

    /**
     * Get overall feedback statistics.
     */
    public function getFeedbackStatistics(): array
    {
        return $this->feedbackModel->getStatistics();
    }
}
