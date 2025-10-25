# Cricket League Admin Panel

A React-based web admin panel for managing the Cricket League application.

## Features

- **Admin Authentication**: Secure login with JWT tokens
- **Dashboard**: Overview of system statistics
- **User Management**: View users, grant/revoke admin privileges, delete users
- **Team Management**: View teams, edit team details, delete teams

## Setup

1. Install dependencies:
```bash
npm install
```

2. Set environment variables:
```bash
# Create .env file
REACT_APP_API_URL=http://localhost:5000/api
```

3. Start the development server:
```bash
npm start
```

## Backend Requirements

The admin panel requires the backend to be running with admin routes enabled. Make sure:

1. Database has been updated with admin support (run the migration)
2. At least one user has been granted admin privileges
3. Backend server is running on the configured API URL

## Admin User Setup

To create an admin user, you can either:

1. **Via Database**: Update an existing user's `is_admin` field to `TRUE`
2. **Via API**: Use the admin panel to grant admin privileges to a user

## Security

- All admin routes require authentication and admin role
- JWT tokens are stored in localStorage
- Automatic logout on token expiration or invalid permissions
- CSRF protection for sensitive operations

## API Endpoints

The admin panel uses the following API endpoints:

- `GET /api/admin/dashboard` - Dashboard statistics
- `GET /api/admin/users` - List all users
- `PUT /api/admin/users/:id/admin` - Update user admin status
- `DELETE /api/admin/users/:id` - Delete user
- `GET /api/admin/teams` - List all teams
- `GET /api/admin/teams/:id` - Get team details
- `PUT /api/admin/teams/:id` - Update team
- `DELETE /api/admin/teams/:id` - Delete team
