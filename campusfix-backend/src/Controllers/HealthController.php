<?php
namespace Campusfix\Backend\Controllers;

use Campusfix\Backend\Config\Database;
use PDOException;

class HealthController
{
    public function check(): array
    {
        try {
            $pdo = Database::connect();

            $databaseVersion = $pdo
                ->query("SELECT VERSION()")
                ->fetchColumn();

            return [
                'success' => true,
                'message' => 'CampusFix API is running',
                'database' => 'connected',
                'database_version' => $databaseVersion
            ];

        } catch (PDOException $e) {
            return [
                'success' => false,
                'message' => 'CampusFix API is running',
                'database' => 'disconnected'
            ];
        }
    }
}
