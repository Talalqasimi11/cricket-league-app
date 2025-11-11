# Technical Context - Cricket League Management Application

## Technology Stack

### Frontend (Mobile Application)
- **Framework**: Flutter 3.x
- **Language**: Dart
- **Platform Support**: iOS 12+, Android API 21+
- **State Management**: Provider pattern
- **Local Storage**: flutter_secure_storage for tokens, Hive for offline data
- **Networking**: Dio HTTP client with interceptors
- **WebSocket**: socket_io_client for real-time updates
- **Image Handling**: cached_network_image for efficient loading

### Backend (API Server)
- **Runtime**: Node.js 18.18.0+
- **Framework**: Express.js 5.1.0
- **Language**: JavaScript (ES6+)
- **Real-time**: Socket.IO 4.8.1 with Redis adapter
- **Database**: mysql2 3.6.5 with connection pooling
- **Authentication**: jsonwebtoken 9.0.2
- **Password Hashing**: bcryptjs 2.4.3
- **Rate Limiting**: express-rate-limit 7.4.0
- **Logging**: pino-http 10.3.0
- **CORS**: cors 2.8.5
- **File Upload**: multer 1.4.5-lts.1 with Sharp 0.33.0

### Admin Panel (Web Application)
- **Framework**: React.js 18.x
- **Build Tool**: Create React App
- **State Management**: React Hooks + Context API
- **Styling**: Tailwind CSS
- **HTTP Client**: Axios with interceptors
- **Charts**: Chart.js/Recharts for analytics
- **Notifications**: Toast notifications
- **Routing**: React Router

### Database
- **Engine**: MySQL 8.0+ (PlanetScale-compatible)
- **ORM**: Raw SQL with parameterized queries
- **Connection Pooling**: mysql2 connection pool (10 connections)
- **Migrations**: Custom migration system with lexicographic ordering
- **Backup**: PlanetScale automated backups

### DevOps & Deployment
- **Version Control**: Git with GitHub
- **CI/CD**: GitHub Actions (planned)
- **Containerization**: Docker (planned)
- **Hosting**: Backend on Railway/Vercel, Database on PlanetScale
- **Monitoring**: Basic health checks, Pino logging
- **Environment**: Development/Staging/Production separation

## Development Setup

### Prerequisites
- **Node.js**: 18.18.0+ (LTS)
- **Flutter**: 3.x with Dart SDK
- **MySQL**: 8.0+ or PlanetScale account
- **Git**: 2.x+
- **VS Code**: With Flutter and Dart extensions

### Local Development Environment
```bash
# Backend setup
cd backend
npm install
cp .env.example .env  # Configure environment variables
npm run dev  # Development server with hot reload

# Frontend setup
cd frontend
flutter pub get
flutter run  # iOS simulator or Android emulator

# Admin panel setup
cd admin-panel
npm install
npm start  # Development server on port 3000

# Database setup
cd cricket-league-db
mysql -u root -p < schema.sql  # Local MySQL
# OR use PlanetScale for cloud database
```

### Environment Configuration
**Required Variables:**
- `DB_HOST`, `DB_USER`, `DB_PASS`, `DB_NAME`: Database connection
- `JWT_SECRET`, `JWT_REFRESH_SECRET`: 32+ character secrets
- `JWT_AUD`, `JWT_ISS`: JWT configuration
- `CORS_ORIGINS`: Comma-separated allowed origins

**Optional Variables:**
- `PORT`: Server port (default: 5000)
- `NODE_ENV`: Environment mode
- `COOKIE_SECURE`: HTTPS-only cookies
- `UPLOAD_PATH`: File upload directory

## Technical Constraints

### Platform Limitations
- **iOS Minimum**: iOS 12.0 (Flutter requirement)
- **Android Minimum**: API level 21 (Android 5.0)
- **Browser Support**: Modern browsers with ES6+ support
- **Network**: Graceful degradation for poor connectivity

### Performance Constraints
- **API Response Time**: <500ms (p95)
- **WebSocket Latency**: <400ms for scoring updates
- **Mobile App Size**: <50MB (acceptable for cricket app)
- **Database Connections**: 10 connection pool limit

### Security Constraints
- **JWT Expiry**: Access tokens (15 min), refresh tokens (7 days)
- **Password Requirements**: Minimum 8 characters, bcrypt 12 rounds
- **Rate Limiting**: 10 requests/15min for auth, 20/hour for registration
- **File Upload**: 5MB limit, JPEG/PNG/WebP only

### Scalability Constraints
- **Stateless Design**: No server-side sessions
- **Database Load**: Optimized queries with proper indexing
- **WebSocket Scaling**: Redis adapter for multi-instance support
- **File Storage**: Local filesystem (upgrade to cloud storage planned)

## Dependencies & Libraries

### Core Dependencies
```
Backend:
- express: ^5.1.0
- mysql2: ^3.6.5
- jsonwebtoken: ^9.0.2
- bcryptjs: ^2.4.3
- socket.io: ^4.8.1
- multer: ^1.4.5-lts.1
- sharp: ^0.33.0

Frontend:
- flutter: sdk
- provider: ^6.0.5
- dio: ^5.3.2
- socket_io_client: ^2.0.3
- hive: ^2.2.3
- flutter_secure_storage: ^9.0.0

Admin Panel:
- react: ^18.2.0
- axios: ^1.6.0
- tailwindcss: ^3.3.0
- chart.js: ^4.4.0
```

### Development Dependencies
```
Backend:
- jest: ^29.7.0
- supertest: ^6.3.3
- nodemon: ^3.0.1

Frontend:
- flutter_test: sdk
- mockito: ^5.4.4

Admin Panel:
- @testing-library/react: ^14.1.2
- cypress: ^13.6.0
```

## Tool Usage Patterns

### Code Quality Tools
- **ESLint**: JavaScript linting with React and Node.js rules
- **Dart Analyzer**: Flutter code analysis
- **Prettier**: Code formatting for consistent style
- **Jest**: Unit testing framework
- **Flutter Test**: Widget testing framework

### Development Workflow
- **Git Flow**: Feature branches with PR reviews
- **Commit Messages**: Conventional commits format
- **Code Reviews**: Required for all changes
- **Testing**: Unit tests for business logic, integration tests for APIs
- **Documentation**: Inline comments and README updates

### Debugging Tools
- **Flutter DevTools**: Performance profiling and widget inspection
- **Chrome DevTools**: Network and JavaScript debugging
- **MySQL Workbench**: Database query analysis and optimization
- **Postman**: API testing and documentation
- **React DevTools**: Component hierarchy and state inspection

## API Design & Usage

### REST API Structure
```
Authentication:
/api/auth/register (POST)
/api/auth/login (POST)
/api/auth/refresh (POST)
/api/auth/logout (POST)

Teams:
/api/teams (GET, POST)
/api/teams/my-team (GET)
/api/teams/:id (PUT, DELETE)

Tournaments:
/api/tournaments (GET, POST)
/api/tournaments/:id (PUT, DELETE)

Matches:
/api/tournament-matches (POST)
/api/tournament-matches/:id (GET, PUT)

Live Scoring:
/api/live/start-innings (POST)
/api/live/add-ball (POST)
/api/live/end-innings (POST)
/api/live/:matchId (GET)
```

### WebSocket Events
```
Client → Server:
- subscribe: { matchId }
- unsubscribe: { matchId }

Server → Client:
- scoreUpdate: { matchId, innings, players, status }
- inningsEnded: { matchId, inningsId, reason }
- matchFinalized: { matchId, winner, finalScores }
- error: { message, code }
```

### Response Format Standards
```json
Success Response:
{
  "success": true,
  "message": "Operation successful",
  "data": { ... },
  "timestamp": "2025-11-06T12:00:00.000Z"
}

Error Response:
{
  "success": false,
  "error": {
    "message": "User-friendly error message",
    "code": "ERROR_CODE",
    "type": "validation|auth|server",
    "validation": { "field": "error message" },
    "timestamp": "2025-11-06T12:00:00.000Z"
  }
}
```

## Database Schema & Relationships

### Core Tables
- **users**: User accounts and authentication
- **teams**: Cricket teams with statistics
- **players**: Team players with roles and stats
- **tournaments**: Tournament definitions and settings
- **tournament_teams**: Many-to-many tournament participation
- **matches**: Match records with scheduling
- **match_innings**: Innings data with scoring
- **ball_by_ball**: Individual ball records
- **player_match_stats**: Player performance per match

### Key Relationships
- User (1) → Team (1): Owner relationship
- Team (1) → Players (N): Team roster
- Tournament (1) → Matches (N): Tournament fixtures
- Match (1) → Innings (2): Match innings
- Innings (1) → Balls (N): Ball-by-ball records
- Player (1) → Match Stats (N): Performance tracking

### Indexing Strategy
- Primary keys on all tables
- Foreign key indexes for joins
- Composite indexes on frequently filtered columns
- Full-text indexes for search functionality

## Testing Strategy

### Unit Testing
- **Backend**: Jest with supertest for API testing
- **Frontend**: Flutter test framework for widgets
- **Coverage**: 75% backend, 65% frontend minimum
- **CI Integration**: Automated testing on commits

### Integration Testing
- **API Workflows**: Complete user journeys
- **Database Transactions**: Atomic operation testing
- **WebSocket Communication**: Real-time feature testing
- **Cross-Platform**: iOS/Android compatibility

### End-to-End Testing
- **User Scenarios**: Registration to match completion
- **Offline Functionality**: Network interruption handling
- **Performance**: Load testing with realistic scenarios
- **Compatibility**: Multiple device and OS testing

## Deployment & Operations

### Environment Strategy
- **Development**: Local development with hot reload
- **Staging**: Production-like testing environment
- **Production**: Multi-region deployment with monitoring

### Monitoring & Alerting
- **Health Checks**: `/health` endpoint with DB connectivity
- **Performance**: Response time tracking
- **Errors**: Centralized logging with Pino
- **Usage**: Basic analytics and user metrics

### Backup & Recovery
- **Database**: PlanetScale automated backups
- **Files**: Local filesystem backup strategy
- **Code**: Git versioning with tagged releases
- **Configuration**: Environment-specific config management

## Future Technical Considerations

### Planned Upgrades
- **GraphQL**: Consider for complex queries
- **Microservices**: Potential API splitting for scaling
- **Cloud Storage**: AWS S3 or similar for file uploads
- **Redis Caching**: Application-level caching layer
- **Container Orchestration**: Kubernetes for production scaling

### Technical Debt
- **Legacy Code**: Some controllers need refactoring
- **Test Coverage**: Increase coverage for edge cases
- **Documentation**: API documentation automation
- **Performance**: Query optimization for large datasets

## Conclusion

The Cricket League Management Application uses a modern, scalable technology stack optimized for mobile-first cricket tournament management. The architecture supports real-time features, offline capabilities, and multi-platform deployment while maintaining development efficiency and code quality standards.
