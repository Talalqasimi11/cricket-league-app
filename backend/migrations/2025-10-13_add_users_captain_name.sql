-- Add captain_name to users table for display purposes
ALTER TABLE users ADD COLUMN captain_name VARCHAR(100) NULL AFTER password_hash;
