<?php

namespace Campusfix\Backend\Models;

use Campusfix\Backend\Config\Database;
use PDO;

class User
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::connect();
    }

    public function findByEmail(string $email): array|false
    {
        $sql = "SELECT * FROM users WHERE email = :email LIMIT 1";

        $stmt = $this->db->prepare($sql);
        $stmt->execute(['email' => $email]);

        return $stmt->fetch();
    }

    public function findById(int $userId): array|false
    {
        $sql = "SELECT * FROM users WHERE user_id = :user_id LIMIT 1";

        $stmt = $this->db->prepare($sql);
        $stmt->execute(['user_id' => $userId]);

        return $stmt->fetch();
    }

    public function create(array $data): int
    {
        $sql = "
            INSERT INTO users (
                department_id,
                full_name,
                email,
                password_hash,
                phone,
                role,
                enrollment_number,
                employee_id
            ) VALUES (
                :department_id,
                :full_name,
                :email,
                :password_hash,
                :phone,
                :role,
                :enrollment_number,
                :employee_id
            )
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            'department_id' => $data['department_id'] ?? null,
            'full_name' => $data['full_name'],
            'email' => $data['email'],
            'password_hash' => $data['password_hash'],
            'phone' => $data['phone'] ?? null,
            'role' => $data['role'] ?? 'STUDENT',
            'enrollment_number' => $data['enrollment_number'] ?? null,
            'employee_id' => $data['employee_id'] ?? null
        ]);

        return (int) $this->db->lastInsertId();
    }

    // Get all staff with search, active filter and pagination
    public function findAllStaff(array $filters = []): array
    {
        $where = ["u.role = 'STAFF'"];
        $params = [];

        if (!empty($filters['search'])) {
            $where[] = "(
                u.full_name LIKE :search_name
                OR u.email LIKE :search_email
                OR u.employee_id LIKE :search_employee
            )";

            $search = '%' . $filters['search'] . '%';

            $params['search_name'] = $search;
            $params['search_email'] = $search;
            $params['search_employee'] = $search;
        }

        if (isset($filters['is_active'])) {
            $where[] = "u.is_active = :is_active";
            $params['is_active'] = $filters['is_active'];
        }

        $whereSql = implode(' AND ', $where);

        $countSql = "
            SELECT COUNT(*)
            FROM users u
            WHERE {$whereSql}
        ";

        $countStmt = $this->db->prepare($countSql);
        $countStmt->execute($params);

        $total = (int) $countStmt->fetchColumn();

        $page = $filters['page'] ?? 1;
        $perPage = $filters['per_page'] ?? 10;
        $offset = ($page - 1) * $perPage;

        $sql = "
            SELECT
                u.user_id,
                u.full_name,
                u.email,
                u.phone,
                u.employee_id,
                u.department_id,
                u.is_active,
                u.created_at,
                d.department_name,
                COUNT(DISTINCT ca.complaint_id) AS assigned_complaints
            FROM users u
            LEFT JOIN departments d
                ON d.department_id = u.department_id
            LEFT JOIN complaint_assignments ca
    ON ca.staff_id = u.user_id
    AND ca.assignment_id = (
        SELECT MAX(ca2.assignment_id)
        FROM complaint_assignments ca2
        WHERE ca2.complaint_id = ca.complaint_id
    )
            WHERE {$whereSql}
            GROUP BY u.user_id
            ORDER BY u.user_id DESC
            LIMIT :limit OFFSET :offset
        ";

        $stmt = $this->db->prepare($sql);

        foreach ($params as $key => $value) {
            $stmt->bindValue(':' . $key, $value);
        }

        $stmt->bindValue(':limit', (int) $perPage, PDO::PARAM_INT);
        $stmt->bindValue(':offset', (int) $offset, PDO::PARAM_INT);

        $stmt->execute();

        return [
            'staff' => $stmt->fetchAll(),
            'pagination' => [
                'total' => $total,
                'page' => (int) $page,
                'per_page' => (int) $perPage,
                'total_pages' => (int) ceil($total / $perPage)
            ]
        ];
    }

    // Get individual staff details and workload
    public function findStaffDetailsById(int $staffId): array|false
    {
        $sql = "
            SELECT
                u.user_id,
                u.full_name,
                u.email,
                u.phone,
                u.employee_id,
                u.department_id,
                u.is_active,
                u.created_at,
                d.department_name,

                (
                    SELECT COUNT(*)
                    FROM complaint_assignments ca
                    WHERE ca.staff_id = u.user_id
                    AND ca.assignment_id = (
                        SELECT MAX(ca2.assignment_id)
                        FROM complaint_assignments ca2
                        WHERE ca2.complaint_id = ca.complaint_id
                    )
                ) AS current_assigned_complaints

            FROM users u
            LEFT JOIN departments d
                ON d.department_id = u.department_id
            WHERE u.user_id = :staff_id
            AND u.role = 'STAFF'
            LIMIT 1
        ";

        $stmt = $this->db->prepare($sql);
        $stmt->execute(['staff_id' => $staffId]);

        return $stmt->fetch();
    }

    // Activate or deactivate a staff account
    public function updateStaffStatus(
        int $staffId,
        bool $isActive
    ): bool {
        $sql = "
            UPDATE users
            SET is_active = :is_active,
                token_version = token_version + 1
            WHERE user_id = :staff_id
            AND role = 'STAFF'
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            'is_active' => (int) $isActive,
            'staff_id' => $staffId
        ]);

        return $stmt->rowCount() > 0;
    }

    public function findAllStudents(array $filters): array
    {
        $conditions = ["u.role = 'STUDENT'"];
        $params = [];
        if ($filters['search'] !== '') {
            $conditions[] = '(u.full_name LIKE :name OR u.email LIKE :email OR u.enrollment_number LIKE :enrollment)';
            $pattern = '%' . $filters['search'] . '%';
            $params['name'] = $pattern;
            $params['email'] = $pattern;
            $params['enrollment'] = $pattern;
        }
        if ($filters['is_active'] !== null) {
            $conditions[] = 'u.is_active = :is_active';
            $params['is_active'] = $filters['is_active'];
        }
        $where = implode(' AND ', $conditions);
        $count = $this->db->prepare("SELECT COUNT(*) FROM users u WHERE $where");
        $count->execute($params);
        $total = (int) $count->fetchColumn();
        $query = $this->db->prepare("SELECT u.user_id,u.full_name,u.email,u.phone,u.enrollment_number,u.department_id,u.is_active,u.created_at,d.department_name,(SELECT COUNT(*) FROM complaints c WHERE c.student_id=u.user_id) AS complaint_count FROM users u LEFT JOIN departments d ON d.department_id=u.department_id WHERE $where ORDER BY u.user_id DESC LIMIT :limit OFFSET :offset");
        foreach ($params as $key => $value) $query->bindValue(':' . $key, $value);
        $query->bindValue(':limit', $filters['per_page'], PDO::PARAM_INT);
        $query->bindValue(':offset', ($filters['page'] - 1) * $filters['per_page'], PDO::PARAM_INT);
        $query->execute();
        return ['students' => $query->fetchAll(PDO::FETCH_ASSOC), 'pagination' => ['total' => $total, 'page' => $filters['page'], 'per_page' => $filters['per_page'], 'total_pages' => (int) ceil($total / $filters['per_page'])]];
    }

    public function findStudentDetailsById(int $studentId): array|false
    {
        $stmt = $this->db->prepare("SELECT u.user_id,u.full_name,u.email,u.phone,u.enrollment_number,u.department_id,u.is_active,u.created_at,u.updated_at,d.department_name,(SELECT COUNT(*) FROM complaints c WHERE c.student_id=u.user_id) AS complaint_count FROM users u LEFT JOIN departments d ON d.department_id=u.department_id WHERE u.user_id=:id AND u.role='STUDENT' LIMIT 1");
        $stmt->execute(['id' => $studentId]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function findStudentComplaints(int $studentId, int $page, int $perPage): array
    {
        $count = $this->db->prepare("SELECT COUNT(*) FROM complaints WHERE student_id=:id");
        $count->execute(['id' => $studentId]);
        $total = (int) $count->fetchColumn();
        $stmt = $this->db->prepare("SELECT complaint_id,complaint_number,title,category,priority,status,created_at,due_at,resolved_at FROM complaints WHERE student_id=:id ORDER BY created_at DESC LIMIT :limit OFFSET :offset");
        $stmt->bindValue(':id', $studentId, PDO::PARAM_INT);
        $stmt->bindValue(':limit', $perPage, PDO::PARAM_INT);
        $stmt->bindValue(':offset', ($page - 1) * $perPage, PDO::PARAM_INT);
        $stmt->execute();
        return ['complaints' => $stmt->fetchAll(PDO::FETCH_ASSOC), 'pagination' => ['total' => $total, 'page' => $page, 'per_page' => $perPage, 'total_pages' => (int) ceil($total / $perPage)]];
    }

    public function updateStudentStatus(int $studentId, bool $isActive): bool
    {
        $stmt = $this->db->prepare("UPDATE users SET is_active=:active,token_version=token_version+1 WHERE user_id=:id AND role='STUDENT'");
        $stmt->execute(['active' => (int) $isActive, 'id' => $studentId]);
        return $stmt->rowCount() > 0;
    }

    public function updateStaff(int $staffId, array $data): bool
    {
        $stmt = $this->db->prepare("UPDATE users SET full_name=:name,email=:email,phone=:phone,department_id=:department_id,employee_id=:employee_id,token_version=token_version+1 WHERE user_id=:id AND role='STAFF'");
        $stmt->execute(['name' => $data['full_name'], 'email' => $data['email'], 'phone' => $data['phone'], 'department_id' => $data['department_id'], 'employee_id' => $data['employee_id'], 'id' => $staffId]);
        return $stmt->rowCount() > 0;
    }

    public function incrementTokenVersion(int $userId): bool
    {
        $stmt = $this->db->prepare('UPDATE users SET token_version=token_version+1 WHERE user_id=:id');
        $stmt->execute(['id' => $userId]);
        return $stmt->rowCount() > 0;
    }
    public function findProfileById(int $userId): array|false
{
    $sql = "
        SELECT
            user_id,
            department_id,
            full_name,
            email,
            phone,
            role,
            enrollment_number,
            employee_id,
            is_active,
            created_at,
            updated_at
        FROM users
        WHERE user_id = :user_id
        LIMIT 1
    ";

    $stmt = $this->db->prepare($sql);
    $stmt->execute(['user_id' => $userId]);

    return $stmt->fetch();
}

public function updateProfile(
    int $userId,
    string $fullName,
    ?string $phone
): bool {
    $sql = "
        UPDATE users
        SET
            full_name = :full_name,
            phone = :phone
        WHERE user_id = :user_id
    ";

    $stmt = $this->db->prepare($sql);

    return $stmt->execute([
        'full_name' => $fullName,
        'phone' => $phone,
        'user_id' => $userId
    ]);
}

public function updatePassword(int $userId, string $passwordHash): bool
{
    $sql = "
        UPDATE users
        SET password_hash = :password_hash
        WHERE user_id = :user_id
    ";

    $stmt = $this->db->prepare($sql);

    $stmt->execute([
        'password_hash' => $passwordHash,
        'user_id' => $userId
    ]);

    return $stmt->rowCount() > 0;
}
public function getTokenVersion(int $userId): int|false
{
    $sql = "
        SELECT token_version, is_active
        FROM users
        WHERE user_id = :user_id
        LIMIT 1
    ";

    $stmt = $this->db->prepare($sql);
    $stmt->execute(['user_id' => $userId]);

    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($result === false || (int) $result['is_active'] !== 1) {
        return false;
    }

    return (int) $result['token_version'];
}
}
