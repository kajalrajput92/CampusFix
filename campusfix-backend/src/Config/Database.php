<?php

namespace Campusfix\Backend\Config;

use PDO;
use PDOException;

class Database
{
    private static ?PDO $connection = null;

    public static function connect(): PDO
    {
        if (self::$connection === null) {
            $host = $_ENV['DB_HOST'] ?? getenv('DB_HOST') ?: '127.0.0.1';
            $port = $_ENV['DB_PORT'] ?? getenv('DB_PORT') ?: '3306';
            $database = $_ENV['DB_DATABASE'] ?? getenv('DB_DATABASE') ?: 'campusfix_db';
            $username = $_ENV['DB_USERNAME'] ?? getenv('DB_USERNAME') ?: 'root';
            $password = $_ENV['DB_PASSWORD'] ?? getenv('DB_PASSWORD') ?: '';
            $charset = $_ENV['DB_CHARSET'] ?? getenv('DB_CHARSET') ?: 'utf8mb4';

            $dsn = "mysql:host={$host};port={$port};dbname={$database};charset={$charset}";

            $options = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false
            ];
            if (defined('PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT')) {
                $options[PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT] = false;
            }

            try {
                self::$connection = new PDO(
                    $dsn,
                    $username,
                    $password,
                    $options
                );
            } catch (PDOException $e) {
     throw new PDOException(
    "Database connection failed.",
    (int) $e->getCode()
);
            }
        }

        return self::$connection;
    }
}
