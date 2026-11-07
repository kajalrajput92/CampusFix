
-- CampusFix Password Recovery Migration
-- Date: 2026-11-05

-- Add token version for JWT session invalidation.
ALTER TABLE users
ADD COLUMN token_version INT UNSIGNED NOT NULL DEFAULT 0;

-- Store hashed, one-time password reset tokens.
CREATE TABLE IF NOT EXISTS password_resets (
    reset_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,
    token_hash CHAR(64) NOT NULL,
    expires_at DATETIME NOT NULL,
    used_at DATETIME DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (reset_id),
    UNIQUE KEY uq_password_reset_token (token_hash),
    INDEX idx_password_reset_user (user_id),
    INDEX idx_password_reset_expiry (expires_at),

    CONSTRAINT fk_password_reset_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;
