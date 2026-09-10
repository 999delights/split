CREATE TABLE app_users (
 id CHAR(36) PRIMARY KEY, email VARCHAR(320) NULL, display_name VARCHAR(120) NOT NULL,
 status VARCHAR(24) NOT NULL DEFAULT 'active',
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE auth_identities (
 id CHAR(36) PRIMARY KEY, user_id CHAR(36) NOT NULL,
 provider VARCHAR(32) COLLATE utf8mb4_bin NOT NULL, subject VARCHAR(255) COLLATE utf8mb4_bin NOT NULL,
 email VARCHAR(320) NULL, UNIQUE KEY identity_provider_subject(provider,subject),
 FOREIGN KEY(user_id) REFERENCES app_users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE auth_email_addresses (
 user_id CHAR(36) NOT NULL, email VARCHAR(254) NOT NULL,
 verified_at BIGINT NULL, verification_source VARCHAR(24) NOT NULL,
 PRIMARY KEY(user_id,email), UNIQUE KEY auth_email_unique(email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE auth_passwords (
 user_id CHAR(36) PRIMARY KEY, password_hash VARCHAR(255) NOT NULL, changed_at BIGINT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE auth_actions (
 token_hash CHAR(64) PRIMARY KEY, user_id CHAR(36) NOT NULL,
 email VARCHAR(254) NOT NULL, purpose VARCHAR(24) NOT NULL,
 expires_at BIGINT NOT NULL, consumed_at BIGINT NULL,
 INDEX action_user(user_id,purpose)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE auth_sessions (
 id CHAR(36) PRIMARY KEY, user_id CHAR(36) NOT NULL, token_hash CHAR(64) NOT NULL UNIQUE,
 family_id CHAR(36) NOT NULL, device_label VARCHAR(120) NOT NULL, provider VARCHAR(24) NOT NULL,
 expires_at BIGINT NOT NULL, created_at BIGINT NOT NULL, consumed_at BIGINT NULL, revoked_at BIGINT NULL,
 INDEX session_family(family_id), INDEX session_user(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE auth_challenges (
 nonce_hash CHAR(64) PRIMARY KEY, expires_at BIGINT NOT NULL, consumed_at BIGINT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE auth_rate_buckets (
 bucket CHAR(64) PRIMARY KEY, attempts INT NOT NULL, expires_at BIGINT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE auth_email_outbox (
 id CHAR(36) PRIMARY KEY, user_id CHAR(36) NOT NULL, recipient VARCHAR(254) NOT NULL,
 template VARCHAR(64) NOT NULL, payload_encrypted TEXT NOT NULL,
 dedupe_key VARCHAR(191) NOT NULL UNIQUE, status VARCHAR(24) NOT NULL,
 attempts INT NOT NULL, next_attempt_at BIGINT NOT NULL, created_at BIGINT NOT NULL,
 lease_until BIGINT NULL, sent_at BIGINT NULL, error_code VARCHAR(64) NULL,
 INDEX email_ready(status,next_attempt_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE auth_security_events (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, user_id CHAR(36) NOT NULL,
 event_type VARCHAR(64) NOT NULL, provider VARCHAR(24) NULL, created_at BIGINT NOT NULL,
 INDEX security_user(user_id,created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
ALTER TABLE auth_email_addresses ADD CONSTRAINT fk_auth_email_addresses_user FOREIGN KEY(user_id) REFERENCES app_users(id);
ALTER TABLE auth_passwords ADD CONSTRAINT fk_auth_passwords_user FOREIGN KEY(user_id) REFERENCES app_users(id);
ALTER TABLE auth_actions ADD CONSTRAINT fk_auth_actions_user FOREIGN KEY(user_id) REFERENCES app_users(id);
ALTER TABLE auth_sessions ADD CONSTRAINT fk_auth_sessions_user FOREIGN KEY(user_id) REFERENCES app_users(id);
ALTER TABLE auth_email_outbox ADD CONSTRAINT fk_auth_email_outbox_user FOREIGN KEY(user_id) REFERENCES app_users(id);
ALTER TABLE auth_security_events ADD CONSTRAINT fk_auth_security_events_user FOREIGN KEY(user_id) REFERENCES app_users(id);
