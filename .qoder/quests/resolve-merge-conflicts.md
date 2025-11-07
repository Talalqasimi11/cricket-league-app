# Merge Conflict Resolution Design

## Purpose

Systematically resolve all Git merge conflict markers across the cricket-league-app codebase, restore code consistency, improve production security, add CI guardrails, and ensure the application can build and run successfully.

## Scope

This design addresses 9 critical issues identified during code review:

1. Unresolved merge conflicts preventing build/run
2. Duplicate/undefined symbols from conflict remnants  
3. Missing `AppColors.darkSurface` causing build errors
4. Backend server entrypoint duplication
5. Production CORS/CSP security gaps
6. Legacy Redis retry pattern needing modernization
7. JWT configuration documentation gaps
8. Missing health check timeout/circuit breaker
9. Absent CI checks for conflict markers

## Problem Analysis

### Root Cause

Git merge conflicts were committed with conflict markers intact, resulting in:
- Multiple versions of same code blocks coexisting
- Syntax errors from incomplete merges
- Duplicate class/method definitions
- Mixed JavaScript operators in Dart code
- Inconsistent backend server initialization strategies

### Impact Assessment

**Severity**: Critical  
**Affected Components**: Frontend (6 files), Backend (3 files), Documentation (2 files)  
**Business Impact**: Application cannot build or start; security vulnerabilities in production deployment

---

## Design Strategy

### Resolution Approach

Follow the project memory guidance:
> "When resolving Dart file merge conflicts, always keep the Remote version and remove Local content between '<<<<<<<' and '=======' markers."

This strategy ensures:
- Consistency with latest approved changes
- Minimal regression risk
- Clear audit trail

### Decision Matrix

| File Type | Conflict Type | Resolution Strategy |
|-----------|--------------|-------------------|
| Frontend Dart | Local vs Remote | Keep Remote, discard Local |
| Backend JS | Duplicate server start | Keep testable export variant |
| Theme/Colors | Duplicate class | Merge both, include all color definitions |
| Documentation | Conflicting sections | Consolidate to single authoritative version |
| Database Schema | Duplicate DDL | Keep most complete version with all fields |

---

## Resolution Specification

### 1. Frontend Merge Conflicts

#### 1.1 Core Service Files

**Files Affected**:
- `frontend/lib/core/api_client.dart`
- `frontend/lib/core/websocket_service.dart`
- `frontend/lib/main.dart`

**Resolution Pattern**:

For each file:
1. Locate all conflict marker blocks: `<<<<<<< Local`, `=======`, `>>>>>>> Remote`
2. Remove Local block (between `<<<<<<<` and `=======`)
3. Keep Remote block (after `=======`)
4. Remove all marker lines
5. Ensure single declaration per symbol

**Specific Actions**:

**api_client.dart**:
- Keep Remote version implementing the complete `_withRefreshRetry` logic
- Retain single `_CacheEntry` class definition
- Keep unified request queue implementation
- Remove duplicate import statements

**websocket_service.dart**:
- Keep Remote version with `WebSocketState` enum
- Retain `_state`, `_setState`, `_cancelConnectionTimeout`, `_connectionTimeoutTimer` fields
- Keep enhanced connection lifecycle management
- Remove duplicate event handler registrations

**main.dart**:
- Keep Remote version with `RouteErrorWidget` imports
- Retain enhanced navigation error handling
- Keep `WidgetsBindingObserver` lifecycle management
- Preserve `ApiClient.dispose()` cleanup logic

#### 1.2 Theme Configuration

**File**: `frontend/lib/core/theme/colors.dart`

**Conflict**: Duplicate `AppColors` class definitions

**Resolution**:
Merge both versions to create complete color palette:

| Color Constant | Hex Value | Purpose |
|----------------|-----------|---------|
| `primary` | `0xFF2196F3` | Alias for primaryBlue |
| `primaryBlue` | `0xFF2196F3` | Primary brand color |
| `secondaryGreen` | `0xFF4CAF50` | Success/positive states |
| `accentOrange` | `0xFFFF9800` | Highlights/warnings |
| `errorRed` | `0xFFE57373` | Error states |
| `backgroundGrey` | `0xFFF5F5F5` | Page backgrounds |
| `textPrimary` | `0xFF212121` | Main text |
| `textSecondary` | `0xFF757575` | Secondary text |
| `dividerColor` | `0xFFBDBDBD` | Dividers/borders |
| `darkSurface` | `0xFF1E1E1E` | Dark mode surfaces |

**Action**:
- Keep all color definitions from both Local and Remote
- Add missing `darkSurface` constant
- Add `primary` alias for backward compatibility
- Ensure single class declaration

#### 1.3 Feature Screens

**Files**:
- `frontend/lib/features/matches/screens/scorecard_screen.dart`
- `frontend/lib/features/tournaments/screens/tournament_team_registration_screen.dart`

**Resolution**:
- Keep Remote versions
- Replace any `===` with `==` in Dart comparison operators
- Ensure single widget class definitions
- Verify all state variables declared once

### 2. Backend Merge Conflicts

#### 2.1 Server Entrypoint

**File**: `backend/index.js`

**Conflict**: Two server start strategies

**Current State**:
- Local: Immediate `httpServer.listen(PORT)`
- Remote: Conditional listen with exports

**Resolution**:
Keep Remote version with testable pattern:

**Pattern**:
```
Export app, server, io at module level
Guard httpServer.listen() with:
  if (require.main === module)
```

**Rationale**:
- Enables Jest test imports without starting server
- Follows Node.js best practices
- Supports integration testing

**Action Items**:
- Remove duplicate server start block
- Ensure single Redis client initialization
- Keep single Socket.IO namespace configuration
- Preserve SIGTERM cleanup handlers

#### 2.2 Controller Files

**Files**:
- `backend/controllers/tournamentTeamController.js`
- `backend/controllers/tournamentMatchController.js`

**Resolution**:
- Keep Remote versions
- Ensure single function exports
- Verify no duplicate middleware chains

### 3. Documentation Conflicts

#### 3.1 README

**File**: `README.md`

**Conflict**: Multiple introduction sections

**Resolution**:
- Keep Remote version header
- Consolidate environment variable documentation
- Merge setup instructions chronologically
- Remove duplicate quick start sections

**Required Sections** (in order):
1. Project title and overview
2. Documentation links
3. Technology stack
4. Environment configuration
5. Database setup
6. Running the application
7. Health check endpoints

#### 3.2 Database Schema

**File**: `cricket-league-db/complete_schema.sql`

**Conflict**: Incomplete table definitions

**Resolution**:
- Keep Remote version with complete field list
- Ensure `legal_balls` field present in `match_innings` table
- Verify all foreign key constraints
- Confirm indexes for performance

---

## Security Enhancements

### 4. Production CORS/CSP Hardening

**Objective**: Enforce HTTPS-only origins and eliminate wildcards in production

**Current Gaps**:
- No validation that `CORS_ORIGINS` contains only HTTPS in production
- Hard-coded dev domains may leak into production
- CSP `connect-src` derives from CORS but lacks validation

**Enhancement Specification**:

#### 4.1 Origin Validation

Add startup validation in `backend/index.js` after loading `CORS_ORIGINS`:

**Validation Rules**:
| Condition | Action |
|-----------|--------|
| `NODE_ENV=production` AND any origin starts with `http://` | Log error, exit process |
| `NODE_ENV=production` AND `CORS_ORIGINS` empty | Log error, exit process |
| `NODE_ENV=production` AND origin contains wildcard `*` | Log error, exit process |
| `COOKIE_SECURE=true` AND any non-HTTPS origin | Log warning |

**Implementation Location**: After `allowedOrigins` array construction, before CORS middleware

#### 4.2 Environment Documentation

Update `backend/.env.example`:

**Add Section**:
```
Production CORS Requirements:
- All origins MUST use HTTPS
- No wildcards allowed
- Comma-separated list required
Example: CORS_ORIGINS=https://app.example.com,https://admin.example.com
```

Update `README.md` CORS section:

**Add Warning**:
> Production deployments require HTTPS-only origins. The server validates `CORS_ORIGINS` at startup and exits if HTTP origins are detected when `NODE_ENV=production`.

### 5. Redis Client Modernization

**Objective**: Use modern Redis client patterns with graceful fallback

**Current Issues**:
- Legacy `retry_strategy` function format (deprecated in redis v4+)
- No fallback to in-memory adapter if Redis unavailable
- Abrupt process exit on Redis connection failure

**Modernization Specification**:

#### 5.1 Client Creation Pattern

Replace current Redis client creation with:

**Configuration Object**:
```
url: process.env.REDIS_URL || 'redis://localhost:6379'
socket:
  reconnectStrategy: (retries) =>
    if retries > 10: return Error
    return min(retries * 1000, 3000)
```

#### 5.2 Event Handlers

Add listeners for:
- `ready`: Log "Redis client ready"
- `end`: Log "Redis connection ended"  
- `reconnecting`: Log "Redis reconnecting, attempt N"
- `error`: Log error, do NOT exit process

#### 5.3 Graceful Degradation

**Fallback Logic**:
```
If Redis connection fails AND NODE_ENV=development:
  Use in-memory Socket.IO adapter
  Log warning: "Using in-memory adapter, live scoring limited to single server"
  
If Redis connection fails AND NODE_ENV=production:
  Log error: "Redis required for production, cannot start"
  Exit process with code 1
```

#### 5.4 Shutdown Handling

Enhance SIGTERM handler:
```
On SIGTERM:
  1. Close Socket.IO server
  2. Disconnect Redis clients (pubClient, subClient)
  3. Close database pool
  4. Exit with code 0
```

### 6. JWT Configuration Documentation

**Objective**: Clarify environment requirements for mobile and web clients

**Gaps**:
- `ALLOW_REFRESH_IN_BODY` environment variable not documented
- CSRF requirements unclear for cookie-based flows
- `iss`/`aud` mismatch detection missing from tests

**Enhancement Specification**:

#### 6.1 Environment Variable Documentation

Add to `backend/README.md`:

**Section**: JWT Configuration

| Variable | Purpose | Required | Default | Notes |
|----------|---------|----------|---------|-------|
| `JWT_SECRET` | Access token signing key | Yes | - | Min 32 chars |
| `JWT_REFRESH_SECRET` | Refresh token signing key | Yes | - | Min 32 chars |
| `JWT_AUD` | Token audience claim | Yes | - | Must match client |
| `JWT_ISS` | Token issuer claim | Yes | - | Validates token source |
| `ALLOW_REFRESH_IN_BODY` | Accept refresh token in request body | No | `false` | Enable for mobile apps |
| `ROTATE_REFRESH_ON_USE` | Issue new refresh token on each use | No | `true` in prod | Security best practice |

**Add Note**:
> Mobile clients should send `refresh_token` in request body with `x-client-type: mobile` header. Web clients should use secure HTTP-only cookies.

#### 6.2 Test Coverage

Add unit test in `backend/__tests__/auth.test.js`:

**Test Case**: JWT verification with mismatched issuer/audience

**Scenario Table**:
| Test | JWT Claims | Expected Result |
|------|-----------|----------------|
| Valid token | `iss=JWT_ISS, aud=JWT_AUD` | Success |
| Wrong issuer | `iss=evil-issuer, aud=JWT_AUD` | TokenExpiredError |
| Wrong audience | `iss=JWT_ISS, aud=wrong-aud` | TokenExpiredError |
| Missing claims | No `iss` or `aud` | TokenExpiredError |

### 7. Health Check Circuit Breaker

**Objective**: Prevent `/health/ready` endpoint from hanging on DB stalls

**Current Issue**:
- `checkConnection()` has no timeout
- Slow DB queries can block health probe indefinitely
- No circuit breaker pattern for repeated failures

**Enhancement Specification**:

#### 7.1 Timeout Implementation

Wrap DB connectivity check with timeout:

**Pattern**:
```
Create Promise.race:
  1. checkConnection() promise
  2. Timeout promise (rejects after 2000ms)
  
If timeout wins:
  Return status 503, database: 'timeout'
  
If check succeeds:
  Cache timestamp in lastHealthCheck
  Return status 200, database: 'connected'
```

#### 7.2 Response Enhancement

Add to `/health/ready` response:

| Field | Type | Purpose |
|-------|------|---------|
| `lastSuccessTimestamp` | ISO 8601 string | When DB was last reachable |
| `checkDurationMs` | number | How long check took |
| `cacheAge` | number | Seconds since last check |

**Caching Strategy**:
- Cache successful checks for 5 seconds
- Return cached response if within cache window
- Always perform fresh check on first request after cache expiry

#### 7.3 Startup Health Endpoint

Add new route: `GET /health/startup`

**Purpose**: Kubernetes startup probe with longer grace period

**Behavior**:
- Timeout: 5 seconds (vs 2 for ready probe)
- Retries DB connection up to 3 times
- Used during container initialization only

**Response Codes**:
- `200`: Database online, app ready
- `503`: Database unreachable after retries

---

## CI/CD Guardrails

### 8. Pre-Merge Conflict Detection

**Objective**: Prevent merge conflict markers from entering main branch

**Implementation Specification**:

#### 8.1 GitHub Actions Workflow

**File**: `.github/workflows/flutter.yml` (create if missing)

**Job**: `check-conflicts`

**Steps**:

| Step | Command | Failure Condition |
|------|---------|------------------|
| Checkout code | `actions/checkout@v3` | - |
| Check for conflict markers | `grep -r "<<<<<<< \|=======\|>>>>>>> " --include="*.dart" --include="*.js" --include="*.md" .` | Exit code 0 (markers found) |
| Fail if markers found | `exit 1` if grep succeeds | - |

**Add to Workflow**:
```
- name: Check for merge conflict markers
  run: |
    if grep -r "<<<<<<< \|=======\|>>>>>>> " --include="*.dart" --include="*.js" --include="*.json" --include="*.md" .; then
      echo "ERROR: Merge conflict markers found in codebase"
      exit 1
    fi
    echo "No conflict markers detected"
```

#### 8.2 Flutter Analysis Check

**Job**: `flutter-analyze`

**Steps**:

| Step | Purpose |
|------|---------|
| Setup Flutter | Install Flutter SDK |
| Get dependencies | `flutter pub get` |
| Run analyzer | `flutter analyze --no-pub` |
| Check exit code | Fail build if warnings/errors |

**Add to Workflow**:
```
- name: Run Flutter analyzer
  working-directory: ./frontend
  run: flutter analyze --no-pub
```

#### 8.3 Pre-Commit Hook

**File**: `.git/hooks/pre-commit` (local developer setup)

**Purpose**: Block local commits containing conflict markers

**Script Logic**:
```
For each staged file:
  If file matches *.dart, *.js, *.json, *.md:
    Search for conflict markers
    If found:
      Echo error with file name and line number
      Exit 1 (prevent commit)
```

**Installation Instructions** (add to `README.md`):
> To prevent accidentally committing merge conflicts, install the pre-commit hook:
> ```
> cp .githooks/pre-commit .git/hooks/pre-commit
> chmod +x .git/hooks/pre-commit
> ```

---

## Validation Checklist

### Post-Resolution Validation

After implementing all resolutions, verify:

#### Frontend Validation

| Check | Command | Success Criteria |
|-------|---------|-----------------|
| No conflict markers | `grep -r "<<<<<<< " frontend/` | No matches |
| Dart analysis passes | `cd frontend && flutter analyze` | 0 errors, 0 warnings |
| Build succeeds | `flutter build apk --debug` | Exit code 0 |
| App starts | Launch in emulator | No crash on startup |
| WebSocket connects | View live match | Connection established |

#### Backend Validation

| Check | Command | Success Criteria |
|-------|---------|-----------------|
| No conflict markers | `grep -r "<<<<<<< " backend/` | No matches |
| Linter passes | `npm run lint` | 0 errors |
| Tests pass | `npm test` | All tests green |
| Server starts | `npm start` | Listening on port 5000 |
| Health check responds | `curl http://localhost:5000/health/ready` | 200 OK |

#### Documentation Validation

| Check | Success Criteria |
|-------|-----------------|
| README renders correctly | No Markdown syntax errors |
| Environment variables complete | All required vars documented |
| Setup steps reproducible | Fresh install succeeds |

---

## Implementation Sequence

### Phase 1: Conflict Resolution (Priority: Critical)

1. **Frontend Core Files** (2 hours)
   - Resolve `api_client.dart`
   - Resolve `websocket_service.dart`  
   - Resolve `main.dart`
   - Run `flutter analyze` to confirm

2. **Frontend Theme** (30 minutes)
   - Merge `colors.dart` to include all constants
   - Update `custom_button.dart` references
   - Test theme compilation

3. **Frontend Screens** (1 hour)
   - Resolve `scorecard_screen.dart`
   - Resolve `tournament_team_registration_screen.dart`
   - Fix Dart syntax errors (replace `===` with `==`)

4. **Backend Server** (1 hour)
   - Resolve `index.js` to single export pattern
   - Resolve controller conflicts
   - Verify server starts without errors

5. **Documentation** (1 hour)
   - Consolidate `README.md`
   - Verify `complete_schema.sql`
   - Update setup instructions

### Phase 2: Security Enhancements (Priority: High)

6. **CORS/CSP Hardening** (2 hours)
   - Add production origin validation
   - Update `.env.example`
   - Test with HTTPS origins

7. **Redis Modernization** (2 hours)
   - Update client creation pattern
   - Add event handlers
   - Implement fallback logic
   - Test reconnection scenarios

8. **JWT Documentation** (1 hour)
   - Update `backend/README.md`
   - Add test cases for iss/aud validation
   - Document mobile vs web refresh flows

### Phase 3: Reliability Improvements (Priority: Medium)

9. **Health Check Circuit Breaker** (2 hours)
   - Add timeout wrapper to `/health/ready`
   - Implement response caching
   - Create `/health/startup` endpoint
   - Test with DB connection delays

### Phase 4: CI/CD Guardrails (Priority: Medium)

10. **GitHub Actions Workflow** (2 hours)
    - Create `.github/workflows/flutter.yml`
    - Add conflict marker check
    - Add `flutter analyze` step
    - Test on PR

11. **Pre-Commit Hook** (1 hour)
    - Create hook script in `.githooks/`
    - Add installation instructions to README
    - Test local commit blocking

---

## Risk Mitigation

### Rollback Strategy

If resolution introduces regressions:

1. **Immediate Rollback**: Revert to last known good commit
2. **Incremental Re-apply**: Apply resolutions one file at a time
3. **Test After Each Change**: Run validation checklist per file

### Testing Strategy

**Unit Tests**: Run existing test suites after each phase  
**Integration Tests**: Verify end-to-end flows after Phase 1  
**Manual Testing**: Test critical paths (login, live scoring, tournament creation)

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Build success rate | 100% | `flutter build` and `npm start` succeed |
| Analyzer warnings | 0 | `flutter analyze` output |
| Test pass rate | 100% | Jest and Flutter test results |
| Conflict marker presence | 0 | Grep search results |
| Health check response time | <2s | `/health/ready` latency |
| Production security score | Pass | No HTTP origins, no wildcards |

---

## Future Considerations

### Post-Resolution Improvements

1. **Automated Conflict Prevention**: Implement branch protection rules requiring CI checks
2. **Code Review Guidelines**: Add checklist for reviewers to catch conflict markers
3. **Developer Training**: Document merge conflict resolution workflow in CONTRIBUTING.md
4. **Monitoring**: Add alerting for health check timeouts in production
5. **Redis Clustering**: Consider Redis Sentinel for high availability

### Technical Debt

- Migration to schema versioning system (Flyway/Liquibase)
- Standardize error response format across all endpoints
- Add OpenAPI/Swagger documentation for API
- Implement structured logging with correlation IDs
- Add performance monitoring for slow queries
