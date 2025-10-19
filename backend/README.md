# Cricket League App - Backend

A Node.js/Express backend API for managing cricket leagues, tournaments, and live scoring.

## Getting Started

### Prerequisites

- Node.js (v16 or higher)
- MySQL database
- npm or yarn package manager

### Installation

1. Clone the repository
2. Navigate to the backend directory
3. Install dependencies:
   ```bash
   npm install
   ```
4. Set up environment variables (see Environment Variables section)
5. Run database migrations:
   ```bash
   npm run migrate
   ```
6. Start the server:
   ```bash
   npm start
   ```

The server will start on `http://localhost:5000` by default.

## Environment Variables (Backend)

Create a `.env` file in the backend directory with the following variables:

```env
# Database Configuration
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=cricket_league

# Server Configuration
PORT=5000
NODE_ENV=development
APP_VERSION=1.0.0

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-this-in-production
JWT_ISS=your-app-name
JWT_AUD=your-app-audience

# Security Configuration
ALLOW_REFRESH_IN_BODY=false  # Set to true for mobile clients
RETURN_RESET_TOKEN_IN_BODY=false  # Set to true for development only
COOKIE_SECURE=true  # Set to true in production with HTTPS
LOG_LEVEL=info  # Set to debug for detailed logging

# Rate Limiting (format: max_requests/window_seconds)
REGISTER_RATE_LIMIT=10/3600  # 10 per hour
LOGIN_RATE_LIMIT=10/900      # 10 per 15 minutes
FORGOT_RATE_LIMIT=5/900      # 5 per 15 minutes
CHANGE_RATE_LIMIT=10/900     # 10 per 15 minutes

# CORS Configuration (Development)
# Add your computer's IP address when testing on physical devices
# Example: http://192.168.1.100:5000
# Find your IP: Windows (ipconfig), macOS/Linux (ifconfig)
CORS_ORIGINS=http://localhost:3000,http://localhost:5000,http://localhost:8080,http://127.0.0.1:5000,http://127.0.0.1:8080,http://10.0.2.2:5000

# Profanity Filter Configuration (Optional)
PROFANITY_FILTER_ENABLED=false
PROFANITY_FILTER=spam,scam,fake,bot
```

### Profanity Filter Configuration

The feedback system includes an optional profanity filter to prevent inappropriate content:

**Configuration Options:**
- `PROFANITY_FILTER_ENABLED=true` - Enable the profanity filter (default: false)
- `PROFANITY_FILTER=word1,word2,word3` - Comma-separated list of words to filter

**Security Notes:**
- By default, the profanity filter is disabled for privacy
- If enabled without `PROFANITY_FILTER` set, uses a sanitized default list
- The filter uses word boundaries to avoid false positives
- Configure your own word list via environment variables, not in code

### CORS Configuration Details

The backend uses a strict CORS policy for security. The `CORS_ORIGINS` environment variable must include ALL origins from which the frontend will connect.

**Important Notes:**
- In development mode, common localhost origins are auto-added if `CORS_ORIGINS` is empty
- In production, `CORS_ORIGINS` is required and must be explicitly set
- Each origin must be a complete URL (e.g., `http://192.168.1.100:5000`)
- Origins are comma-separated with no spaces around commas

### Testing on Physical Devices

When testing the app on physical Android/iOS devices, you need to add your computer's IP address to the CORS origins.

#### Finding Your Computer's IP Address

**Windows:**
1. Open Command Prompt
2. Run `ipconfig`
3. Look for "IPv4 Address" under your active network adapter

**macOS:**
1. Open Terminal
2. Run `ifconfig | grep inet`
3. Look for the IP address (usually starts with 192.168.x.x or 10.x.x.x)

**Linux:**
1. Open Terminal
2. Run `ip addr show` or `hostname -I`
3. Look for the IP address

#### Adding Device Origin to CORS

1. Find your computer's IP address (e.g., `192.168.1.100`)
2. Add `http://YOUR_IP:5000` to the `CORS_ORIGINS` in your `.env` file
3. Restart the backend server

**Example:**
```env
CORS_ORIGINS=http://localhost:3000,http://localhost:5000,http://localhost:8080,http://127.0.0.1:5000,http://127.0.0.1:8080,http://10.0.2.2:5000,http://192.168.1.100:5000
```

## Troubleshooting Frontend-Backend Communication

### Common Issues and Solutions

#### 1. CORS Errors
**Error:** "Not allowed by CORS" or "Access to fetch at 'http://...' from origin 'http://...' has been blocked by CORS policy"

**Solution:**
1. Add the frontend origin to `CORS_ORIGINS` in `.env` file
2. Restart the backend server
3. Clear browser cache if testing on web

#### 2. Connection Refused
**Error:** "Connection refused" or "Network is unreachable"

**Solutions:**
- **Backend not running**: Start the server with `npm start`
- **Wrong port**: Ensure the server is running on port 5000 (or check PORT in .env)
- **Firewall blocking**: Allow port 5000 through Windows Firewall or macOS Security
- **Wrong IP address**: Verify the IP address is correct and both devices are on the same network

#### 3. Network Unreachable
**Error:** "Network is unreachable" on physical devices

**Solutions:**
- Ensure both device and computer are on the same WiFi network
- Check that the computer's IP address is correct
- Verify the backend is accessible from the computer first

#### 4. 401 Unauthorized
**Error:** "401 Unauthorized" responses

**Note:** This is an authentication issue, not a connection issue. The backend is reachable but the request lacks valid authentication.

### Testing Backend Accessibility

#### From Your Computer
```bash
# Test basic connectivity
curl http://localhost:5000/health

# Expected response:
{"status":"ok","version":"dev","db":"up"}
```

#### From Physical Device
```bash
# Replace with your computer's IP
curl http://192.168.1.100:5000/health

# Expected response:
{"status":"ok","version":"dev","db":"up"}
```

#### Using Browser
Open `http://localhost:5000/health` in your browser. You should see a JSON response with status information.

### Checking CORS Headers

Use browser developer tools to check CORS headers:

1. Open browser developer tools (F12)
2. Go to Network tab
3. Make a request from the frontend
4. Look for the `Access-Control-Allow-Origin` header in the response
5. Verify it matches your frontend's origin

### Debugging Steps

1. **Verify backend is running:**
   ```bash
   curl http://localhost:5000/health
   ```

2. **Check CORS configuration:**
   - Look at server startup logs for "CORS allowed origins"
   - Verify your origin is in the list

3. **Test from device:**
   ```bash
   curl http://YOUR_IP:5000/health
   ```

4. **Check firewall settings:**
   - Windows: Windows Defender Firewall
   - macOS: System Preferences > Security & Privacy > Firewall
   - Linux: `sudo ufw status`

5. **Verify network connectivity:**
   - Both devices on same WiFi
   - No VPN interfering
   - No corporate firewall blocking

## API Endpoints

### Health Check
- `GET /health` - Server health and database status

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh` - Token refresh
- `POST /api/auth/logout` - User logout
- `PUT /api/auth/change-password` - Change password
- `PUT /api/auth/change-phone` - Change phone number

### Teams
- `GET /api/teams` - List teams
- `POST /api/teams` - Create team
- `GET /api/teams/:id` - Get team details
- `PUT /api/teams/:id` - Update team
- `DELETE /api/teams/:id` - Delete team

### Tournaments
- `GET /api/tournaments` - List tournaments
- `POST /api/tournaments` - Create tournament
- `GET /api/tournaments/:id` - Get tournament details
- `PUT /api/tournaments/:id` - Update tournament

### Tournament Teams
- `POST /api/tournament-teams` - Add team to tournament
- `GET /api/tournament-teams/:tournament_id` - Get tournament teams
- `PUT /api/tournament-teams` - Update tournament team (extended functionality)
- `DELETE /api/tournament-teams` - Remove tournament team (extended functionality)

### Matches
- `GET /api/tournament-matches` - List matches
- `POST /api/tournament-matches` - Create match
- `GET /api/tournament-matches/:id` - Get match details
- `PUT /api/tournament-matches/:id` - Update match

### Live Scoring
- `POST /api/live/start` - Start live scoring
- `POST /api/live/ball` - Record ball
- `GET /api/live/:matchId` - Get live score
- `POST /api/live/end` - End live scoring

## Development

### Project Structure

```
backend/
├── config/              # Database and environment configuration
├── controllers/         # Request handlers
├── middleware/          # Custom middleware (auth, etc.)
├── migrations/          # Database migration files
├── routes/             # API route definitions
├── scripts/            # Utility scripts
├── __tests__/          # Test files
├── index.js            # Main server file
└── package.json        # Dependencies and scripts
```

### Running Tests

```bash
# Run all tests
npm test

# Run tests with coverage
npm run test:coverage

# Run specific test file
npm test -- auth.test.js
```

### Database Migrations

```bash
# Run migrations
npm run migrate

# Create new migration
npm run migrate:create migration_name

# Rollback last migration
npm run migrate:rollback
```

## Production Deployment

### Environment Setup

1. Set `NODE_ENV=production`
2. Configure production database
3. Set strong JWT secrets
4. Configure CORS_ORIGINS with production domains
5. Set up SSL/TLS certificates

### Security Considerations

- Use strong, unique JWT secrets
- Configure proper CORS origins for production
- Enable rate limiting
- Use HTTPS in production
- Regularly update dependencies
- Monitor logs for suspicious activity

### Security Features

The backend implements comprehensive security measures:

#### Authentication & Authorization
- JWT-based authentication with short-lived access tokens (15 minutes)
- Long-lived refresh tokens (7 days) stored securely
- Role-based access control with captain permissions
- Progressive lockout: 3→1m, 5→5m, 10→30m delays
- IP-based throttling to prevent distributed attacks

#### Token Security
- Refresh tokens in httpOnly cookies (web) or request body (mobile)
- CSRF protection for cookie-based refresh
- Token rotation on refresh (configurable)
- Secure cookie flags (HttpOnly, Secure, SameSite)

#### Rate Limiting
- Configurable rate limits via environment variables
- Different limits for different endpoints
- Standard rate limit headers with Retry-After

#### Data Protection
- Password reset tokens only returned in development
- Sensitive data redacted from logs
- Audit trail for authentication failures
- Secure password hashing with bcrypt

#### Environment-Specific Security
- Development: More lenient limits, debug logging
- Production: Strict limits, minimal logging, secure cookies
- Test: Isolated database, comprehensive test coverage

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review the frontend README for client-side configuration
3. Check server logs for detailed error information
4. Verify database connectivity and migrations
