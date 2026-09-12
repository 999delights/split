-- Account/Admin contract v1. Additive; execute through the checksum migration runner.
ALTER TABLE app_users ADD COLUMN last_login_at DATETIME NULL;
ALTER TABLE auth_identities ADD COLUMN created_at DATETIME NULL, ADD COLUMN last_login_at DATETIME NULL;
ALTER TABLE auth_identities ADD COLUMN email_verified BOOLEAN NULL;
CREATE TABLE user_devices (
 id CHAR(36) PRIMARY KEY, user_id CHAR(36) NOT NULL,
 installation_id CHAR(36) NOT NULL, platform VARCHAR(32) NOT NULL,
 name VARCHAR(120) NULL, model VARCHAR(120) NULL, app_version VARCHAR(40) NULL,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 last_seen_at DATETIME NULL, revoked_at DATETIME NULL,
 UNIQUE KEY device_owner(id,user_id), UNIQUE KEY user_installation(user_id,installation_id),
 FOREIGN KEY(user_id) REFERENCES app_users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
ALTER TABLE auth_sessions ADD COLUMN device_id CHAR(36) NULL,
 ADD CONSTRAINT auth_session_device FOREIGN KEY(device_id,user_id) REFERENCES user_devices(id,user_id);
ALTER TABLE auth_actions ADD COLUMN pending_password_hash VARCHAR(255) NULL;
ALTER TABLE auth_email_addresses ADD COLUMN confirmed_at BIGINT NULL;
CREATE TABLE auth_email_templates (
 template_key VARCHAR(64) PRIMARY KEY, subject VARCHAR(200) NOT NULL, body TEXT NOT NULL,
 revision INT NOT NULL, updated_at BIGINT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE auth_template_revisions (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, template_key VARCHAR(64) NOT NULL,
 revision INT NOT NULL, subject VARCHAR(200) NOT NULL, body TEXT NOT NULL,
 updated_at BIGINT NOT NULL, actor VARCHAR(120) NOT NULL,
 UNIQUE KEY template_revision(template_key,revision)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
ALTER TABLE app_users ADD COLUMN last_login_provider VARCHAR(24) NULL;
