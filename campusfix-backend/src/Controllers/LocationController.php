<?php

namespace Campusfix\Backend\Controllers;

use Campusfix\Backend\Middleware\AuthMiddleware;
use Campusfix\Backend\Services\LocationService;
use InvalidArgumentException;
use Throwable;

class LocationController
{
    private LocationService $locationService;

    public function __construct()
    {
        $this->locationService = new LocationService();
    }

    public function index(): void
    {
        try {
            AuthMiddleware::authorize(['ADMIN']);

            $locations = $this->locationService->getAllLocations();

            http_response_code(200);

            echo json_encode([
                'success' => true,
                'message' => 'Locations retrieved successfully.',
                'data' => $locations
            ]);
        } catch (Throwable $e) {
            $this->handleError($e);
        }
    }

    public function show(): void
    {
        try {
            AuthMiddleware::authorize(['ADMIN']);

            $locationId = filter_var(
                $_GET['id'] ?? null,
                FILTER_VALIDATE_INT
            );

            if (!$locationId || $locationId <= 0) {
                throw new InvalidArgumentException(
                    'Valid location ID is required.'
                );
            }

            $location = $this->locationService
                ->getLocationDetails($locationId);

            http_response_code(200);

            echo json_encode([
                'success' => true,
                'message' => 'Location retrieved successfully.',
                'data' => $location
            ]);
        } catch (Throwable $e) {
            $this->handleError($e);
        }
    }

    public function store(): void
    {
        try {
            AuthMiddleware::authorize(['ADMIN']);

            $data = json_decode(
                file_get_contents('php://input'),
                true
            );

            if (!is_array($data)) {
                throw new InvalidArgumentException(
                    'Valid JSON request body is required.'
                );
            }

            $location = $this->locationService
                ->createLocation($data);

            http_response_code(201);

            echo json_encode([
                'success' => true,
                'message' => 'Location created successfully.',
                'data' => $location
            ]);
        } catch (Throwable $e) {
            $this->handleError($e);
        }
    }

    public function update(): void
    {
        try {
            AuthMiddleware::authorize(['ADMIN']);

            $data = json_decode(
                file_get_contents('php://input'),
                true
            );

            if (!is_array($data)) {
                throw new InvalidArgumentException(
                    'Valid JSON request body is required.'
                );
            }

            $locationId = filter_var(
                $data['location_id'] ?? null,
                FILTER_VALIDATE_INT
            );

            if (!$locationId || $locationId <= 0) {
                throw new InvalidArgumentException(
                    'Valid location ID is required.'
                );
            }

            $location = $this->locationService
                ->updateLocation($locationId, $data);

            http_response_code(200);

            echo json_encode([
                'success' => true,
                'message' => 'Location updated successfully.',
                'data' => $location
            ]);
        } catch (Throwable $e) {
            $this->handleError($e);
        }
    }

    private function handleError(Throwable $e): void
    {
        if ($e instanceof InvalidArgumentException) {
            http_response_code(422);

            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);

            return;
        }

        $message = $e->getMessage();

        if (
            str_contains($message, 'Unauthorized') ||
            str_contains($message, 'token')
        ) {
            http_response_code(401);

            echo json_encode([
                'success' => false,
                'message' => 'Unauthorized access.'
            ]);

            return;
        }

        if (
            str_contains($message, 'Forbidden') ||
            str_contains($message, 'permission')
        ) {
            http_response_code(403);

            echo json_encode([
                'success' => false,
                'message' => 'Access forbidden.'
            ]);

            return;
        }

        error_log($e);

        http_response_code(500);

        echo json_encode([
            'success' => false,
            'message' => 'Internal server error.'
        ]);
    }
}
