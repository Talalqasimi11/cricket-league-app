# Design: Resolve Dart Merge Conflicts and System Stabilization

## Objective

Eliminate all Git merge conflicts in Dart files, resolve compilation errors, complete incomplete API implementations, enhance error handling, improve production readiness, and establish automated quality gates to prevent future merge issues.

## Problem Statement

The codebase contains unresolved Git merge conflicts causing compilation failures, duplicate class definitions, incomplete API service methods, theme inconsistencies, backend testability issues, security configuration gaps, and missing automated quality checks. These issues block development and deployment.

## Scope

### In Scope
1. Merge conflict resolution in all Dart files
2. Duplicate class/type definition elimination
3. API service method implementation
4. Theme color definition completion
5. Backend export structure refactoring
6. Security configuration hardening
7. Database schema ordering corrections
8. Test coverage expansion
9. Controller utility adoption
10. Health check enhancements
11. Documentation conflict resolution

### Out of Scope
- New feature development
- Performance optimization beyond bug fixes
- Database migration system implementation
- Third-party package upgrades
- UI/UX redesign

## Design

### 1. Merge Conflict Resolution Strategy

#### 1.1 Conflict Resolution Decision Matrix

| File | Conflict Type | Resolution Strategy | Rationale |
|------|--------------|---------------------|-----------|
| `main.dart` | Duplicate classes + import differences | Keep Remote version | Remote has lifecycle management and RouteErrorWidget |
| `api_client.dart` | Duplicate ApiClient class | Keep Remote version | Remote has connection timeout and state management |
| `websocket_service.dart` | Duplicate WebSocketService | Keep Remote version | Remote has state enum and disposal safety |
| `scorecard_screen.dart` | Duplicate ScorecardScreen | Keep Remote version | Remote has enhanced UI and proper data handling |
| `tournament_team_registration_screen.dart` | Multiple variants | Analyze and merge best features | TBD during implementation |

#### 1.2 Dart Operator Corrections

**Issue**: JavaScript equality operator `===` found in Dart files

**Resolution**:
- Search pattern: `===` and `!==`
- Replace with: `==` and `!=`
- Validate: No semantic changes needed (Dart uses `==` for equality)

#### 1.3 Import Reconciliation

**Process**:
- Merge import lists from both conflict branches
- Remove duplicates
- Maintain import order: Dart SDK → Flutter → Package → Relative
- Ensure all referenced symbols are imported

### 2. Duplicate Class Elimination

#### 2.1 ApiClient Deduplication

**Current State**: Two complete ApiClient class definitions exist in `api_client.dart`

**Target State**: Single coherent ApiClient class with:
- Singleton pattern
- Lifecycle management (init, dispose with WidgetsBindingObserver)
- HTTP client resource management
- Request queuing for offline mode
- Response caching with expiration
- Token refresh retry logic
- Platform-aware base URL detection
- Connection state tracking

**Merge Strategy**:
1. Keep Remote version as base (has state management)
2. Verify Local version has no unique methods
3. Ensure all internal helper classes are defined once: `_QueuedRequest`, `_CacheEntry`

#### 2.2 WebSocketService Deduplication

**Current State**: Two WebSocketService implementations

**Target State**: Single class with:
- State enumeration (disconnected, connecting, connected, disposed)
- Connection timeout management
- Reconnection backoff logic
- Event callback handlers
- Proper disposal and cleanup
- Subscription management per match

**Merge Strategy**:
1. Adopt Remote version (includes state enum and timeout handling)
2. Verify all event handlers are preserved
3. Ensure disposal prevents further operations

#### 2.3 Screen Component Deduplication

**Screens with Conflicts**:
- `ScorecardScreen`: Keep Remote version (has enhanced UI)
- `AppBootstrap` / `AuthInitializer`: Keep Remote version (has lifecycle observer)

### 3. API Service Implementation

#### 3.1 Incomplete Methods Analysis

**Methods Requiring Implementation**:

| Method | Route | Query Parameters | Response Model | Cache Strategy |
|--------|-------|------------------|----------------|----------------|
| `getTournaments()` | `/api/tournaments` | `status` (optional) | `List<Tournament>` | 10 min cache |
| `getMatches()` | `/api/matches` | `status`, `tournament_id` (optional) | `List<Match>` | 5 min cache |
| `getPlayerMatchStats()` | `/api/player-match-stats` | `match_id` (required) | `List<PlayerMatchStats>` | 5 min cache |
| `getTeamTournamentSummary()` | `/api/team-tournament-summary` | `tournament_id` (required) | `List<TeamTournamentSummary>` | 10 min cache |
| `submitFeedback()` | `/api/feedback` | None | `Feedback` | No cache |
| `getMyTeam()` | `/api/teams/my-team` | None | Dynamic JSON | 10 min cache |
| `getPlayers()` | `/api/players` | `team_id` (optional) | Dynamic JSON list | 10 min cache |
| `getTournamentTeams()` | `/api/tournament-teams` | `tournament_id` (required) | Dynamic JSON list | 10 min cache |

#### 3.2 Implementation Pattern

**Common Structure**:
```
1. Construct endpoint path with query parameters
2. Call ApiClient method (get, post, etc.) with optional cache duration
3. Parse response using helper (_parseResponse or _parseListResponse)
4. Handle errors with debugPrint and rethrow
5. Return typed model or dynamic JSON
```

**Query Parameter Building**:
- Build parameter list conditionally
- Join with `&` separator
- Append to path with `?` prefix

**Error Handling**:
- All methods use try-catch
- Log errors with debugPrint including method name
- Rethrow to allow caller handling

### 4. Theme Color Resolution

#### 4.1 Missing Color Definition

**Issue**: `custom_button.dart` references `AppColors.darkSurface` which doesn't exist

**Current `AppColors` Definition**:
```
- primaryBlue
- secondaryGreen
- accentOrange
- errorRed
- backgroundGrey
- textPrimary
- textSecondary
- dividerColor
```

**Resolution Options**:

| Option | Action | Impact |
|--------|--------|--------|
| A. Add to AppColors | Define `darkSurface = Color(0xFF1A1A1A)` | Consistent with existing pattern |
| B. Use theme context | Replace with `Theme.of(context).colorScheme.surface` | More dynamic, theme-aware |
| C. Use existing color | Map to `backgroundGrey` or create alias | Quick fix, may not match intent |

**Recommended**: Option A - Add `darkSurface` constant to maintain consistency with existing `AppColors` usage pattern.

**Value Selection**:
- Analyze `custom_button.dart` usage context (secondary variant)
- Match existing dark mode surface color in theme extensions
- Default: `Color(0xFF1E1E1E)` (Material dark surface)

#### 4.2 Theme Extension Check

**Verify**: `theme_extensions.dart` and `theme_config.dart` for existing dark surface definitions
**Align**: New constant with any existing theme definitions

### 5. Backend Export Structure Refactoring

#### 5.1 Current Export Issue

**Problem**: `backend/index.js` only exports `io`, making Supertest integration impossible

**Current Pattern**:
```
- Server starts unconditionally on require
- Only io (Socket.IO) instance exported
- Tests cannot import app without starting server
```

#### 5.2 Target Export Structure

**Exports Required**:
- `app` (Express application instance)
- `server` (HTTP server instance)
- `io` (Socket.IO instance)

**Conditional Startup Pattern**:
```
if (require.main === module) {
  server.listen(PORT, callback);
}
```

**Benefits**:
- Tests can import app without side effects
- Supertest can wrap app instance
- Controllers can access io via export
- Server lifecycle controllable in tests

#### 5.3 Migration Steps

1. Store server instance in variable before listen()
2. Wrap listen() call in require.main check
3. Export object: `{ app, server, io }`
4. Update test files to use new exports

### 6. Security Configuration Hardening

#### 6.1 CORS Production Checks

**Current Gaps**:
- Localhost origins included in production defaults
- No validation that HTTPS required when credentials=true
- Hard-coded ngrok origin in development list

**Enhanced Validation Rules**:

| Condition | Validation | Action on Failure |
|-----------|-----------|-------------------|
| `NODE_ENV=production` && `CORS_ORIGINS` empty | Fatal | Exit with error |
| `NODE_ENV=production` && `COOKIE_SECURE=true` | Warn if any HTTP origins | Log warning, continue |
| `NODE_ENV=production` && wildcard origin | Fatal | Exit with error |
| Development mode | Informational | Log active origins |

**Ngrok Origin Handling**:
- Remove from hard-coded defaults
- Document in README as environment-specific configuration
- Optionally gate with `DEV_NGROK_URL` environment variable

#### 6.2 CSP Tightening

**Current**: CSP `connect-src` auto-derives WebSocket URLs

**Enhancement**:
- Validate derived URLs match allowed patterns
- Log CSP violations in development
- Document required CSP configuration in production

#### 6.3 Environment Variable Documentation

**Update `.env.example`**:
- Add all required CORS origins
- Document HTTPS requirement for production
- Provide ngrok configuration example
- Include security best practices section

### 7. Redis Client Modernization

#### 7.1 Deprecated API Usage

**Current**: Uses deprecated `retry_strategy` option

**Replacement**:
```
socket: {
  reconnectStrategy: (retries) => {
    if (retries > maxRetries) return new Error('Max retries');
    return Math.min(retries * 50, 2000);
  }
}
```

#### 7.2 Graceful Degradation

**Strategy**: Application continues without Redis if unavailable

**Event Handlers**:
- `ready`: Log successful connection, use Redis adapter
- `error`: Log error, track connection state
- `end`: Log disconnection
- `reconnecting`: Log retry attempts

**Adapter Fallback**:
- Start with memory adapter
- Switch to Redis adapter on successful connection
- Fallback to memory on Redis failure
- Document cluster implications (memory adapter is single-process)

### 8. JWT Configuration Consistency

#### 8.1 Required Environment Variables

**Enforce in Documentation**:
- `JWT_ISS`: Issuer claim (must match verify())
- `JWT_AUD`: Audience claim (must match verify())
- Document mismatch error scenarios

#### 8.2 Refresh Token Rotation Headers

**Current Inconsistency**: Multiple code paths set rotation header differently

**Standardization**:
- Single header: `X-Refresh-Rotated`
- Set once per rotation event
- Body inclusion: Only when `ALLOW_REFRESH_IN_BODY=true` AND `x-client-type=mobile`
- Document in API reference

#### 8.3 Test Coverage

**Add Tests**:
- Token verification with mismatched iss
- Token verification with mismatched aud
- Rotation header presence validation
- Mobile vs web refresh flow differences

### 9. Database Schema Ordering

#### 9.1 Current Issue

**Problem**: `schema.sql` contains `UPDATE tournaments` before table creation

**Analysis**:
- Statement location in file
- Dependencies on table existence
- Migration vs bootstrap context

#### 9.2 Resolution Strategy

**Option A**: Move statement after table creation
**Option B**: Wrap in existence check (if database supports)
**Option C**: Move to separate migration file

**Recommended**: Option A for bootstrap script, ensure idempotency

**Verification**:
- Fresh database installation succeeds
- All DDL statements execute in order
- DML statements reference existing tables

### 10. Automated Testing Enhancement

#### 10.1 Frontend Test Coverage Gaps

**Required Test Files**:

| Test File | Target | Test Scenarios |
|-----------|--------|----------------|
| `safe_json_parser_test.dart` | `core/safe_json_parser.dart` | Valid JSON, invalid JSON, null handling, nested objects |
| `websocket_service_test.dart` | `core/websocket_service.dart` | Connect, disconnect, reconnection, state transitions, disposal |
| `route_error_widget_test.dart` | `widgets/route_error_widget.dart` | Widget rendering, error display, navigation back |

**Test Approach**:
- Unit tests for utilities (safe_json_parser)
- Mock tests for services (websocket_service with mock socket)
- Widget tests for UI components (route_error_widget)

#### 10.2 CI Integration

**GitHub Actions Workflow** (`flutter.yml`):

**Trigger Events**:
- Pull requests to main/dev branches
- Push to main/dev branches

**Jobs**:
1. **Analyze**: Run `flutter analyze` on frontend code
2. **Test**: Run `flutter test` on frontend code
3. **Conflict Check**: Grep for conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)

**Failure Conditions**:
- Any analyzer errors
- Test failures
- Conflict markers found

#### 10.3 Pre-commit Hook

**Hook Script** (`.git/hooks/pre-commit`):
```
#!/bin/sh
# Check for merge conflict markers
if git grep -qE '^(<{7}|={7}|>{7})' -- ':(exclude).git'; then
  echo "Error: Merge conflict markers found"
  exit 1
fi
```

**Setup Documentation**: Include in README setup steps

### 11. Controller Utility Adoption

#### 11.1 Refactoring Candidates

**Target Controllers**:
- `teamController.js`
- `playerController.js`
- `matchFinalizationController.js`
- `liveScoreController.js`

**Available Utilities**:
- `withTransaction()` from `transactionWrapper.js`
- `validateBody()` from `enhancedValidation.js`

#### 11.2 Refactoring Strategy

**Prioritization**:
1. Endpoints with multiple table modifications → use `withTransaction()`
2. Endpoints with complex input validation → use `validateBody()`
3. High-traffic endpoints → refactor for consistency

**Behavioral Preservation**:
- No logic changes
- Replace plumbing code only
- Maintain exact response format
- Preserve error messages

#### 11.3 Validation Schema Pattern

**For each endpoint**:
1. Define validation schema (field types, required, constraints)
2. Replace manual validation with `validateBody(schema)`
3. Centralize validation logic

### 12. Health Check Enhancement

#### 12.1 Current Limitation

**Issue**: Database ping can hang indefinitely, blocking health check response

#### 12.2 Enhanced Health Endpoint Design

**Timeout Wrapper**:
```
Promise.race([
  checkConnection(),
  new Promise((_, reject) => 
    setTimeout(() => reject(new Error('Timeout')), 2000)
  )
])
```

**Health Status States**:
- `healthy`: DB connection successful, latency < 1s
- `degraded`: DB connection successful, latency > 1s
- `unhealthy`: DB connection failed or timeout

**Response Schema**:
```
{
  status: "healthy" | "degraded" | "unhealthy",
  timestamp: ISO8601,
  database: {
    connected: boolean,
    latency_ms: number,
    last_success: ISO8601,
    time_since_success_ms: number
  }
}
```

#### 12.3 Cached Status

**Cache Strategy**:
- Cache last successful connection time
- Include in response even when current check fails
- Helps distinguish transient vs persistent failures

**TTL**: 10 seconds (balance between freshness and load)

#### 12.4 Startup Probe (Optional)

**New Endpoint**: `/health/startup`
- Longer timeout (5s) for cold start scenarios
- Used by orchestrators (Kubernetes, Docker)
- Returns 200 only when app fully initialized

### 13. Documentation Conflict Resolution

#### 13.1 README.md Conflicts

**Issue**: Multiple conflict blocks, duplicate sections, mixed content versions

**Resolution Process**:
1. Identify canonical sections (most recent, accurate)
2. Merge environment variable documentation
3. Consolidate setup instructions
4. Verify all referenced files exist
5. Update links to documentation files

#### 13.2 Content Merge Strategy

**Sections to Preserve**:
- Latest environment variable requirements
- Schema setup with legal_balls field
- Accurate quick start steps
- Current technology stack

**Sections to Remove**:
- Outdated migration instructions
- Conflicting feature descriptions
- Duplicate setup steps

**Verification**:
- All links resolve
- Commands are executable
- Environment variables match .env.example

## Implementation Plan

### Phase 1: Critical Compilation Fixes (Priority: Critical)

**Deliverable**: Application compiles without errors

1. Resolve merge conflicts in `main.dart` (keep Remote)
2. Resolve merge conflicts in `api_client.dart` (keep Remote)
3. Resolve merge conflicts in `websocket_service.dart` (keep Remote)
4. Resolve merge conflicts in `scorecard_screen.dart` (keep Remote)
5. Resolve conflicts in `tournament_team_registration_screen.dart`
6. Remove all conflict markers from Dart files
7. Replace JavaScript operators (`===`, `!==`) with Dart equivalents
8. Run `flutter analyze` and fix remaining errors

**Validation**: `flutter analyze` returns zero errors

### Phase 2: API Service Completion (Priority: High)

**Deliverable**: All API methods functional

1. Implement `getTournaments()` with status filtering
2. Implement `getMatches()` with status and tournament_id filtering
3. Implement `getPlayerMatchStats()` with match_id parameter
4. Implement `getTeamTournamentSummary()` with tournament_id parameter
5. Implement `submitFeedback()` with model mapping
6. Implement `getMyTeam()` with JSON parsing
7. Implement `getPlayers()` with team_id filtering
8. Implement `getTournamentTeams()` with tournament_id parameter

**Validation**: All methods return expected data types, handle errors gracefully

### Phase 3: Theme and UI Fixes (Priority: High)

**Deliverable**: UI renders without color errors

1. Add `darkSurface` constant to `AppColors`
2. Verify theme extension alignment
3. Test `custom_button.dart` in dark mode
4. Validate all button variants render correctly

**Validation**: No runtime theme errors, buttons render in all variants

### Phase 4: Backend Refactoring (Priority: High)

**Deliverable**: Backend testable with Supertest

1. Refactor `index.js` exports (app, server, io)
2. Add `require.main` check around server.listen()
3. Update test files to use new exports
4. Verify server starts independently
5. Run existing backend tests

**Validation**: Tests import app without starting server, all tests pass

### Phase 5: Security Hardening (Priority: Medium)

**Deliverable**: Production-ready security configuration

1. Add production CORS validation
2. Require HTTPS origins when `COOKIE_SECURE=true`
3. Remove hard-coded ngrok origin
4. Add environment variable documentation
5. Update `.env.example` with security notes
6. Add startup warnings for misconfigurations

**Validation**: Production mode rejects insecure configurations

### Phase 6: Infrastructure Improvements (Priority: Medium)

**Deliverable**: Enhanced reliability and error handling

1. Modernize Redis client (reconnectStrategy)
2. Add Redis event handlers (ready, error, end)
3. Implement graceful degradation
4. Add connection timeout to health check
5. Implement cached health status
6. Add startup probe endpoint
7. Fix database schema ordering in `schema.sql`

**Validation**: App continues without Redis, health checks timeout gracefully

### Phase 7: Testing and Automation (Priority: Medium)

**Deliverable**: Automated quality gates

1. Create `safe_json_parser_test.dart`
2. Create `websocket_service_test.dart`
3. Create `route_error_widget_test.dart`
4. Add GitHub Actions workflow for Flutter
5. Add conflict marker check to CI
6. Create pre-commit hook script
7. Document hook installation

**Validation**: CI passes on clean branch, rejects conflicts and errors

### Phase 8: Controller Refactoring (Priority: Low)

**Deliverable**: Consistent utility usage across controllers

1. Refactor `teamController.js` to use utilities
2. Refactor `playerController.js` to use utilities
3. Refactor `matchFinalizationController.js` to use utilities
4. Refactor `liveScoreController.js` to use utilities
5. Create validation schemas for each endpoint
6. Test refactored endpoints for behavioral equivalence

**Validation**: All endpoints return identical responses, tests pass

### Phase 9: Documentation (Priority: Low)

**Deliverable**: Accurate, conflict-free documentation

1. Resolve all conflicts in `README.md`
2. Verify all documentation links
3. Update quick start guide
4. Document new environment variables
5. Update API documentation for refresh rotation
6. Document health check endpoints

**Validation**: All commands work, all links resolve

## Success Criteria

| Criterion | Measurement | Target |
|-----------|-------------|--------|
| Compilation | `flutter analyze` exit code | 0 errors |
| API Coverage | Implemented methods / Total methods | 100% |
| Test Coverage | Frontend tests passing | All pass |
| Backend Tests | Supertest integration | Functional |
| Security | Production CORS validation | Active |
| Health Checks | Response time under load | < 2s |
| Documentation | Broken links | 0 |
| CI Integration | Pipeline failures on conflicts | Enforced |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Choosing wrong conflict version | Medium | High | Analyze both versions, prefer documented behavior |
| Breaking existing functionality | Medium | High | Preserve behavior exactly, comprehensive testing |
| API signature changes | Low | High | Maintain backward compatibility, document changes |
| Redis connection failures | Medium | Medium | Graceful degradation, fallback to memory adapter |
| Health check timeouts | Low | Low | Cached status, reasonable timeout values |
| Test maintenance overhead | Medium | Low | Keep tests simple, focus on critical paths |

## Dependencies

### External Dependencies
- No new package dependencies required
- Existing packages: `http`, `socket_io_client`, `flutter_secure_storage`, `connectivity_plus`

### Internal Dependencies
- Backend utilities: `transactionWrapper.js`, `enhancedValidation.js`
- Frontend models: `Tournament`, `Match`, `PlayerMatchStats`, `TeamTournamentSummary`, `Feedback`
- Theme system: `theme_data.dart`, `theme_extensions.dart`, `colors.dart`

## Rollback Plan

### Conflict Resolution Rollback
- Each merge conflict resolution committed separately
- Git tags mark pre-resolution state
- Revert individual commits if issues arise

### Backend Changes Rollback
- Export structure change is additive (backward compatible)
- Old import pattern still works
- Can revert to conditional startup later

### Database Schema Rollback
- Schema ordering fix doesn't affect existing databases
- Only impacts fresh installations
- No migration needed

## Testing Strategy

### Unit Tests
- `safe_json_parser_test.dart`: Cover valid, invalid, null, edge cases
- Backend utilities: Test validation schemas, transaction wrappers

### Integration Tests
- API service methods: Mock ApiClient, verify request construction
- WebSocket service: Mock socket, test state transitions

### Widget Tests
- `route_error_widget_test.dart`: Verify rendering, user interactions

### E2E Tests
- Backend: Supertest for complete request/response cycles
- Frontend: Integration tests for critical user flows (existing)

### Manual Testing Checklist
- [ ] App builds without errors
- [ ] All screens navigate correctly
- [ ] API calls return expected data
- [ ] WebSocket connects and receives updates
- [ ] Dark mode renders correctly
- [ ] Backend health checks respond
- [ ] Production mode rejects insecure CORS configs

## Monitoring and Observability

### Logging Enhancements
- Log conflict resolution decisions
- Log API method invocations and errors
- Log WebSocket state transitions
- Log health check failures and timeouts

### Metrics to Track
- Health check response times
- Redis connection status
- API error rates by endpoint
- WebSocket reconnection frequency

### Alerts
- Health check degraded for > 5 minutes
- Redis unavailable for > 10 minutes
- API error rate > 5% for any endpoint
- Frontend analyzer errors in CI

## Future Improvements

### Beyond This Design
1. Migrate to formal database migration system (Knex, TypeORM)
2. Implement comprehensive API error codes and messages
3. Add request tracing (correlation IDs across frontend/backend)
4. Enhance WebSocket reconnection with exponential backoff
5. Implement circuit breaker pattern for external dependencies
6. Add performance monitoring for API endpoints
7. Create development environment automation (Docker Compose)
8. Implement feature flags for safer deployments

### Technical Debt Addressed
- Merge conflicts eliminated
- Incomplete implementations completed
- Security configurations hardened
- Test coverage improved
- Documentation conflicts resolved

### Remaining Technical Debt
- No formal migration system
- Manual environment configuration
- Limited observability tooling
- No automated performance testing
- Missing API versioning strategy
