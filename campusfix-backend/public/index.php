
<?php

use Campusfix\Backend\Config\Environment;

require_once dirname(__DIR__) . '/vendor/autoload.php';

header('Content-Type: application/json; charset=utf-8');

try {
    Environment::load();

    $requestOrigin = $_SERVER['HTTP_ORIGIN'] ?? '';
    $corsConfig = $_ENV['CORS_ALLOWED_ORIGINS'] ?? '*';
    $isDev = ($_ENV['APP_ENV'] ?? 'development') === 'development' || ($_ENV['APP_DEBUG'] ?? 'true') === 'true';

    $allowedOrigins = array_values(array_filter(array_map(
        'trim',
        explode(',', $corsConfig)
    )));

    header('Vary: Origin');

    $originAllowed = false;
    if ($requestOrigin !== '') {
        if ($isDev || $corsConfig === '*' || in_array($requestOrigin, $allowedOrigins, true)) {
            $originAllowed = true;
        }
    }

    if ($originAllowed) {
        header('Access-Control-Allow-Origin: ' . $requestOrigin);
        header('Access-Control-Allow-Methods: GET, POST, PATCH, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Authorization, Content-Type, Accept, X-Requested-With');
        header('Access-Control-Max-Age: 600');
    }

    if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
        if (!$originAllowed && !$isDev) {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Origin is not allowed.']);
            exit;
        }
        http_response_code(204);
        exit;
    }

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
}
catch (Throwable $e) {
    error_log('[CampusFix API ERROR] ' . $e, 4);
    http_response_code(500);

    echo json_encode([
        'success' => false,
        'message' => 'Internal server error'
    ]);
}
