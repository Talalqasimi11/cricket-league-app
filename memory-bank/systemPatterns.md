# System Patterns - Cricket League Management Application

## System Architecture

### High-Level Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │   Node.js API   │    │   React Admin   │
│   (Mobile)      │◄──►│   (Backend)     │◄──►│   (Web Panel)   │
│                 │    │                 │    │                 │
│ - Provider      │    │ - Express.js    │    │ - React Hooks   │
│ - Offline Queue │    │ - Socket.IO     │    │ - Axios         │
│ - Secure Storage│    │ - JWT Auth      │    │ - Form Validation│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   MySQL DB      │
                    │   (PlanetScale) │
                    │                 │
                    │ - InnoDB        │
                    │ - Connection    │
                    │   Pooling       │
                    └─────────────────┘
```

### Component Relationships

#### Core Components
- **Authentication Service**: JWT-based auth with refresh tokens
- **Tournament Engine**: Manages tournament lifecycle and match scheduling
- **Live Scoring Engine**: Real-time ball-by-ball scoring with validation
- **Statistics Calculator**: Automatic calculation of player/team statistics
- **WebSocket Manager**: Real-time updates for live matches
- **File Upload Service**: Image processing and storage management

#### Data Flow Patterns
1. **User Registration** → Team Auto-Creation → Database Storage
2. **Tournament Creation** → Team Registration → Match Scheduling
3. **Live Match** → Ball Recording → Statistics Update → Real-time Broadcast
4. **Match Completion** → Finalization → Winner Determination → Statistics Lock

## Key Technical Decisions

### State Management (Frontend)
- **Provider Pattern**: Simple, predictable state management for Flutter
- **Scoped State**: Component-level state for UI interactions
- **Persistent State**: Secure storage for authentication tokens
- **Offline State**: Local database (Hive) for offline functionality

### API Design Patterns
- **RESTful Endpoints**: Standard HTTP methods with resource-based URLs
- **Consistent Response Format**: Standardized success/error response structure
- **Versioned APIs**: `/api/v1/` prefix for future compatibility
- **Pagination**: Cursor-based pagination for list endpoints
- **Filtering**: Query parameter-based filtering for complex queries

### Database Patterns
- **Connection Pooling**: Efficient connection management with mysql2
- **Transaction Wrappers**: Atomic operations with retry logic
- **Migration System**: Lexicographic ordering with idempotent scripts
- **Indexing Strategy**: Optimized indexes on frequently queried fields
- **Foreign Key Constraints**: Referential integrity with cascade operations

### Error Handling Patterns
- **Middleware-Based**: Express middleware for centralized error handling
- **Structured Responses**: Consistent error format with codes and messages
- **Logging Strategy**: Pino logger with request IDs and structured logs
- **Graceful Degradation**: Fallback behavior for non-critical failures

## Component Design Patterns

### Controller Pattern (Backend)
```javascript
// Standard controller structure
const controller = {
  async operation(req, res) {
    try {
      // Input validation
      const validated = req.validated;
      
      // Business logic
      const result = await service.performOperation(validated);
      
      // Response formatting
      const response = formatResponse(result);
      
      res.json(response);
    } catch (error) {
      // Error handling
      handleError(error, res);
    }
  }
};
```

### Service Layer Pattern
```javascript
// Service with dependency injection
class ScoringService {
  constructor(db, logger, websocket) {
    this.db = db;
    this.logger = logger;
    this.websocket = websocket;
  }
  
  async recordBall(ballData) {
    // Validation
    this.validateBallData(ballData);
    
    // Transaction wrapper
    return await withTransaction(async (conn) => {
      // Database operations
      await this.updateInnings(conn, ballData);
      await this.updatePlayerStats(conn, ballData);
      
      // Real-time broadcast
      this.websocket.broadcastScore(ballData.matchId);
      
      return { success: true };
    });
  }
}
```

### Repository Pattern (Data Access)
```javascript
// Repository with query building
class TournamentRepository {
  async findByStatus(status, options = {}) {
    const { limit, offset } = options;
    
    const query = `
      SELECT * FROM tournaments 
      WHERE status = ?
      ORDER BY created_at DESC
      LIMIT ? OFFSET ?
    `;
    
    const [rows] = await this.db.query(query, [status, limit, offset]);
    return rows;
  }
  
  async create(tournamentData) {
    const query = `
      INSERT INTO tournaments 
      (name, location, start_date, created_by) 
      VALUES (?, ?, ?, ?)
    `;
    
    const [result] = await this.db.query(query, [
      tournamentData.name,
      tournamentData.location,
      tournamentData.startDate,
      tournamentData.createdBy
    ]);
    
    return result.insertId;
  }
}
```

## Critical Implementation Paths

### Match Creation Flow
1. **Validation**: Tournament exists, not started, user has permission
2. **Team Verification**: Both teams registered for tournament
3. **Match Creation**: Insert match record with tournament context
4. **Innings Initialization**: Create innings records for both teams
5. **WebSocket Notification**: Broadcast match creation to subscribers

### Live Scoring Flow
1. **Authentication**: Verify scorer is team owner
2. **Ball Validation**: Cricket rules (ball number 1-6, legal deliveries)
3. **Transaction Start**: Begin atomic operation
4. **Statistics Update**: Update innings, player stats, team stats
5. **Auto-End Logic**: Check for innings completion (10 wickets or overs)
6. **Broadcast**: Real-time updates to all match viewers
7. **Transaction Commit**: Atomic completion

### Tournament Finalization Flow
1. **Permission Check**: Only participating team owners can finalize
2. **Innings Validation**: All innings completed
3. **Winner Calculation**: Compare total runs
4. **Statistics Lock**: Prevent further modifications
5. **Team Updates**: Update win/loss records
6. **Broadcast**: Final results to all subscribers

## Security Patterns

### Authentication Flow
- **JWT Tokens**: Short-lived access tokens (15 min) + refresh tokens (7 days)
- **Password Security**: bcrypt hashing with 12 salt rounds
- **Rate Limiting**: Progressive throttling on failed attempts
- **Session Management**: Secure cookies with httpOnly flag

### Authorization Patterns
- **Role-Based Access**: Owner, player, spectator roles
- **Resource Ownership**: Users can only modify their own resources
- **API Scopes**: Granular permissions for different operations
- **Audit Logging**: Track all administrative actions

### Input Validation
- **Middleware Validation**: Request-level validation with detailed errors
- **Type Coercion**: Automatic type conversion for numeric fields
- **Sanitization**: SQL injection prevention with parameterized queries
- **Length Limits**: Prevent buffer overflow attacks

## Performance Patterns

### Database Optimization
- **Connection Pooling**: 10 connections with automatic management
- **Query Optimization**: Proper indexing on foreign keys and search fields
- **Batch Operations**: Bulk inserts/updates where possible
- **Read Replicas**: Future consideration for high-traffic endpoints

### Caching Strategy
- **Application Cache**: In-memory caching for frequently accessed data
- **Database Cache**: Query result caching with TTL
- **CDN**: Static asset delivery optimization
- **API Response Cache**: Short-lived caching for stable data

### Monitoring Patterns
- **Health Checks**: `/health` endpoint with DB connectivity
- **Performance Metrics**: Response time tracking and alerting
- **Error Tracking**: Centralized error logging and alerting
- **Usage Analytics**: User behavior and feature usage tracking

## Scalability Considerations

### Horizontal Scaling
- **Stateless API**: No server-side session storage
- **Database Sharding**: Future partitioning by tournament or region
- **Load Balancing**: Multiple API instances behind load balancer
- **WebSocket Clustering**: Redis adapter for multi-server WebSocket support

### Vertical Scaling
- **Resource Optimization**: Efficient memory usage and garbage collection
- **Query Optimization**: Complex query analysis and optimization
- **Caching Layers**: Multi-level caching strategy
- **Background Jobs**: Async processing for heavy operations

## Testing Patterns

### Unit Testing
- **Controller Logic**: Business logic testing with mocked dependencies
- **Service Methods**: Pure function testing with controlled inputs
- **Validation Rules**: Input validation testing with edge cases
- **Error Scenarios**: Exception handling and error response testing

### Integration Testing
- **API Endpoints**: Full request/response cycle testing
- **Database Operations**: Transaction testing with rollback
- **WebSocket Events**: Real-time communication testing
- **Authentication Flow**: Complete login/logout cycle testing

### End-to-End Testing
- **User Journeys**: Complete user workflows from registration to match completion
- **Cross-Platform**: Testing across iOS, Android, and web platforms
- **Offline Scenarios**: Network interruption and recovery testing
- **Performance Testing**: Load testing with realistic user patterns

## Deployment Patterns

### Environment Management
- **Development**: Local development with hot reload
- **Staging**: Production-like environment for testing
- **Production**: Multi-region deployment with failover
- **Configuration**: Environment-specific configuration management

### CI/CD Pipeline
- **Automated Testing**: Unit and integration tests on every commit
- **Code Quality**: Linting, security scanning, and coverage reports
- **Deployment Automation**: Blue-green deployments with rollback capability
- **Monitoring**: Automated health checks and alerting

## Conclusion

The Cricket League Management Application follows established patterns for scalable, maintainable software development. The architecture supports the core requirements of tournament management, live scoring, and real-time updates while providing a foundation for future feature development and scaling.
