<?php

namespace Campusfix\Backend\Models;

use Campusfix\Backend\Config\Database;
use PDO;

class Notification
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::connect();
    }

    /**
     * Create a notification for a user.
     */
    public function create(array $data): int
    {
        $sql = "
            INSERT INTO notifications (
                user_id,
                complaint_id,
                type,
                title,
                message
            )
            VALUES (
                :user_id,
                :complaint_id,
                :type,
                :title,
                :message
            )
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            ':user_id' => $data['user_id'],
            ':complaint_id' => $data['complaint_id'] ?? null,
            ':type' => $data['type'],
            ':title' => $data['title'],
            ':message' => $data['message']
        ]);

        return (int) $this->db->lastInsertId();
    }

    /**
     * Get notifications belonging to a user.
     */
    public function findByUser(
        int $userId,
        array $filters = []
    ): array {

        $where = ['user_id = :user_id'];

        $params = [
            ':user_id' => $userId
        ];

        if (isset($filters['is_read'])) {
            $where[] = 'is_read = :is_read';
            $params[':is_read'] = $filters['is_read'];
        }

        $limit = max(
            1,
            min(100, (int) ($filters['limit'] ?? 20))
        );

        $page = max(
            1,
            (int) ($filters['page'] ?? 1)
        );

        $offset = ($page - 1) * $limit;

        $sql = "
            SELECT
                notification_id,
                user_id,
                complaint_id,
                type,
                title,
                message,
                is_read,
                created_at,
                read_at
            FROM notifications
            WHERE " . implode(' AND ', $where) . "
            ORDER BY created_at DESC, notification_id DESC
            LIMIT :limit OFFSET :offset
        ";

        $stmt = $this->db->prepare($sql);

        foreach ($params as $key => $value) {
            $stmt->bindValue($key, $value, PDO::PARAM_INT);
        }

        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);

        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Count unread notifications for a user.
     */
    public function countUnread(int $userId): int
    {
        $sql = "
            SELECT COUNT(*)
            FROM notifications
            WHERE user_id = :user_id
            AND is_read = 0
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            ':user_id' => $userId
        ]);

        return (int) $stmt->fetchColumn();
    }

    /**
     * Mark one notification as read.
     */
    public function markAsRead(
        int $notificationId,
        int $userId
    ): bool {

        $sql = "
            UPDATE notifications
            SET
                is_read = 1,
                read_at = CURRENT_TIMESTAMP
            WHERE notification_id = :notification_id
            AND user_id = :user_id
            AND is_read = 0
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            ':notification_id' => $notificationId,
            ':user_id' => $userId
        ]);

        return $stmt->rowCount() > 0;
    }

    /**
     * Mark all notifications as read for a user.
     */
    public function markAllAsRead(int $userId): int
    {
        $sql = "
            UPDATE notifications
            SET
                is_read = 1,
                read_at = CURRENT_TIMESTAMP
            WHERE user_id = :user_id
            AND is_read = 0
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            ':user_id' => $userId
        ]);

        return $stmt->rowCount();
    }

    /**
     * Delete a notification belonging to a user.
     */
    public function delete(
        int $notificationId,
        int $userId
    ): bool {

        $sql = "
            DELETE FROM notifications
            WHERE notification_id = :notification_id
            AND user_id = :user_id
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            ':notification_id' => $notificationId,
            ':user_id' => $userId
        ]);

        return $stmt->rowCount() > 0;
    }
}
