<?php

namespace Campusfix\Backend\Services;

use Campusfix\Backend\Models\Notification;
use InvalidArgumentException;

class NotificationService
{
    private Notification $notificationModel;

    public function __construct()
    {
        $this->notificationModel = new Notification();
    }


    /**
     * Create a notification for a user.
     */
    public function createNotification(array $data): int
    {
        $userId = filter_var(
            $data['user_id'] ?? null,
            FILTER_VALIDATE_INT
        );

        $complaintId = $data['complaint_id'] ?? null;

        if ($complaintId !== null && $complaintId !== '') {
            $complaintId = filter_var(
                $complaintId,
                FILTER_VALIDATE_INT
            );

            if ($complaintId === false || $complaintId <= 0) {
                throw new InvalidArgumentException(
                    'Invalid complaint ID.'
                );
            }
        } else {
            $complaintId = null;
        }

        $type = trim($data['type'] ?? '');
        $title = trim($data['title'] ?? '');
        $message = trim($data['message'] ?? '');

        if ($userId === false || $userId <= 0) {
            throw new InvalidArgumentException(
                'Valid user ID is required.'
            );
        }

        if ($type === '' || strlen($type) > 50) {
            throw new InvalidArgumentException(
                'Notification type is required and must not exceed 50 characters.'
            );
        }

        if ($title === '' || strlen($title) > 150) {
            throw new InvalidArgumentException(
                'Notification title is required and must not exceed 150 characters.'
            );
        }

        if ($message === '') {
            throw new InvalidArgumentException(
                'Notification message is required.'
            );
        }

        return $this->notificationModel->create([
            'user_id' => $userId,
            'complaint_id' => $complaintId,
            'type' => $type,
            'title' => $title,
            'message' => $message
        ]);
    }


    /**
     * Get notifications for the authenticated user.
     */
    public function getNotifications(
        int $userId,
        array $filters = []
    ): array {

        if ($userId <= 0) {
            throw new InvalidArgumentException(
                'Invalid user ID.'
            );
        }

        if (isset($filters['is_read'])) {
            $isRead = filter_var(
                $filters['is_read'],
                FILTER_VALIDATE_INT
            );

            if ($isRead === false || !in_array($isRead, [0, 1], true)) {
                throw new InvalidArgumentException(
                    'Read filter must be 0 or 1.'
                );
            }

            $filters['is_read'] = $isRead;
        }

        $page = filter_var(
            $filters['page'] ?? 1,
            FILTER_VALIDATE_INT
        );

        $limit = filter_var(
            $filters['limit'] ?? 20,
            FILTER_VALIDATE_INT
        );

        if ($page === false || $page < 1) {
            throw new InvalidArgumentException(
                'Page must be a positive integer.'
            );
        }

        if ($limit === false || $limit < 1 || $limit > 100) {
            throw new InvalidArgumentException(
                'Limit must be between 1 and 100.'
            );
        }

        $filters['page'] = $page;
        $filters['limit'] = $limit;

        return $this->notificationModel->findByUser(
            $userId,
            $filters
        );
    }

    /**
     * Get unread notification count.
     */
    public function getUnreadCount(int $userId): int
    {
        if ($userId <= 0) {
            throw new InvalidArgumentException(
                'Invalid user ID.'
            );
        }

        return $this->notificationModel->countUnread($userId);
    }

    /**
     * Mark a notification as read.
     */
    public function markAsRead(
        int $notificationId,
        int $userId
    ): array {

        if ($notificationId <= 0 || $userId <= 0) {
            throw new InvalidArgumentException(
                'Valid notification and user IDs are required.'
            );
        }

        $updated = $this->notificationModel->markAsRead(
            $notificationId,
            $userId
        );

        if (!$updated) {
            throw new InvalidArgumentException(
                'Notification not found or already marked as read.'
            );
        }

        return [
            'notification_id' => $notificationId,
            'is_read' => true
        ];
    }

    /**
     * Mark all notifications as read.
     */
    public function markAllAsRead(int $userId): array
    {
        if ($userId <= 0) {
            throw new InvalidArgumentException(
                'Invalid user ID.'
            );
        }

        $updatedCount = $this->notificationModel->markAllAsRead(
            $userId
        );

        return [
            'updated_count' => $updatedCount
        ];
    }

    /**
     * Delete a notification.
     */
    public function deleteNotification(
        int $notificationId,
        int $userId
    ): array {

        if ($notificationId <= 0 || $userId <= 0) {
            throw new InvalidArgumentException(
                'Valid notification and user IDs are required.'
            );
        }

        $deleted = $this->notificationModel->delete(
            $notificationId,
            $userId
        );

        if (!$deleted) {
            throw new InvalidArgumentException(
                'Notification not found.'
            );
        }

        return [
            'notification_id' => $notificationId,
            'deleted' => true
        ];
    }
}
