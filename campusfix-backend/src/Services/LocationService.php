<?php

namespace Campusfix\Backend\Services;

use Campusfix\Backend\Models\Location;
use InvalidArgumentException;

class LocationService
{
    private Location $locationModel;

    public function __construct()
    {
        $this->locationModel = new Location();
    }

    public function getAllLocations(): array
    {
        return $this->locationModel->findAll();
    }

    public function getLocationDetails(int $locationId): array
    {
        if ($locationId <= 0) {
            throw new InvalidArgumentException(
                'Valid location ID is required.'
            );
        }

        $location = $this->locationModel->findById($locationId);

        if (!$location) {
            throw new InvalidArgumentException(
                'Location not found.'
            );
        }

        return $location;
    }

    public function createLocation(array $data): array
    {
        $validatedData = $this->validateLocationData($data);

        $locationId = $this->locationModel->create($validatedData);

        return $this->getLocationDetails($locationId);
    }

    public function updateLocation(int $locationId, array $data): array
    {
        if ($locationId <= 0) {
            throw new InvalidArgumentException(
                'Valid location ID is required.'
            );
        }

        $this->getLocationDetails($locationId);

        $validatedData = $this->validateLocationData($data);

        $this->locationModel->update($locationId, $validatedData);

        return $this->getLocationDetails($locationId);
    }

    private function validateLocationData(array $data): array
    {
        $buildingName = trim($data['building_name'] ?? '');

        $blockName = trim($data['block_name'] ?? '');
        $floorNumber = trim($data['floor_number'] ?? '');
        $roomNumber = trim($data['room_number'] ?? '');
        $description = trim($data['description'] ?? '');

        if ($buildingName === '') {
            throw new InvalidArgumentException(
                'Building name is required.'
            );
        }

        if (strlen($buildingName) > 150) {
            throw new InvalidArgumentException(
                'Building name cannot exceed 150 characters.'
            );
        }

        if (strlen($blockName) > 100) {
            throw new InvalidArgumentException(
                'Block name cannot exceed 100 characters.'
            );
        }

        if (strlen($floorNumber) > 20) {
            throw new InvalidArgumentException(
                'Floor number cannot exceed 20 characters.'
            );
        }

        if (strlen($roomNumber) > 30) {
            throw new InvalidArgumentException(
                'Room number cannot exceed 30 characters.'
            );
        }

        if (strlen($description) > 5000) {
            throw new InvalidArgumentException(
                'Description cannot exceed 5000 characters.'
            );
        }

        return [
            'building_name' => $buildingName,
            'block_name' => $blockName !== '' ? $blockName : null,
            'floor_number' => $floorNumber !== '' ? $floorNumber : null,
            'room_number' => $roomNumber !== '' ? $roomNumber : null,
            'description' => $description !== '' ? $description : null
        ];
    }
}
