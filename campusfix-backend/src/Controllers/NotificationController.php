<?php

namespace Campusfix\Backend\Controllers;

use Campusfix\Backend\Services\NotificationService;
use Campusfix\Backend\Middleware\AuthMiddleware;
use InvalidArgumentException;
use RuntimeException;
use Throwable;

class NotificationController
{
    private NotificationService $notificationService;

    public function __construct()
    {
        $this->notificationService = new NotificationService();
    }

    /**
     * Handle authentication and authorization errors.
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
     * Get authenticated user notifications.
     */
    public function index(): array
    {
        try {
            $user = AuthMiddleware::authorize([
                'STUDENT',
                'STAFF',
                'ADMIN'
            ]);

            $filters = [
                'is_read' => $_GET['is_read'] ?? null,
                'page' => $_GET['page'] ?? 1,
                'limit' => $_GET['limit'] ?? 20
            ];

            if ($filters['is_read'] === null) {
                unset($filters['is_read']);
            }

            $notifications = $this->notificationService
                ->getNotifications((int) $user->sub, $filters);

            return [
                'success' => true,
                'message' => 'Notifications retrieved successfully.',
                'data' => $notifications
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
                'message' => 'Unable to retrieve notifications.'
            ];
        }
    }

    /**
     * Get unread notification count.
     */
    public function unreadCount(): array
    {
        try {
            $user = AuthMiddleware::authorize([
                'STUDENT',
                'STAFF',
                'ADMIN'
            ]);

            $count = $this->notificationService
                ->getUnreadCount((int) $user->sub);

            return [
                'success' => true,
                'message' => 'Unread notification count retrieved successfully.',
                'data' => [
                    'unread_count' => $count
                ]
            ];

        } catch (RuntimeException $e) {
            return $this->handleAuthException($e);

        } catch (Throwable $e) {
            error_log($e->getMessage());
            http_response_code(500);

            return [
                'success' => false,
                'message' => 'Unable to retrieve unread count.'
            ];
        }
    }

    /**
     * Mark one notification as read.
     */
    public function markAsRead(): array
    {
        try {
            $user = AuthMiddleware::authorize([
                'STUDENT',
                'STAFF',
                'ADMIN'
            ]);

            $notificationId = filter_var(
                $_GET['notification_id'] ?? null,
                FILTER_VALIDATE_INT
            );

            if ($notificationId === false || $notificationId <= 0) {
                throw new InvalidArgumentException(
                    'A valid notification ID is required.'
                );
            }

            $result = $this->notificationService->markAsRead(
                $notificationId,
                (int) $user->sub
            );

            return [
                'success' => true,
                'message' => 'Notification marked as read.',
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
                'message' => 'Unable to mark notification as read.'
            ];
        }
    }

    /**
     * Mark all notifications as read.
     */
    public function markAllAsRead(): array
    {
        try {
            $user = AuthMiddleware::authorize([
                'STUDENT',
                'STAFF',
                'ADMIN'
            ]);

            $result = $this->notificationService->markAllAsRead(
                (int) $user->sub
            );

            return [
                'success' => true,
                'message' => 'All notifications marked as read.',
                'data' => $result
            ];

        } catch (RuntimeException $e) {
            return $this->handleAuthException($e);

        } catch (Throwable $e) {
            error_log($e->getMessage());
            http_response_code(500);

            return [
                'success' => false,
                'message' => 'Unable to mark all notifications as read.'
            ];
        }
    }

    /**
     * Delete a notification belonging to the authenticated user.
     */
    public function delete(): array
    {
        try {
            $user = AuthMiddleware::authorize([
                'STUDENT',
                'STAFF',
                'ADMIN'
            ]);

            $notificationId = filter_var(
                $_GET['notification_id'] ?? null,
                FILTER_VALIDATE_INT
            );

            if ($notificationId === false || $notificationId <= 0) {
                throw new InvalidArgumentException(
                    'A valid notification ID is required.'
                );
            }

            $result = $this->notificationService->deleteNotification(
                $notificationId,
                (int) $user->sub
            );

            return [
                'success' => true,
                'message' => 'Notification deleted successfully.',
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
                'message' => 'Unable to delete notification.'
            ];
        }
    }
}
