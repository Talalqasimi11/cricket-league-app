# Software Architecture Documentation

## Cricket League Management Application

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [System Architecture Overview](#2-system-architecture-overview)
3. [Technology Stack Architecture](#3-technology-stack-architecture)
4. [Design Patterns & Architectural Patterns](#4-design-patterns--architectural-patterns)
5. [Data Architecture & Models](#5-data-architecture--models)
6. [Component Architecture](#6-component-architecture)
7. [Security Architecture](#7-security-architecture)
8. [Performance & Scalability Architecture](#8-performance--scalability-architecture)
9. [Integration Architecture](#9-integration-architecture)
10. [Deployment Architecture](#10-deployment-architecture)
11. [Quality Assurance Architecture](#11-quality-assurance-architecture)
12. [Evolution & Maintenance Architecture](#12-evolution--maintenance-architecture)

---

## 1. Executive Summary

The Cricket League Management Application is a comprehensive digital platform designed to digitize and streamline cricket tournament management for amateur and semi-professional leagues. The system employs a modern, scalable architecture that supports real-time features, offline capabilities, and multi-platform deployment.

### Key Architectural Principles

- **Mobile-First Design**: Optimized for mobile cricket usage with offline capabilities
- **Real-Time Architecture**: WebSocket-based live scoring with low-latency updates
- **Microservices-Inspired**: Modular backend with clear separation of concerns
- **Data Integrity**: ACID-compliant transactions with comprehensive validation
- **Security-First**: JWT-based authentication with progressive security measures
- **Scalable Design**: Stateless APIs with horizontal scaling capabilities

### Architectural Goals

- Support 100+ concurrent live matches
- Handle 10,000+ active users
- Maintain <400ms real-time latency
- Ensure 99.9% uptime for core features
- Support offline functionality for 80% of use cases

---

## 2. System Architecture Overview

### High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    CLIENT LAYER                                 │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   Flutter App   │    │   React Admin   │    │   Web App   │  │
│  │   (Mobile)      │    │   (Dashboard)   │    │  (Future)   │  │
│  │                 │    │                 │    │             │  │
│  │ - Provider      │    │ - React Hooks   │    │ - PWA       │  │
│  │ - Offline Queue │    │ - Axios         │    │ - Service   │  │
│  │ - Secure Storage│    │ - Form Validation│    │   Worker    │  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                   API GATEWAY LAYER                             │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   Express.js    │    │   Socket.IO     │    │   Redis     │  │
│  │   REST API      │    │   WebSocket     │    │   Adapter    │  │
│  │                 │    │                 │    │             │  │
│  │ - JWT Auth      │    │ - Real-time     │    │ - Clustering │  │
│  │ - Rate Limiting │    │ - Broadcasting  │    │ - Pub/Sub    │  │
│  │ - CORS          │    │ - Rooms         │    │             │  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                   SERVICE LAYER                                 │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │ Auth Service    │    │ Scoring Engine  │    │ File Upload │  │
│  │                 │    │                 │    │ Service     │  │
│  │ - JWT Tokens    │    │ - Ball Validation│    │             │  │
│  │ - Password Hash │    │ - Statistics     │    │ - Sharp     │  │
│  │ - Sessions      │    │ - Real-time      │    │ - S3/Local  │  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                   DATA LAYER                                    │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   MySQL DB      │    │   Redis Cache   │    │   File      │  │
│  │   (PlanetScale) │    │   (Optional)    │    │   Storage   │  │
│  │                 │    │                 │    │             │  │
│  │ - InnoDB        │    │ - Sessions      │    │ - Local FS  │  │
│  │ - ACID          │    │ - Real-time     │    │ - CDN       │  │
│  │ - Replication   │    │ - Pub/Sub       │    │             │  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Architecture Characteristics

#### Scalability
- **Horizontal Scaling**: Stateless APIs support multiple instances
- **Database Sharding**: Future partitioning by tournament/region
- **Load Balancing**: Nginx/Cloud Load Balancer for traffic distribution
- **Caching Layers**: Redis for session and data caching

#### Reliability
- **Fault Tolerance**: Graceful degradation for non-critical features
- **Circuit Breakers**: Prevent cascade failures
- **Health Checks**: Comprehensive monitoring endpoints
- **Backup & Recovery**: Automated database backups with point-in-time recovery

#### Performance
- **Response Times**: <500ms API responses, <400ms real-time updates
- **Throughput**: Support 1000+ concurrent users
- **Resource Efficiency**: Optimized queries and connection pooling
- **Caching Strategy**: Multi-level caching (application, database, CDN)

#### Security
- **Authentication**: JWT with refresh token rotation
- **Authorization**: Role-based access control (RBAC)
- **Data Protection**: Encryption at rest and in transit
- **Input Validation**: Comprehensive sanitization and validation

---

## 3. Technology Stack Architecture

### Frontend Architecture

#### Flutter Mobile Application
```
Architecture: MVVM with Provider State Management

├── lib/
│   ├── main.dart                 # App entry point & initialization
│   ├── core/                     # Core functionality
│   │   ├── api_client.dart       # HTTP client with interceptors
│   │   ├── auth_provider.dart    # Authentication state management
│   │   ├── database/             # Local storage (Hive)
│   │   └── offline/              # Offline queue management
│   ├── features/                 # Feature modules
│   │   ├── auth/                 # Authentication screens
│   │   ├── tournaments/          # Tournament management
│   │   ├── matches/              # Match screens & scoring
│   │   └── teams/                # Team management
│   ├── models/                   # Data models
│   ├── screens/                  # UI screens
│   ├── services/                 # Business logic services
│   ├── widgets/                  # Reusable UI components
│   └── utils/                    # Utility functions
```

**Key Architectural Decisions:**
- **Provider Pattern**: Simple, predictable state management
- **Feature-First Organization**: Modular architecture by feature
- **Repository Pattern**: Data access abstraction
- **Dependency Injection**: Constructor-based DI for testability

#### React Admin Panel
```
Architecture: Component-Based with Hooks

├── src/
│   ├── App.js                   # Main application component
│   ├── index.js                 # React entry point
│   ├── components/              # Reusable components
│   │   ├── Dashboard.js         # Admin dashboard
│   │   ├── UserManagement.js    # User CRUD operations
│   │   └── TournamentManagement.js
│   ├── services/                # API service layer
│   │   └── api.js              # Axios-based API client
│   ├── utils/                   # Utility functions
│   │   ├── errorHandler.js      # Error handling utilities
│   │   └── formValidation.js    # Form validation helpers
│   └── contexts/                # React contexts (future)
```

### Backend Architecture

#### Node.js/Express API Server
```
Architecture: Layered Architecture with MVC Pattern

├── index.js                    # Server entry point
├── config/                     # Configuration management
│   ├── db.js                   # Database connection
│   └── validateEnv.js          # Environment validation
├── controllers/                # Request handlers (MVC Controllers)
│   ├── authController.js       # Authentication logic
│   ├── liveScoreController.js  # Live scoring operations
│   └── tournamentController.js # Tournament management
├── routes/                     # Route definitions
│   ├── authRoutes.js           # Authentication endpoints
│   └── api/                    # API route modules
├── middleware/                 # Express middleware
│   ├── authMiddleware.js       # JWT authentication
│   └── rateLimit.js            # Rate limiting
├── services/                   # Business logic layer
├── utils/                      # Utility functions
│   ├── transactionWrapper.js   # Database transactions
│   ├── enhancedValidation.js   # Input validation
│   └── errorMessages.js        # Error handling
├── models/                     # Data models (future)
└── tests/                      # Test suites
```

**Key Architectural Patterns:**
- **Layered Architecture**: Clear separation between routes, controllers, services
- **Middleware Pattern**: Request/response processing pipeline
- **Repository Pattern**: Data access abstraction
- **Service Layer**: Business logic encapsulation

#### Real-Time Architecture (Socket.IO)
```
WebSocket Architecture: Pub/Sub with Rooms

├── socket/
│   ├── index.js                # Socket.IO initialization
│   ├── middleware/             # Socket middleware
│   │   ├── auth.js             # JWT authentication
│   │   └── rateLimit.js        # Connection rate limiting
│   └── handlers/               # Event handlers
│       ├── match.js            # Match-related events
│       ├── scoring.js          # Live scoring events
│       └── tournament.js       # Tournament events

Event Flow:
1. Client connects → Authentication middleware
2. Client subscribes to match → Join room
3. Ball scored → Validate → Update DB → Broadcast to room
4. Client receives update → UI updates in real-time
```

### Database Architecture

#### MySQL Schema Design
```
Entity-Relationship Model:

Users (1) ──── (1) Teams
  │               │
  │               │
  └─── Tournaments (N) ──── TournamentTeams (N)
          │                       │
          │                       │
          └─── Matches (N) ──── MatchInnings (2)
                  │                   │
                  │                   │
                  └─── PlayerMatchStats (N)
                  └─── BallByBall (N)
```

**Normalization Strategy:**
- **3NF Compliance**: Eliminates transitive dependencies
- **Referential Integrity**: Foreign key constraints ensure data consistency
- **Indexing Strategy**: Optimized for query performance
- **Partitioning Ready**: Designed for future horizontal scaling

---

## 4. Design Patterns & Architectural Patterns

### Creational Patterns

#### Singleton Pattern
```javascript
// Database connection (backend/utils/db.js)
class Database {
  constructor() {
    if (Database.instance) {
      return Database.instance;
    }
    this.pool = mysql.createPool(config);
    Database.instance = this;
  }
}

module.exports = new Database();
```

#### Factory Pattern
```dart
// API client factory (Flutter)
class ApiClientFactory {
  static ApiClient create({String? baseUrl}) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? 'https://api.example.com',
      connectTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.add(AuthInterceptor());
    dio.interceptors.add(LoggingInterceptor());

    return ApiClient(dio);
  }
}
```

### Structural Patterns

#### Adapter Pattern
```javascript
// Database adapter for different storage backends
class DatabaseAdapter {
  constructor(config) {
    this.type = config.type;
    switch (config.type) {
      case 'mysql':
        this.client = new MySQLClient(config);
        break;
      case 'postgres':
        this.client = new PostgresClient(config);
        break;
      default:
        throw new Error('Unsupported database type');
    }
  }

  async query(sql, params) {
    return this.client.query(sql, params);
  }
}
```

#### Decorator Pattern
```javascript
// Express route decorators
function requireAuth(roles = []) {
  return function(req, res, next) {
    if (!req.user) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    if (roles.length > 0 && !roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    next();
  };
}

// Usage
router.get('/admin/users', requireAuth(['admin']), getUsers);
```

### Behavioral Patterns

#### Observer Pattern
```javascript
// Real-time score updates
class MatchObserver {
  constructor() {
    this.observers = new Map();
  }

  subscribe(matchId, callback) {
    if (!this.observers.has(matchId)) {
      this.observers.set(matchId, new Set());
    }
    this.observers.get(matchId).add(callback);
  }

  notify(matchId, data) {
    const observers = this.observers.get(matchId);
    if (observers) {
      observers.forEach(callback => callback(data));
    }
  }
}
```

#### Strategy Pattern
```javascript
// Authentication strategies
class AuthStrategy {
  authenticate(credentials) {
    throw new Error('Strategy must implement authenticate');
  }
}

class JWTStrategy extends AuthStrategy {
  authenticate(token) {
    return jwt.verify(token, process.env.JWT_SECRET);
  }
}

class LocalStrategy extends AuthStrategy {
  authenticate(credentials) {
    return bcrypt.compare(credentials.password, user.hash);
  }
}
```

#### Command Pattern
```javascript
// Database transaction commands
class TransactionCommand {
  constructor(operation, params) {
    this.operation = operation;
    this.params = params;
  }

  async execute(conn) {
    switch (this.operation) {
      case 'INSERT':
        return conn.query(this.params.sql, this.params.values);
      case 'UPDATE':
        return conn.query(this.params.sql, this.params.values);
      default:
        throw new Error('Unsupported operation');
    }
  }
}
```

### Architectural Patterns

#### Layered Architecture (Backend)
```
Presentation Layer (Routes/Controllers)
    ↓
Application Layer (Services/Middleware)
    ↓
Domain Layer (Business Logic/Models)
    ↓
Infrastructure Layer (Database/External APIs)
```

#### MVC Pattern (Frontend)
```
Model (Data/Models)
    ↓
View (Widgets/Screens)
    ↔
Controller (Providers/State Management)
```

#### Repository Pattern
```javascript
// Data access abstraction
class TournamentRepository {
  constructor(db) {
    this.db = db;
  }

  async findById(id) {
    const [rows] = await this.db.query(
      'SELECT * FROM tournaments WHERE id = ?',
      [id]
    );
    return rows[0];
  }

  async findByStatus(status) {
    const [rows] = await this.db.query(
      'SELECT * FROM tournaments WHERE status = ?',
      [status]
    );
    return rows;
  }

  async create(tournamentData) {
    const [result] = await this.db.query(
      'INSERT INTO tournaments SET ?',
      tournamentData
    );
    return result.insertId;
  }
}
```

#### Service Layer Pattern
```javascript
// Business logic encapsulation
class TournamentService {
  constructor(tournamentRepo, teamRepo) {
    this.tournamentRepo = tournamentRepo;
    this.teamRepo = teamRepo;
  }

  async createTournament(ownerId, tournamentData) {
    // Business logic validation
    await this.validateTournamentData(tournamentData);

    // Check ownership permissions
    await this.validateOwnerPermission(ownerId);

    // Create tournament
    const tournamentId = await this.tournamentRepo.create({
      ...tournamentData,
      created_by: ownerId
    });

    return tournamentId;
  }
}
```

---

## 5. Data Architecture & Models

### Data Model Architecture

#### Entity-Relationship Diagram
```
┌─────────────┐       ┌─────────────┐
│    Users    │       │    Teams    │
├─────────────┤       ├─────────────┤
│ id (PK)     │1────1 │ id (PK)     │
│ phone_number│       │ owner_id (FK)│
│ password_hash│      │ team_name   │
│ is_admin    │       │ team_location│
│ created_at  │       │ matches_played│
└─────────────┘       │ matches_won │
                      │ trophies    │
                      │ captain_id  │
                      └─────────────┘
                             │1
                             │
                             │N
                      ┌─────────────┐       ┌─────────────────┐
                      │   Players   │       │   Tournaments   │
                      ├─────────────┤       ├─────────────────┤
                      │ id (PK)     │       │ id (PK)         │
                      │ team_id (FK)│       │ tournament_name │
                      │ player_name │       │ location        │
                      │ player_role │       │ start_date      │
                      │ player_image│       │ status          │
                      │ runs        │       │ created_by (FK) │
                      │ matches     │       └─────────────────┘
                      │ centuries   │               │
                      │ fifties     │               │
                      │ avg/strike  │               │
                      │ wickets     │               │
                      └─────────────┘               │
                             │                      │
                             │                      │
                             │N                     │N
                      ┌─────────────┐       ┌─────────────────┐
                      │PlayerMatch  │       │TournamentTeams │
                      │  Statistics │       ├─────────────────┤
                      ├─────────────┤       │ id (PK)         │
                      │ id (PK)     │       │ tournament_id   │
                      │ player_id   │       │ team_id         │
                      │ match_id    │       │ temp_team_name  │
                      │ runs        │       │ temp_location   │
                      │ balls       │       └─────────────────┘
                      │ wickets     │
                      │ etc...      │
                      └─────────────┘
```

### Data Flow Architecture

#### Write Path (Data Ingestion)
```
User Action → API Validation → Business Logic → Transaction → Database → Cache Invalidation → Response
```

#### Read Path (Data Retrieval)
```
User Request → API Authentication → Cache Check → Database Query → Response Formatting → Client
```

#### Real-Time Data Flow
```
Ball Scored → Validation → Database Transaction → WebSocket Broadcast → Client Update → UI Refresh
```

### Data Validation Architecture

#### Input Validation Layers
```javascript
// 1. Route-level validation (Express middleware)
router.post('/tournaments', validateTournamentData, createTournament);

// 2. Controller validation
const createTournament = async (req, res) => {
  const validated = req.validated; // Already validated by middleware
  // Business logic...
};

// 3. Service-level validation
class TournamentService {
  async createTournament(data) {
    await this.validateBusinessRules(data);
    await this.validatePermissions(data);
    // Create tournament...
  }
}

// 4. Database-level constraints
-- Foreign key constraints
-- Check constraints
-- Unique constraints
```

### Data Consistency Architecture

#### Transaction Management
```javascript
// Transaction wrapper pattern
const { withTransaction } = require('./transactionWrapper');

const result = await withTransaction(async (conn) => {
  // Multiple database operations in single transaction
  const team = await conn.query('INSERT INTO teams ...');
  const players = await conn.query('INSERT INTO players ...');
  const stats = await conn.query('INSERT INTO player_match_stats ...');

  return { teamId: team.insertId, playerCount: players.affectedRows };
}, {
  retryCount: 3,
  retryDelay: 50
});
```

#### Concurrency Control
- **Optimistic Locking**: Version fields for conflict detection
- **Pessimistic Locking**: Database-level locking for critical operations
- **Queue-Based Processing**: Sequential processing for order-dependent operations

---

## 6. Component Architecture

### Backend Component Architecture

#### Controller Layer
```javascript
// Standard controller structure
const controller = {
  // CRUD operations
  async create(req, res) {
    try {
      const validated = req.validated;
      const result = await service.create(validated, req.user.id);
      res.status(201).json(formatResponse(result));
    } catch (error) {
      handleError(error, res);
    }
  },

  async getById(req, res) {
    try {
      const { id } = req.params;
      const result = await service.getById(id, req.user.id);
      res.json(formatResponse(result));
    } catch (error) {
      handleError(error, res);
    }
  }
};
```

#### Service Layer
```javascript
// Business logic encapsulation
class ScoringService {
  constructor(repositories, websocket) {
    this.matchRepo = repositories.match;
    this.inningsRepo = repositories.innings;
    this.statsRepo = repositories.stats;
    this.websocket = websocket;
  }

  async recordBall(ballData, scorerId) {
    // 1. Validate permissions
    await this.validateScorerPermission(ballData.matchId, scorerId);

    // 2. Validate cricket rules
    await this.validateBallData(ballData);

    // 3. Execute in transaction
    return await withTransaction(async (conn) => {
      // Update innings
      await this.updateInnings(conn, ballData);

      // Update player statistics
      await this.updatePlayerStats(conn, ballData);

      // Broadcast real-time update
      this.websocket.broadcast(ballData.matchId, {
        type: 'ball_scored',
        data: ballData
      });

      return { success: true };
    });
  }
}
```

#### Repository Layer
```javascript
// Data access abstraction
class MatchRepository {
  constructor(db) {
    this.db = db;
  }

  async findById(id) {
    const [rows] = await this.db.query(`
      SELECT m.*, t1.team_name as team1_name, t2.team_name as team2_name
      FROM matches m
      JOIN teams t1 ON m.team1_id = t1.id
      JOIN teams t2 ON m.team2_id = t2.id
      WHERE m.id = ?
    `, [id]);

    return rows[0];
  }

  async updateStatus(id, status, winnerId = null) {
    const [result] = await this.db.query(
      'UPDATE matches SET status = ?, winner_team_id = ? WHERE id = ?',
      [status, winnerId, id]
    );

    return result.affectedRows > 0;
  }
}
```

### Frontend Component Architecture

#### Provider State Management
```dart
// State management with Provider
class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> login(String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await api.login(phone, password);
      _user = User.fromJson(response.data['user']);
      await secureStorage.write('token', response.data['token']);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

#### Screen Architecture
```dart
// Screen with BLoC-like pattern
class TournamentScreen extends StatefulWidget {
  @override
  _TournamentScreenState createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  late TournamentProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<TournamentProvider>(context, listen: false);
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    await _provider.loadTournaments();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TournamentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return LoadingWidget();
        }

        return ListView.builder(
          itemCount: provider.tournaments.length,
          itemBuilder: (context, index) {
            return TournamentCard(provider.tournaments[index]);
          },
        );
      },
    );
  }
}
```

#### Widget Composition
```dart
// Composite widget pattern
class MatchScoreCard extends StatelessWidget {
  final Match match;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          MatchHeader(match: match),
          TeamScore(team: match.team1, score: match.team1Score),
          TeamScore(team: match.team2, score: match.team2Score),
          MatchStatus(status: match.status),
        ],
      ),
    );
  }
}
```

---

## 7. Security Architecture

### Authentication Architecture

#### JWT Token Architecture
```javascript
// Token structure
const jwtPayload = {
  sub: userId,           // Subject (user ID)
  phone_number: phone,   // User identifier
  roles: ['captain'],    // User roles
  scopes: ['team:read', 'team:manage'], // Permissions
  typ: 'access',         // Token type
  iss: process.env.JWT_ISS, // Issuer
  aud: process.env.JWT_AUD  // Audience
};

// Token generation
const accessToken = jwt.sign(payload, secret, { expiresIn: '15m' });
const refreshToken = jwt.sign(payload, refreshSecret, { expiresIn: '7d' });
```

#### Multi-Factor Security
- **Password Security**: bcrypt with 12 salt rounds
- **Token Rotation**: Refresh tokens rotated on use (production)
- **Session Management**: Secure httpOnly cookies
- **Rate Limiting**: Progressive throttling on failed attempts

### Authorization Architecture

#### Role-Based Access Control (RBAC)
```javascript
// Permission definitions
const PERMISSIONS = {
  'team:read': 'Read team information',
  'team:manage': 'Create, update, delete teams',
  'match:score': 'Score matches and manage innings',
  'tournament:manage': 'Create, update, delete tournaments',
  'admin:manage': 'Administrative operations'
};

// Role definitions
const ROLES = {
  captain: ['team:read', 'team:manage', 'player:manage', 'match:score', 'tournament:manage'],
  admin: ['admin:manage', 'user:manage', 'team:admin']
};
```

#### Resource Ownership
```javascript
// Ownership validation
const validateOwnership = async (resourceId, userId, resourceType) => {
  const [owner] = await db.query(`
    SELECT owner_id FROM ${resourceType}s WHERE id = ?
  `, [resourceId]);

  if (!owner || owner.owner_id !== userId) {
    throw new ForbiddenError('Access denied');
  }
};
```

### Data Protection Architecture

#### Encryption Strategy
- **At Rest**: Database encryption for sensitive fields
- **In Transit**: TLS 1.3 for all communications
- **Client Storage**: Encrypted local storage for tokens

#### Input Security
```javascript
// Input sanitization middleware
const sanitizeInput = (req, res, next) => {
  // SQL injection prevention
  for (const key in req.body) {
    if (typeof req.body[key] === 'string') {
      req.body[key] = req.body[key].replace(/['";\\]/g, '');
    }
  }

  // XSS prevention
  for (const key in req.query) {
    req.query[key] = validator.escape(req.query[key]);
  }

  next();
};
```

---

## 8. Performance & Scalability Architecture

### Performance Architecture

#### Response Time Optimization
```javascript
// Database query optimization
const getTournamentWithTeams = async (tournamentId) => {
  // Single optimized query instead of N+1
  const [rows] = await db.query(`
    SELECT
      t.*,
      tt.id as team_id,
      COALESCE(tt.team_name, ttemp.temp_team_name) as team_name,
      COALESCE(tt.team_location, ttemp.temp_team_location) as team_location
    FROM tournaments t
    LEFT JOIN tournament_teams tt ON t.id = tt.tournament_id
    LEFT JOIN teams tm ON tt.team_id = tm.id
    LEFT JOIN tournament_temp_teams ttemp ON tt.temp_team_id = ttemp.id
    WHERE t.id = ?
  `, [tournamentId]);

  return rows;
};
```

#### Caching Strategy
```javascript
// Multi-level caching
class CacheManager {
  constructor(redis, memoryCache) {
    this.redis = redis;
    this.memory = memoryCache;
  }

  async get(key) {
    // L1: Memory cache
    let data = this.memory.get(key);
    if (data) return data;

    // L2: Redis cache
    data = await this.redis.get(key);
    if (data) {
      this.memory.set(key, data); // Populate L1
      return data;
    }

    return null;
  }

  async set(key, value, ttl = 300) {
    this.memory.set(key, value, ttl);
    await this.redis.setex(key, ttl, JSON.stringify(value));
  }
}
```

### Scalability Architecture

#### Horizontal Scaling
```
Load Balancer
    ↓
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ API Server  │  │ API Server  │  │ API Server  │
│ Instance 1  │  │ Instance 2  │  │ Instance N  │
└─────────────┘  └─────────────┘  └─────────────┘
       │               │               │
       └───────────────┼───────────────┘
                      │
               ┌─────────────┐
               │ Redis PubSub│
               │  for WS     │
               └─────────────┘
```

#### Database Scaling
```sql
-- Future partitioning strategy
PARTITION BY RANGE (YEAR(created_at)) (
  PARTITION p2024 VALUES LESS THAN (2025),
  PARTITION p2025 VALUES LESS THAN (2026),
  PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Read replica configuration
-- Primary: Write operations
-- Replicas: Read operations for analytics
```

#### WebSocket Scaling
```javascript
// Redis adapter for multi-instance WebSocket
const io = require('socket.io')(server);
const redisAdapter = require('socket.io-redis');

io.adapter(redisAdapter({
  host: process.env.REDIS_HOST,
  port: process.env.REDIS_PORT
}));
```

---

## 9. Integration Architecture

### API Integration Patterns

#### RESTful API Design
```javascript
// Consistent API structure
GET    /api/tournaments           # List tournaments
POST   /api/tournaments           # Create tournament
GET    /api/tournaments/:id       # Get tournament
PUT    /api/tournaments/:id       # Update tournament
DELETE /api/tournaments/:id       # Delete tournament

// Filtering and pagination
GET /api/tournaments?status=live&page=1&limit=20

// Response format
{
  "success": true,
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150
  },
  "timestamp": "2025-11-06T12:00:00.000Z"
}
```

#### WebSocket Integration
```javascript
// Client-side WebSocket connection
class WebSocketManager {
  constructor() {
    this.socket = io(BASE_URL, {
      auth: { token: getAuthToken() },
      transports: ['websocket', 'polling']
    });

    this.setupEventHandlers();
  }

  subscribeToMatch(matchId) {
    this.socket.emit('subscribe', { matchId });
  }

  onScoreUpdate(callback) {
    this.socket.on('scoreUpdate', callback);
  }
}
```

### Third-Party Integrations

#### File Storage Integration
```javascript
// File upload with Sharp processing
const uploadService = {
  async processImage(file) {
    const processed = await sharp(file.buffer)
      .resize(300, 300, { fit: 'cover' })
      .jpeg({ quality: 80 })
      .toBuffer();

    // Save to local storage or cloud
    const filename = `player_${Date.now()}.jpg`;
    await fs.writeFile(`uploads/players/${filename}`, processed);

    return `/uploads/players/${filename}`;
  }
};
```

#### External API Integration
```javascript
// Weather API for match scheduling (future)
class WeatherService {
  async getWeatherForecast(location, date) {
    const response = await axios.get('https://api.weather.com/forecast', {
      params: { location, date },
      headers: { 'X-API-Key': process.env.WEATHER_API_KEY }
    });

    return {
      condition: response.data.condition,
      temperature: response.data.temperature,
      precipitation: response.data.precipitation
    };
  }
}
```

---

## 10. Deployment Architecture

### Environment Architecture

#### Development Environment
```
Local Development
├── Flutter DevTools
├── Hot Reload
├── Local MySQL
├── Nodemon
└── Debug Logging
```

#### Staging Environment
```
Production-like Testing
├── Docker Containers
├── PlanetScale DB
├── Nginx Load Balancer
├── Monitoring Tools
└── Automated Tests
```

#### Production Environment
```
Scalable Production
├── Kubernetes Cluster
├── Multi-region Deployment
├── CDN Integration
├── Advanced Monitoring
└── Auto-scaling
```

### Containerization Strategy

#### Docker Architecture
```dockerfile
# Backend Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 5000
CMD ["npm", "start"]

# Frontend Dockerfile
FROM flutter:latest
WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get
COPY . .
RUN flutter build apk --release
```

#### Docker Compose for Development
```yaml
version: '3.8'
services:
  backend:
    build: ./backend
    ports:
      - "5000:5000"
    environment:
      - DB_HOST=mysql
      - REDIS_URL=redis://redis:6379

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"

  mysql:
    image: mysql:8
    environment:
      MYSQL_ROOT_PASSWORD: password

  redis:
    image: redis:alpine
```

### CI/CD Pipeline Architecture

#### GitHub Actions Workflow
```yaml
name: CI/CD Pipeline

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm install
      - run: npm test
      - run: npm run lint

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: docker build -t myapp .
      - run: docker push myregistry/myapp:${{ github.sha }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - run: kubectl set image deployment/myapp myapp=myregistry/myapp:${{ github.sha }}
```

---

## 11. Quality Assurance Architecture

### Testing Architecture

#### Unit Testing Strategy
```javascript
// Backend unit tests
describe('TournamentService', () => {
  let service;
  let mockRepo;

  beforeEach(() => {
    mockRepo = {
      create: jest.fn(),
      findById: jest.fn()
    };
    service = new TournamentService(mockRepo);
  });

  test('should create tournament with valid data', async () => {
    const tournamentData = { name: 'Test Tournament', location: 'Test City' };
    mockRepo.create.mockResolvedValue(1);

    const result = await service.createTournament(1, tournamentData);

    expect(result).toBe(1);
    expect(mockRepo.create).toHaveBeenCalledWith({
      ...tournamentData,
      created_by: 1
    });
  });
});
```

#### Integration Testing Strategy
```javascript
// API integration tests
describe('Tournament API', () => {
  let app;
  let db;

  beforeAll(async () => {
    app = await createTestApp();
    db = await createTestDatabase();
  });

  afterAll(async () => {
    await db.close();
  });

  test('POST /api/tournaments - creates tournament', async () => {
    const response = await request(app)
      .post('/api/tournaments')
      .set('Authorization', `Bearer ${testToken}`)
      .send({
        tournament_name: 'Integration Test Tournament',
        location: 'Test City',
        start_date: '2025-12-01'
      });

    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);
  });
});
```

#### End-to-End Testing Strategy
```dart
// Flutter integration tests
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete tournament creation flow', (tester) async {
    await tester.pumpWidget(const MyApp());

    // Navigate to tournaments
    await tester.tap(find.text('Tournaments'));
    await tester.pumpAndSettle();

    // Create tournament
    await tester.tap(find.text('Create Tournament'));
    await tester.pumpAndSettle();

    // Fill form
    await tester.enterText(find.byKey(const Key('name')), 'E2E Test Tournament');
    await tester.enterText(find.byKey(const Key('location')), 'Test City');

    // Submit
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Verify success
    expect(find.text('Tournament created successfully'), findsOneWidget);
  });
}
```

### Code Quality Architecture

#### Linting and Formatting
```javascript
// ESLint configuration
module.exports = {
  extends: ['eslint:recommended', '@typescript-eslint/recommended'],
  rules: {
    'no-unused-vars': 'error',
    'prefer-const': 'error',
    'no-var': 'error'
  }
};
```

#### Static Analysis
```dart
// Flutter analysis options
analyzer:
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false
  errors:
    missing_required_param: error
    missing_return: error
  exclude:
    - lib/generated/**
```

---

## 12. Evolution & Maintenance Architecture

### Versioning Strategy

#### API Versioning
```javascript
// URL-based versioning
app.use('/api/v1', v1Routes);

// Header-based versioning (future)
app.use((req, res, next) => {
  const version = req.headers['api-version'] || 'v1';
  req.apiVersion = version;
  next();
});
```

#### Database Migrations
```javascript
// Migration file structure
const migration = {
  up: async (db) => {
    await db.query(`
      ALTER TABLE matches ADD COLUMN venue VARCHAR(100) DEFAULT 'TBD'
    `);
  },

  down: async (db) => {
    await db.query(`
      ALTER TABLE matches DROP COLUMN venue
    `);
  }
};
```

### Monitoring & Observability

#### Application Metrics
```javascript
// Prometheus metrics
const register = new promClient.Registry();
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5]
});

register.registerMetric(httpRequestDuration);

// Middleware to collect metrics
app.use((req, res, next) => {
  const end = httpRequestDuration.startTimer({
    method: req.method,
    route: req.route?.path || req.path
  });

  res.on('finish', () => {
    end({ status_code: res.statusCode });
  });

  next();
});
```

#### Logging Architecture
```javascript
// Structured logging with Pino
const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  formatters: {
    level: (label) => ({ level: label })
  },
  serializers: {
    req: pino.stdSerializers.req,
    res: pino.stdSerializers.res,
    err: pino.stdSerializers.err
  }
});

// Usage
logger.info({ userId, action: 'tournament_created' }, 'Tournament created successfully');
logger.error({ err, userId }, 'Failed to create tournament');
```

### Maintenance Procedures

#### Database Maintenance
```sql
-- Regular maintenance queries
-- Analyze table statistics
ANALYZE TABLE users, teams, tournaments, matches;

-- Optimize tables
OPTIMIZE TABLE player_match_stats;

-- Clean up old data
DELETE FROM auth_failures WHERE failed_at < DATE_SUB(NOW(), INTERVAL 30 DAY);
```

#### Application Maintenance
```javascript
// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    // Database connectivity check
    await db.query('SELECT 1');

    // Redis connectivity check (if used)
    if (redis) {
      await redis.ping();
    }

    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      version: process.env.npm_package_version
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});
```

### Future-Proofing Architecture

#### Extensibility Patterns
```javascript
// Plugin architecture for future features
class PluginManager {
  constructor() {
    this.plugins = new Map();
  }

  register(name, plugin) {
    this.plugins.set(name, plugin);
  }

  async executeHook(hookName, ...args) {
    for (const plugin of this.plugins.values()) {
      if (plugin[hookName]) {
        await plugin[hookName](...args);
      }
    }
  }
}

// Usage
const plugins = new PluginManager();
plugins.register('analytics', new AnalyticsPlugin());
plugins.register('notifications', new NotificationPlugin());

// Execute hooks
await plugins.executeHook('onTournamentCreated', tournamentData);
```

#### Configuration Management
```javascript
// Environment-based configuration
const config = {
  development: {
    database: { host: 'localhost' },
    redis: { enabled: false },
    logging: { level: 'debug' }
  },
  production: {
    database: { host: process.env.DB_HOST },
    redis: { enabled: true, url: process.env.REDIS_URL },
    logging: { level: 'info' }
  }
};

module.exports = config[process.env.NODE_ENV || 'development'];
```

---

## Conclusion

The Cricket League Management Application employs a comprehensive, scalable software architecture that balances modern development practices with practical implementation. The architecture supports the core requirements of tournament management, real-time scoring, and multi-platform deployment while providing a solid foundation for future enhancements and scaling.

Key architectural strengths include:
- **Layered Architecture**: Clear separation of concerns
- **Scalable Design**: Horizontal scaling capabilities
- **Security-First**: Comprehensive authentication and authorization
- **Performance Optimized**: Efficient data access and caching
- **Maintainable Code**: Consistent patterns and documentation
- **Testable Design**: Dependency injection and modular components

This architecture ensures the application can evolve with growing user demands while maintaining reliability, performance, and security standards.
