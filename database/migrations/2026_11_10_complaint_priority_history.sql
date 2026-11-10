-- Phase 7: retain an audit trail for administrator priority changes.
-- Verify the deployed base schema uses BIGINT UNSIGNED ids before applying.
CREATE TABLE complaint_priority_history (
    priority_history_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    complaint_id BIGINT UNSIGNED NOT NULL,
    changed_by BIGINT UNSIGNED NOT NULL,
    old_priority VARCHAR(10) NOT NULL,
    new_priority VARCHAR(10) NOT NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (priority_history_id),
    INDEX idx_priority_history_complaint (complaint_id, changed_at),
    INDEX idx_priority_history_admin (changed_by),
    CONSTRAINT fk_priority_history_complaint
        FOREIGN KEY (complaint_id) REFERENCES complaints(complaint_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_priority_history_admin
        FOREIGN KEY (changed_by) REFERENCES users(user_id)
        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
