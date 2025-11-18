# Flutter Deprecation Fix - withOpacity to withValues

## Task
Fix deprecated `withOpacity` method usage in `frontend/lib/features/matches/screens/live_match_view_screen.dart`

## Steps
- [ ] Search for all `withOpacity` instances in the target file
- [ ] Replace `withOpacity(0.5)` with `withValues(alpha: 0.5)`
- [ ] Replace `withOpacity(0.3)` with `withValues(alpha: 0.3)`
- [ ] Replace `withOpacity(0.7)` with `withValues(alpha: 0.7)`
- [ ] Replace `withOpacity(0.6)` with `withValues(alpha: 0.6)`
- [ ] Verify all replacements are correct and maintain functionality
