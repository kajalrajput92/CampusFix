<?php

namespace Campusfix\Backend\Models;

use Campusfix\Backend\Config\Database;
use PDO;

class Location
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::connect();
    }

    public function findAll(): array
    {
        $sql = "
            SELECT
                location_id,
                building_name,
                block_name,
                floor_number,
                room_number,
                description,
                created_at
            FROM locations
            ORDER BY location_id DESC
        ";

        $stmt = $this->db->prepare($sql);
        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function findById(int $locationId): array|false
    {
        $sql = "
            SELECT
                location_id,
                building_name,
                block_name,
                floor_number,
                room_number,
                description,
                created_at
            FROM locations
            WHERE location_id = :location_id
            LIMIT 1
        ";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([
            'location_id' => $locationId
        ]);

        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function create(array $data): int
    {
        $sql = "
            INSERT INTO locations (
                building_name,
                block_name,
                floor_number,
                room_number,
                description
            ) VALUES (
                :building_name,
                :block_name,
                :floor_number,
                :room_number,
                :description
            )
        ";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([
            'building_name' => $data['building_name'],
            'block_name' => $data['block_name'],
            'floor_number' => $data['floor_number'],
            'room_number' => $data['room_number'],
            'description' => $data['description']
        ]);

        return (int) $this->db->lastInsertId();
    }

    public function update(int $locationId, array $data): bool
    {
        $sql = "
            UPDATE locations
            SET
                building_name = :building_name,
                block_name = :block_name,
                floor_number = :floor_number,
                room_number = :room_number,
                description = :description
            WHERE location_id = :location_id
        ";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([
            'building_name' => $data['building_name'],
            'block_name' => $data['block_name'],
            'floor_number' => $data['floor_number'],
            'room_number' => $data['room_number'],
            'description' => $data['description'],
            'location_id' => $locationId
        ]);

        return $stmt->rowCount() > 0;
    }
}
