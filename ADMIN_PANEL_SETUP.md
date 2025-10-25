# Cricket League Admin Panel Setup Guide

This guide will help you set up and use the new admin panel for the Cricket League application.

## Overview

The admin panel is a separate React web application that provides administrative functionality for managing users and teams in the Cricket League system.

## File Structure

```
cricket-league-app/
├── admin-panel/                 # New React admin panel
│   ├── public/
│   ├── src/
│   │   ├── components/         # React components
│   │   ├── services/           # API service layer
│   │   └── App.js              # Main app component
│   ├── package.json
│   └── README.md
├── backend/                     # Existing Node.js backend
│   ├── controllers/
│   │   └── adminController.js  # New admin controller
│   ├── middleware/
│   │   └── authMiddleware.js    # Updated with admin support
│   ├── routes/
│   │   └── adminRoutes.js       # New admin routes
│   └── index.js                 # Updated to mount admin routes
└── cricket-league-db/
    ├── complete_schema.sql       # Updated with admin support
    └── admin_migration.sql      # Migration for existing databases
```

## Backend Changes Made

### 1. Database Schema Updates

**File: `cricket-league-db/complete_schema.sql`**
- Added `is_admin BOOLEAN DEFAULT FALSE` column to users table

**File: `cricket-league-db/admin_migration.sql`**
- Migration script for existing databases
- Adds admin column to existing users table

### 2. Authentication Updates

**File: `backend/controllers/authController.js`**
- Updated JWT payload to include admin roles and scopes
- Modified login, registration, and refresh token functions
- Admin users get additional roles and scopes

**File: `backend/middleware/authMiddleware.js`**
- Added `requireAdmin` middleware function
- Checks for 'admin' role in JWT token

### 3. New Admin API

**File: `backend/controllers/adminController.js`**
- Dashboard statistics
- User management (list, update admin status, delete)
- Team management (list, view details, edit, delete)

**File: `backend/routes/adminRoutes.js`**
- Protected admin routes under `/api/admin`
- All routes require authentication and admin role

**File: `backend/index.js`**
- Mounted admin routes at `/api/admin`

## Frontend Admin Panel

### Features

1. **Admin Login**
   - Secure authentication with JWT tokens
   - Role-based access control
   - Automatic logout on token expiration

2. **Dashboard**
   - System statistics overview
   - Quick action cards
   - Real-time data

3. **User Management**
   - List all users with admin status
   - Grant/revoke admin privileges
   - Delete users (with safety checks)
   - View user details and team associations

4. **Team Management**
   - List all teams with statistics
   - View detailed team information including players
   - Edit team details (name, location, logo)
   - Delete teams (with safety checks)

### Technology Stack

- **React 18** with functional components and hooks
- **Tailwind CSS** for styling (via CDN)
- **Axios** for API communication
- **Local Storage** for token persistence

## Setup Instructions

### 1. Database Setup

For **new installations**:
```sql
-- Use the updated complete_schema.sql
-- The is_admin column is already included
```

For **existing installations**:
```sql
-- Run the migration script
source cricket-league-db/admin_migration.sql
```

### 2. Create Admin User

**Option A: Via Database**
```sql
-- Update existing user to admin
UPDATE users SET is_admin = TRUE WHERE phone_number = 'your_admin_phone';

-- Or create new admin user
INSERT INTO users (phone_number, password_hash, is_admin) 
VALUES ('admin_phone', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMeshCSR5P4BYq7s8J4xrV8KDe', TRUE);
```

**Option B: Via Admin Panel**
1. Register a regular user through the mobile app
2. Use the admin panel to grant admin privileges

### 3. Backend Setup

1. Ensure all backend dependencies are installed
2. Start the backend server:
```bash
cd backend
npm start
```

The backend will now serve admin routes at `/api/admin/*`

### 4. Admin Panel Setup

1. Navigate to the admin panel directory:
```bash
cd admin-panel
```

2. Install dependencies:
```bash
npm install
```

3. Create environment file:
```bash
# Create .env file
echo "REACT_APP_API_URL=http://localhost:5000/api" > .env
```

4. Start the development server:
```bash
npm start
```

The admin panel will be available at `http://localhost:3000`

## Usage

### 1. Admin Login

1. Open the admin panel in your browser
2. Use your admin phone number and password
3. The system will verify admin privileges and grant access

### 2. Dashboard

- View system statistics
- Monitor user and team counts
- Quick access to management features

### 3. User Management

- **View Users**: See all registered users with their admin status
- **Grant Admin**: Click "Make Admin" to grant admin privileges
- **Remove Admin**: Click "Remove Admin" to revoke admin privileges
- **Delete User**: Remove users (admins cannot delete themselves)

### 4. Team Management

- **View Teams**: See all teams with statistics
- **Team Details**: Click "View" to see team information and players
- **Edit Team**: Click "Edit" to modify team name, location, or logo
- **Delete Team**: Remove teams (with safety checks for matches)

## Security Features

1. **Authentication Required**: All admin routes require valid JWT tokens
2. **Role-Based Access**: Only users with 'admin' role can access admin features
3. **Self-Protection**: Admins cannot remove their own admin status or delete themselves
4. **Data Validation**: Server-side validation for all admin operations
5. **Error Handling**: Comprehensive error handling and user feedback

## API Endpoints

### Dashboard
- `GET /api/admin/dashboard` - Get system statistics

### User Management
- `GET /api/admin/users` - List all users
- `PUT /api/admin/users/:id/admin` - Update user admin status
- `DELETE /api/admin/users/:id` - Delete user

### Team Management
- `GET /api/admin/teams` - List all teams
- `GET /api/admin/teams/:id` - Get team details
- `PUT /api/admin/teams/:id` - Update team
- `DELETE /api/admin/teams/:id` - Delete team

## Troubleshooting

### Common Issues

1. **"Admin access required" error**
   - Ensure the user has admin privileges in the database
   - Check that `is_admin = TRUE` for the user

2. **CORS errors**
   - Ensure the backend CORS configuration includes the admin panel URL
   - Add `http://localhost:3000` to CORS_ORIGINS if needed

3. **API connection errors**
   - Verify the backend server is running
   - Check the REACT_APP_API_URL environment variable
   - Ensure the API endpoints are accessible

4. **Token expiration**
   - The admin panel will automatically logout on token expiration
   - Re-login to continue using the panel

### Development Tips

1. **Testing Admin Features**
   - Create test users through the mobile app
   - Grant admin privileges via the admin panel
   - Test different user scenarios

2. **Database Monitoring**
   - Monitor the `users` table for admin status changes
   - Check the `teams` table for team modifications

3. **API Testing**
   - Use browser developer tools to monitor API calls
   - Check network tab for authentication headers
   - Verify JWT token payload in browser storage

## Production Deployment

### Backend
1. Ensure all environment variables are set
2. Run database migrations
3. Deploy with proper CORS configuration
4. Set up SSL certificates for secure communication

### Admin Panel
1. Build the React app: `npm run build`
2. Serve the built files from a web server
3. Configure environment variables for production API URL
4. Set up proper authentication and security headers

## Support

For issues or questions:
1. Check the browser console for JavaScript errors
2. Verify backend logs for API errors
3. Ensure database connectivity and permissions
4. Test API endpoints directly using tools like Postman

The admin panel provides a comprehensive interface for managing the Cricket League system with proper security and user experience considerations.
