
<?php

use Campusfix\Backend\Config\Environment;

require_once dirname(__DIR__) . '/vendor/autoload.php';

header('Content-Type: application/json; charset=utf-8');

try {
    Environment::load();

    $routes = require dirname(__DIR__) . '/routes/api.php';

    $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
    $path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);

    $routeKey = $method . ' ' . $path;

    if (!isset($routes[$routeKey])) {
        http_response_code(404);

        echo json_encode([
            'success' => false,
            'message' => 'Route not found'
        ]);

        exit;
    }

    [$controllerClass, $action] = $routes[$routeKey];

    $controller = new $controllerClass();
    $response = $controller->$action();

    echo json_encode($response, JSON_PRETTY_PRINT);

} catch (Throwable $e) {
    http_response_code(500);

    echo json_encode([
        'success' => false,
        'message' => 'Internal server error'
    ]);
}
