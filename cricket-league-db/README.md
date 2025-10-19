# Cricket League Database

This directory contains the complete database schema for the Cricket League application.

## Setup Instructions

1. **Create the database:**
   ```sql
   CREATE DATABASE cricket_league CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```

2. **Import the complete schema:**
   ```bash
   mysql -u root -p cricket_league < complete_schema.sql
   ```

3. **Verify the setup:**
   ```sql
   USE cricket_league;
   SHOW TABLES;
   ```

## Schema Files

- `complete_schema.sql` - Complete database schema with all tables, indexes, constraints, and test data
- `schema.sql` - Legacy schema file (kept for reference)

## Features Included

- **User Management**: Authentication, refresh tokens, password resets
- **Team Management**: Teams, players, captain/vice-captain assignments
- **Tournament System**: Tournaments, team registrations, match scheduling
- **Match Management**: Live scoring, ball-by-ball tracking, statistics
- **Security**: Rate limiting, auth failure tracking, feedback system
- **Performance**: Optimized indexes for all major queries

## Test Data

The schema includes test data:
- Test user: `12345678` / `12345678`
- Test team: "Test Warriors" with 5 sample players

## Database Requirements

- MySQL 5.7+ or MariaDB 10.2+
- UTF8MB4 character set support
- InnoDB storage engine
