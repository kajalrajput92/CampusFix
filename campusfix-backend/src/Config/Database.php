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
            $host = $_ENV['DB_HOST'];
            $port = $_ENV['DB_PORT'];
            $database = $_ENV['DB_DATABASE'];
            $username = $_ENV['DB_USERNAME'];
            $password = $_ENV['DB_PASSWORD'];
            $charset = $_ENV['DB_CHARSET'];

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
