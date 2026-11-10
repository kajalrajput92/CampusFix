<?php

namespace Campusfix\Backend\Models;

use Campusfix\Backend\Config\Database;
use PDO;

class Department
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::connect();
    }

    // Get all departments with complaint and staff counts
    public function findAll(): array
    {
        $sql = "
            SELECT
                d.department_id,
                d.department_name,
                d.description,
                d.created_at,
                COUNT(DISTINCT c.complaint_id) AS total_complaints,
                COUNT(DISTINCT CASE WHEN u.role = 'STAFF' THEN u.user_id END) AS total_staff,
                COUNT(DISTINCT u.user_id) AS total_users
            FROM departments d
            LEFT JOIN complaints c
                ON c.department_id = d.department_id
            LEFT JOIN users u
                ON u.department_id = d.department_id
            GROUP BY d.department_id
            ORDER BY d.department_id DESC
        ";

        $stmt = $this->db->prepare($sql);
        $stmt->execute();

        return $stmt->fetchAll();
    }

    // Find department by ID
    public function findById(int $departmentId): array|false
    {
        $sql = "
            SELECT
                d.department_id,
                d.department_name,
                d.description,
                d.created_at,
                COUNT(DISTINCT c.complaint_id) AS total_complaints,
                COUNT(DISTINCT CASE WHEN u.role = 'STAFF' THEN u.user_id END) AS total_staff,
                COUNT(DISTINCT u.user_id) AS total_users
            FROM departments d
            LEFT JOIN complaints c
                ON c.department_id = d.department_id
            LEFT JOIN users u
                ON u.department_id = d.department_id
            WHERE d.department_id = :department_id
            GROUP BY d.department_id
            LIMIT 1
        ";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([
            'department_id' => $departmentId
        ]);

        return $stmt->fetch();
    }

    // Create department
    public function create(array $data): int
    {
        $sql = "
            INSERT INTO departments (
                department_name,
                description
            ) VALUES (
                :department_name,
                :description
            )
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            'department_name' => $data['department_name'],
            'description' => $data['description']
        ]);

        return (int) $this->db->lastInsertId();
    }

    // Update department
    public function update(int $departmentId, array $data): bool
    {
        $sql = "
            UPDATE departments
            SET
                department_name = :department_name,
                description = :description
            WHERE department_id = :department_id
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            'department_name' => $data['department_name'],
            'description' => $data['description'],
            'department_id' => $departmentId
        ]);

        return $stmt->rowCount() > 0;
    }

    public function deleteIfUnused(int $departmentId): bool
    {
        $this->db->beginTransaction();
        try {
            $lock = $this->db->prepare('SELECT department_id FROM departments WHERE department_id=:id FOR UPDATE');
            $lock->execute(['id' => $departmentId]);
            if (!$lock->fetchColumn()) {
                $this->db->commit();
                return false;
            }
            $users = $this->db->prepare('SELECT COUNT(*) FROM users WHERE department_id=:id');
            $users->execute(['id' => $departmentId]);
            $complaints = $this->db->prepare('SELECT COUNT(*) FROM complaints WHERE department_id=:id');
            $complaints->execute(['id' => $departmentId]);
            if ((int) $users->fetchColumn() > 0 || (int) $complaints->fetchColumn() > 0) {
                throw new \Campusfix\Backend\Services\ConflictException('Department is referenced by users or complaints and cannot be deleted.');
            }
            $delete = $this->db->prepare('DELETE FROM departments WHERE department_id=:id');
            $delete->execute(['id' => $departmentId]);
            $this->db->commit();
            return $delete->rowCount() === 1;
        } catch (\Throwable $error) {
            if ($this->db->inTransaction()) $this->db->rollBack();
            throw $error;
        }
    }
}
