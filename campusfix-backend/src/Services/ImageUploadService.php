<?php

namespace Campusfix\Backend\Services;

use InvalidArgumentException;
use RuntimeException;
use Throwable;

class ImageUploadService
{
    private const MAX_IMAGES = 5;
    private const MAX_FILE_SIZE = 5 * 1024 * 1024;

    private const ALLOWED_MIME_TYPES = [
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp'
    ];

    private string $uploadDirectory;

    public function __construct()
    {
        $this->uploadDirectory = dirname(__DIR__, 2)
            . DIRECTORY_SEPARATOR
            . 'storage'
            . DIRECTORY_SEPARATOR
            . 'uploads'
            . DIRECTORY_SEPARATOR
            . 'complaints';
    }

    /**
     * Validate and store complaint images.
     *
     * @return array<int, string>
     */
    public function upload(array $files): array
    {
        if (!isset($files['error'])) {
            throw new InvalidArgumentException(
                'Invalid image upload data.'
            );
        }

        $normalized = $this->normalizeFiles($files);

        // Ignore empty file fields.
        $normalized = array_values(array_filter(
            $normalized,
            static fn(array $file): bool =>
                $file['error'] !== UPLOAD_ERR_NO_FILE
        ));

        if (count($normalized) > self::MAX_IMAGES) {
            throw new InvalidArgumentException(
                'Maximum 5 images are allowed per complaint.'
            );
        }

        if (empty($normalized)) {
            return [];
        }

        if (!is_dir($this->uploadDirectory)) {
            if (
                !mkdir($this->uploadDirectory, 0750, true) &&
                !is_dir($this->uploadDirectory)
            ) {
                throw new RuntimeException(
                    'Unable to create upload directory.'
                );
            }
        }

        if (!is_writable($this->uploadDirectory)) {
            throw new RuntimeException(
                'Upload directory is not writable.'
            );
        }

        $storedPaths = [];

        try {
            foreach ($normalized as $file) {
                if ($file['error'] !== UPLOAD_ERR_OK) {
                    throw new InvalidArgumentException(
                        $this->getUploadErrorMessage($file['error'])
                    );
                }

                if (
                    !is_string($file['tmp_name']) ||
                    $file['tmp_name'] === '' ||
                    !is_uploaded_file($file['tmp_name'])
                ) {
                    throw new InvalidArgumentException(
                        'Invalid uploaded image.'
                    );
                }

                $size = filesize($file['tmp_name']);

                if ($size === false || $size <= 0) {
                    throw new InvalidArgumentException(
                        'Uploaded image is empty or invalid.'
                    );
                }

                if ($size > self::MAX_FILE_SIZE) {
                    throw new InvalidArgumentException(
                        'Each image must not exceed 5 MB.'
                    );
                }

                // Detect actual MIME type, not filename extension.
                $finfo = new \finfo(FILEINFO_MIME_TYPE);
                $mimeType = $finfo->file($file['tmp_name']);
              

                if (
                    !is_string($mimeType) ||
                    !isset(self::ALLOWED_MIME_TYPES[$mimeType])
                ) {
                    throw new InvalidArgumentException(
                        'Only JPG, PNG and WebP images are allowed.'
                    );
                }

                // Verify that the file contains image data.
                $imageInfo = @getimagesize($file['tmp_name']);

                if (
                    $imageInfo === false ||
                    !isset($imageInfo['mime']) ||
                    $imageInfo['mime'] !== $mimeType
                ) {
                    throw new InvalidArgumentException(
                        'Uploaded file is not a valid image.'
                    );
                }

                $extension = self::ALLOWED_MIME_TYPES[$mimeType];

                $filename = bin2hex(random_bytes(16))
                    . '.'
                    . $extension;

                $destination = $this->uploadDirectory
                    . DIRECTORY_SEPARATOR
                    . $filename;

                if (!move_uploaded_file(
                    $file['tmp_name'],
                    $destination
                )) {
                    throw new RuntimeException(
                        'Unable to store uploaded image.'
                    );
                }

                $storedPaths[] =
                    'storage/uploads/complaints/' . $filename;
            }

            return $storedPaths;

        } catch (Throwable $e) {
            $this->deleteFiles($storedPaths);
            throw $e;
        }
    }

    /** Resolve only paths created by this uploader; never serve a caller path. */
    public function resolveStoredImage(string $storedPath): array|false
    {
        $filename = basename($storedPath);
        if (!preg_match('/^[a-f0-9]{32}\.(jpg|png|webp)$/', $filename)) return false;
        $root = realpath($this->uploadDirectory);
        $file = realpath($this->uploadDirectory . DIRECTORY_SEPARATOR . $filename);
        if ($root === false || $file === false || !is_file($file)) return false;
        $prefix = rtrim($root, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;
        if (!str_starts_with($file, $prefix)) return false;
        $finfo = new \finfo(FILEINFO_MIME_TYPE);
        $mime = $finfo->file($file);
        if (!in_array($mime, ['image/jpeg', 'image/png', 'image/webp'], true)) return false;
        return ['path' => $file, 'mime' => $mime, 'name' => $filename];
    }

    /**
     * Normalize PHP single and multiple file upload structures.
     */
    private function normalizeFiles(array $files): array
    {
        $normalized = [];

        if (is_array($files['error'])) {
            $count = count($files['error']);

            if (
                !isset(
                    $files['name'],
                    $files['tmp_name'],
                    $files['size']
                ) ||
                !is_array($files['name']) ||
                !is_array($files['tmp_name']) ||
                !is_array($files['size']) ||
                count($files['name']) !== $count ||
                count($files['tmp_name']) !== $count ||
                count($files['size']) !== $count
            ) {
                throw new InvalidArgumentException(
                    'Invalid image upload structure.'
                );
            }

            foreach ($files['error'] as $index => $error) {
                if (!is_int($error)) {
                    throw new InvalidArgumentException(
                        'Invalid image upload error code.'
                    );
                }

                $normalized[] = [
                    'name' => $files['name'][$index],
                    'tmp_name' => $files['tmp_name'][$index],
                    'error' => $error,
                    'size' => $files['size'][$index]
                ];
            }

        } else {
            if (!is_int($files['error'])) {
                throw new InvalidArgumentException(
                    'Invalid image upload error code.'
                );
            }

            $normalized[] = [
                'name' => $files['name'] ?? '',
                'tmp_name' => $files['tmp_name'] ?? '',
                'error' => $files['error'],
                'size' => $files['size'] ?? 0
            ];
        }

        return $normalized;
    }

    /**
     * Remove stored files after a failed operation.
     */
    public function deleteFiles(array $paths): void
    {
        foreach ($paths as $path) {
            if (!is_string($path)) {
                continue;
            }

            $filename = basename($path);

            if (
                $filename === '' ||
                $filename === '.' ||
                $filename === '..'
            ) {
                continue;
            }

            $fullPath = $this->uploadDirectory
                . DIRECTORY_SEPARATOR
                . $filename;

            if (is_file($fullPath)) {
                @unlink($fullPath);
            }
        }
    }

    /**
     * Get readable PHP upload error messages.
     */
    private function getUploadErrorMessage(int $error): string
    {
        return match ($error) {
            UPLOAD_ERR_INI_SIZE,
            UPLOAD_ERR_FORM_SIZE =>
                'Uploaded image exceeds the allowed size.',

            UPLOAD_ERR_PARTIAL =>
                'Image upload was incomplete.',

            UPLOAD_ERR_NO_FILE =>
                'An uploaded image is missing.',

            UPLOAD_ERR_NO_TMP_DIR,
            UPLOAD_ERR_CANT_WRITE,
            UPLOAD_ERR_EXTENSION =>
                'Image upload failed on the server.',

            default =>
                'Unknown image upload error.'
        };
    }
}
