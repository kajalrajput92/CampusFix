<?php

namespace Campusfix\Backend\Models;

use Campusfix\Backend\Config\Database;
use PDO;

class Feedback
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::connect();
    }

    /**
     * Check whether a complaint belongs to a student
     * and has been resolved.
     */
    public function findEligibleComplaint(
        int $complaintId,
        int $studentId
    ): array|false {

        $sql = "
            SELECT
                complaint_id,
                complaint_number,
                student_id,
                status,
                resolved_at
            FROM complaints
            WHERE complaint_id = :complaint_id
              AND student_id = :student_id
              AND status = 'RESOLVED'
            LIMIT 1
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            'complaint_id' => $complaintId,
            'student_id' => $studentId
        ]);

        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    /**
     * Check whether feedback already exists.
     */
    public function findByComplaintId(
        int $complaintId
    ): array|false {

        $sql = "
            SELECT
                feedback_id,
                complaint_id,
                student_id,
                rating,
                comments,
                created_at
            FROM feedback
            WHERE complaint_id = :complaint_id
            LIMIT 1
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            'complaint_id' => $complaintId
        ]);

        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    /**
     * Create feedback for a resolved complaint.
     */
    public function create(array $data): int
    {
        $sql = "
            INSERT INTO feedback (
                complaint_id,
                student_id,
                rating,
                comments
            ) VALUES (
                :complaint_id,
                :student_id,
                :rating,
                :comments
            )
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            'complaint_id' => $data['complaint_id'],
            'student_id' => $data['student_id'],
            'rating' => $data['rating'],
            'comments' => $data['comments']
        ]);

        return (int) $this->db->lastInsertId();
    }

    /**
     * Get feedback submitted by a student.
     */
    public function findByStudent(int $studentId): array
    {
        $sql = "
            SELECT
                f.feedback_id,
                f.complaint_id,
                c.complaint_number,
                c.title,
                f.rating,
                f.comments,
                f.created_at
            FROM feedback f
            INNER JOIN complaints c
                ON f.complaint_id = c.complaint_id
            WHERE f.student_id = :student_id
            ORDER BY f.created_at DESC, f.feedback_id DESC
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            'student_id' => $studentId
        ]);

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Get all feedback for admin.
     */
    public function findAll(array $filters = []): array
    {
        $conditions = [];
        $params = [];

        if (isset($filters['rating']) && $filters['rating'] !== '') {
            $conditions[] = 'f.rating = :rating';
            $params['rating'] = (int) $filters['rating'];
        }

        if (!empty($filters['search'])) {
            $conditions[] = '(
                c.complaint_number LIKE :search_complaint
                OR c.title LIKE :search_title
                OR u.full_name LIKE :search_student
                OR f.comments LIKE :search_comments
            )';

            $search = '%' . trim($filters['search']) . '%';

            $params['search_complaint'] = $search;
            $params['search_title'] = $search;
            $params['search_student'] = $search;
            $params['search_comments'] = $search;
        }

        $whereSql = '';

        if (!empty($conditions)) {
            $whereSql = ' WHERE ' . implode(' AND ', $conditions);
        }

        $page = max(1, (int) ($filters['page'] ?? 1));

        $perPage = min(
            100,
            max(1, (int) ($filters['per_page'] ?? 10))
        );

        $offset = ($page - 1) * $perPage;

        $countSql = "
            SELECT COUNT(*)
            FROM feedback f
            INNER JOIN complaints c
                ON f.complaint_id = c.complaint_id
            INNER JOIN users u
                ON f.student_id = u.user_id
            $whereSql
        ";

        $countStmt = $this->db->prepare($countSql);
        $countStmt->execute($params);

        $total = (int) $countStmt->fetchColumn();

        $sql = "
            SELECT
                f.feedback_id,
                f.complaint_id,
                c.complaint_number,
                c.title,
                f.student_id,
                u.full_name AS student_name,
                f.rating,
                f.comments,
                f.created_at
            FROM feedback f
            INNER JOIN complaints c
                ON f.complaint_id = c.complaint_id
            INNER JOIN users u
                ON f.student_id = u.user_id
            $whereSql
            ORDER BY f.created_at DESC, f.feedback_id DESC
            LIMIT :limit OFFSET :offset
        ";

        $stmt = $this->db->prepare($sql);

        foreach ($params as $key => $value) {
            $stmt->bindValue(
                ':' . $key,
                $value,
                PDO::PARAM_STR
            );
        }

        $stmt->bindValue(':limit', $perPage, PDO::PARAM_INT);
        $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);

        $stmt->execute();

        return [
            'feedback' => $stmt->fetchAll(PDO::FETCH_ASSOC),
            'pagination' => [
                'total' => $total,
                'page' => $page,
                'per_page' => $perPage,
                'total_pages' => (int) ceil($total / $perPage)
            ]
        ];
    }

    /**
     * Get one feedback record for admin.
     */
    public function findDetailsById(int $feedbackId): array|false
    {
        $sql = "
            SELECT
                f.feedback_id,
                f.complaint_id,
                c.complaint_number,
                c.title,
                c.status AS complaint_status,
                f.student_id,
                u.full_name AS student_name,
                u.email AS student_email,
                f.rating,
                f.comments,
                f.created_at
            FROM feedback f
            INNER JOIN complaints c
                ON f.complaint_id = c.complaint_id
            INNER JOIN users u
                ON f.student_id = u.user_id
            WHERE f.feedback_id = :feedback_id
            LIMIT 1
        ";

        $stmt = $this->db->prepare($sql);

        $stmt->execute([
            'feedback_id' => $feedbackId
        ]);

        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    /**
     * Get overall feedback statistics.
     */
    public function getStatistics(): array
    {
        $sql = "
            SELECT
                COUNT(*) AS total_feedback,
                ROUND(AVG(rating), 2) AS average_rating,
                SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END)
                    AS five_star_count,
                SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END)
                    AS four_star_count,
                SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END)
                    AS three_star_count,
                SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END)
                    AS two_star_count,
                SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END)
                    AS one_star_count
            FROM feedback
        ";

        $stmt = $this->db->query($sql);

        return $stmt->fetch(PDO::FETCH_ASSOC);
    }
}
