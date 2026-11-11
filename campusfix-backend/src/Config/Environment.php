<?php

namespace Campusfix\Backend\Config;

use Dotenv\Dotenv;

class Environment
{
    public static function load(): void
    {
        $rootPath = dirname(__DIR__, 2);

        if (file_exists($rootPath . DIRECTORY_SEPARATOR . '.env')) {
            $dotenv = Dotenv::createImmutable($rootPath);
            $dotenv->safeLoad();
        }

        foreach (getenv() as $key => $val) {
            if (!isset($_ENV[$key])) {
                $_ENV[$key] = $val;
            }
        }

        date_default_timezone_set('Asia/Kolkata');
    }
}
