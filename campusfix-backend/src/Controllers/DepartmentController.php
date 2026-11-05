<?php

namespace Campusfix\Backend\Controllers;

use Campusfix\Backend\Middleware\AuthMiddleware;
use Campusfix\Backend\Services\DepartmentService;
use InvalidArgumentException;
use PDOException;
use Throwable;

class DepartmentController
{
    private DepartmentService $departmentService;

    public function __construct()
    {
        $this->departmentService = new DepartmentService();
    }

    // Get all departments
    public function index(): array
    {
        try {
            AuthMiddleware::authorize(['ADMIN']);

            $departments = $this->departmentService
                ->getAllDepartments();

            return [
                'success' => true,
                'message' => 'Departments retrieved successfully.',
                'data' => $departments
            ];

        } catch (Throwable $e) {
            error_log($e->getMessage());

            if (http_response_code() < 400) {
                http_response_code(500);
            }

            return [
                'success' => false,
                'message' => 'Unable to retrieve departments.'
            ];
        }
    }

    // Get department details
    public function show(): array
    {
        try {
            AuthMiddleware::authorize(['ADMIN']);

            $departmentId = filter_var(
                $_GET['id'] ?? null,
                FILTER_VALIDATE_INT
            );

            if (
                $departmentId === false ||
                $departmentId === null ||
                $departmentId <= 0
            ) {
                throw new InvalidArgumentException(
                    'Valid department ID is required.'
                );
            }

            $department = $this->departmentService
                ->getDepartmentDetails($departmentId);

            return [
                'success' => true,
                'message' => 'Department details retrieved successfully.',
                'data' => $department
            ];

        } catch (InvalidArgumentException $e) {
            http_response_code(422);

            return [
                'success' => false,
                'message' => $e->getMessage()
            ];

        } catch (Throwable $e) {
            error_log($e->getMessage());

            if (http_response_code() < 400) {
                http_response_code(500);
            }

            return [
                'success' => false,
                'message' => 'Unable to retrieve department details.'
            ];
        }
    }

    // Create department
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
                    'A valid JSON request body is required.'
                );
            }

            $department = $this->departmentService
                ->createDepartment($data);

            http_response_code(201);

            return [
                'success' => true,
                'message' => 'Department created successfully.',
                'data' => $department
            ];

        } catch (InvalidArgumentException $e) {
            http_response_code(422);

            return [
                'success' => false,
                'message' => $e->getMessage()
            ];

        } catch (PDOException $e) {
            error_log($e->getMessage());

            if ($e->getCode() === '23000') {
                http_response_code(409);

                return [
                    'success' => false,
                    'message' => 'Department name already exists.'
                ];
            }

            http_response_code(500);

            return [
                'success' => false,
                'message' => 'Unable to create department.'
            ];

        } catch (Throwable $e) {
            error_log($e->getMessage());

            if (http_response_code() < 400) {
                http_response_code(500);
            }

            return [
                'success' => false,
                'message' => 'Unable to create department.'
            ];
        }
    }

    // Update department
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
                    'A valid JSON request body is required.'
                );
            }

            $departmentId = filter_var(
                $data['department_id'] ?? null,
                FILTER_VALIDATE_INT
            );

            if (
                $departmentId === false ||
                $departmentId === null ||
                $departmentId <= 0
            ) {
                throw new InvalidArgumentException(
                    'Valid department ID is required.'
                );
            }

            $department = $this->departmentService
                ->updateDepartment($departmentId, $data);

            return [
                'success' => true,
                'message' => 'Department updated successfully.',
                'data' => $department
            ];

        } catch (InvalidArgumentException $e) {
            http_response_code(422);

            return [
                'success' => false,
                'message' => $e->getMessage()
            ];

        } catch (PDOException $e) {
            error_log($e->getMessage());

            if ($e->getCode() === '23000') {
                http_response_code(409);

                return [
                    'success' => false,
                    'message' => 'Department name already exists.'
                ];
            }

            http_response_code(500);

            return [
                'success' => false,
                'message' => 'Unable to update department.'
            ];

        } catch (Throwable $e) {
            error_log($e->getMessage());

            if (http_response_code() < 400) {
                http_response_code(500);
            }

            return [
                'success' => false,
                'message' => 'Unable to update department.'
            ];
        }
    }
}
