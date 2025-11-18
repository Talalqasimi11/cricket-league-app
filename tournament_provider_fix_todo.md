# Tournament Team Registration Provider Fix

## Task
Fix compilation and runtime errors in `frontend/lib/features/tournaments/providers/tournament_team_registration_provider.dart`

## Issues Identified
- Constructor async call error (direct async method call in constructor)
- Improper future management and assignment
- Missing null safety checks in several locations
- Potential race conditions in state management
- Incomplete disposal logic for async operations
- Complex loading state management that could cause issues

## Steps
- [ ] Fix constructor by removing direct async call to fetchTeams()
- [ ] Create proper initialization method for initial data fetch
- [ ] Add null safety checks throughout the code
- [ ] Simplify state management to prevent race conditions
- [ ] Improve disposal logic for async operations and futures
- [ ] Test the fixes to ensure no compilation errors
- [ ] Verify functionality is maintained after fixes

## Key Code Areas to Fix
1. Lines 26-27: Constructor calls fetchTeams() directly (async error)
2. Future management: _fetchTeamsFuture assignment and handling
3. Null safety: Multiple locations lack proper null checks
4. State management: Complex loading states need simplification
5. Disposal: Async operations not properly handled in dispose()
