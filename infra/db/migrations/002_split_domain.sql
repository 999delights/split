CREATE TABLE split_profiles (
 id CHAR(36) PRIMARY KEY, nickname VARCHAR(120) NOT NULL,
 FOREIGN KEY(id) REFERENCES app_users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE split_groups (
 id VARCHAR(191) PRIMARY KEY, name VARCHAR(120) NOT NULL, icon INT NOT NULL,
 currency VARCHAR(3) NOT NULL, created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE split_group_users (
 group_id VARCHAR(191) NOT NULL,user_id CHAR(36) NOT NULL,role VARCHAR(20) NOT NULL,
 PRIMARY KEY(group_id,user_id), FOREIGN KEY(group_id) REFERENCES split_groups(id),
 FOREIGN KEY(user_id) REFERENCES app_users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE split_members (
 id VARCHAR(191) PRIMARY KEY,group_id VARCHAR(191) NOT NULL,name VARCHAR(120) NOT NULL,
 FOREIGN KEY(group_id) REFERENCES split_groups(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE split_expenses (
 id VARCHAR(191) PRIMARY KEY,group_id VARCHAR(191) NOT NULL,name VARCHAR(120) NOT NULL,
 amount BIGINT NOT NULL,payer VARCHAR(191) NOT NULL,created VARCHAR(40) NOT NULL,
 FOREIGN KEY(group_id) REFERENCES split_groups(id),FOREIGN KEY(payer) REFERENCES split_members(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE split_shares (
 expense_id VARCHAR(191) NOT NULL,member_id VARCHAR(191) NOT NULL,amount BIGINT NOT NULL,
 PRIMARY KEY(expense_id,member_id),FOREIGN KEY(expense_id) REFERENCES split_expenses(id) ON DELETE CASCADE,
 FOREIGN KEY(member_id) REFERENCES split_members(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE split_settlements (
 id VARCHAR(191) PRIMARY KEY,group_id VARCHAR(191) NOT NULL,sender VARCHAR(191) NOT NULL,
 receiver VARCHAR(191) NOT NULL,amount BIGINT NOT NULL,created VARCHAR(40) NOT NULL,
 FOREIGN KEY(group_id) REFERENCES split_groups(id),FOREIGN KEY(sender) REFERENCES split_members(id),
 FOREIGN KEY(receiver) REFERENCES split_members(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE split_group_legacy_metadata (
 group_id VARCHAR(191) PRIMARY KEY,color VARCHAR(80),profile_pic VARCHAR(120),date_json TEXT,
 FOREIGN KEY(group_id) REFERENCES split_groups(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE split_imports (
 source_hash CHAR(64) PRIMARY KEY,user_id CHAR(36) NOT NULL,counts_json JSON NOT NULL,
 imported_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),FOREIGN KEY(user_id) REFERENCES app_users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
