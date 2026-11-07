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

    public function index(): array
    {
        try {
            AuthMiddleware::authorize(['ADMIN', 'STUDENT', 'STAFF']);

            $locations = $this->locationService->getAllLocations();

            http_response_code(200);

            return [
                'success' => true,
                'message' => 'Locations retrieved successfully.',
                'data' => $locations
            ];
        } catch (Throwable $e) {
            return $this->handleError($e);
        }
    }

    public function show(): array
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

            return [
                'success' => true,
                'message' => 'Location retrieved successfully.',
                'data' => $location
            ];
        } catch (Throwable $e) {
            return $this->handleError($e);
        }
    }

    public function store(): array
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

            return [
                'success' => true,
                'message' => 'Location created successfully.',
                'data' => $location
            ];
        } catch (Throwable $e) {
            return $this->handleError($e);
        }
    }

    public function update(): array
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

            return [
                'success' => true,
                'message' => 'Location updated successfully.',
                'data' => $location
            ];
        } catch (Throwable $e) {
            return $this->handleError($e);
        }
    }

    private function handleError(Throwable $e): array
    {
        if ($e instanceof InvalidArgumentException) {
            http_response_code(422);

            return [
                'success' => false,
                'message' => $e->getMessage()
            ];
        }

        $statusCode = http_response_code();
        $message = $e->getMessage();

        if (
            $statusCode === 401 ||
            str_contains($message, 'Unauthorized') ||
            str_contains($message, 'token')
        ) {
            http_response_code(401);

            return [
                'success' => false,
                'message' => 'Unauthorized access.'
            ];
        }

        if (
            $statusCode === 403 ||
            str_contains($message, 'Forbidden') ||
            str_contains($message, 'permission')
        ) {
            http_response_code(403);

            return [
                'success' => false,
                'message' => 'Access forbidden.'
            ];
        }

        error_log($e->getMessage());

        http_response_code(500);

        return [
            'success' => false,
            'message' => 'Internal server error.'
        ];
    }
}
