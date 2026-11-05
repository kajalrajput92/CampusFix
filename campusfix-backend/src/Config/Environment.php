<?php
namespace Campusfix\Backend\Config;

use Dotenv\Dotenv;

class Environment
{
    public static function load(): void
    {
        $rootPath = dirname(__DIR__, 2);

        $dotenv = Dotenv::createImmutable($rootPath);

        $dotenv->load();
    }
}
