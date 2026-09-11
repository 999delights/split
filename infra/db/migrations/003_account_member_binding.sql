ALTER TABLE split_group_users ADD COLUMN member_id VARCHAR(191) NULL;
ALTER TABLE split_group_users ADD CONSTRAINT fk_split_user_member FOREIGN KEY(member_id) REFERENCES split_members(id);
CREATE UNIQUE INDEX split_member_account ON split_group_users(member_id);
