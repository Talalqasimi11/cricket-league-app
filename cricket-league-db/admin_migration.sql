-- Migration to add admin support to existing cricket_league database
-- Run this script to add admin functionality to an existing database

-- Add is_admin column to users table
ALTER TABLE users ADD COLUMN is_admin BOOLEAN DEFAULT FALSE;

-- Create an admin user (optional - for testing)
-- Replace 'admin_phone' and 'admin_password' with your desired admin credentials
-- INSERT INTO users (phone_number, password_hash, is_admin) VALUES 
-- ('admin_phone', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMeshCSR5P4BYq7s8J4xrV8KDe', TRUE);

-- Note: The password hash above is for 'password123' - change this in production!
