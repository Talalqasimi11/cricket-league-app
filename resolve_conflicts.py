#!/usr/bin/env python3
"""
Merge Conflict Resolution Script
Systematically resolves Git merge conflicts by keeping Remote versions
and removing Local content as per the design document.
"""

import re
import os
from pathlib import Path

# Files to process
CONFLICT_FILES = [
    "backend/controllers/tournamentMatchController.js",
    "backend/controllers/tournamentTeamController.js",
    "backend/index.js",
    "cricket-league-db/complete_schema.sql",
    "frontend/lib/core/api_client.dart",
    "frontend/lib/core/theme/colors.dart",
    "frontend/lib/core/websocket_service.dart",
    "frontend/lib/features/matches/screens/scorecard_screen.dart",
    "frontend/lib/features/tournaments/screens/tournament_team_registration_screen.dart",
    "frontend/lib/main.dart",
    "IMPLEMENTATION_SUMMARY.md",
    "README.md",
]

def resolve_conflicts_in_file(filepath):
    """
    Resolve conflicts in a single file by keeping Remote version.
    Strategy: Remove everything between <<<<<<< Local and ======= (including markers)
              Remove >>>>>>> Remote marker
              Keep content after ======= until >>>>>>> Remote
    """
    print(f"Processing: {filepath}")
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Count conflicts before resolution
    conflict_count = content.count('<<<<<<< Local')
    if conflict_count == 0:
        print(f"  ✓ No conflicts found")
        return False
    
    print(f"  Found {conflict_count} conflict(s)")
    
    # Resolve conflicts: keep Remote, discard Local
    # Pattern: <<<<<<< Local\n.*?\n=======\n(.*?)\n>>>>>>> Remote
    # We want to keep group(1) which is the Remote content
    
    # This regex handles nested conflicts and multiple conflicts
    pattern = r'<<<<<<< Local.*?=======\n(.*?)>>>>>>> Remote\n?'
    
    resolved_content = re.sub(pattern, r'\1', content, flags=re.DOTALL)
    
    # Verify all conflicts are resolved
    remaining_conflicts = resolved_content.count('<<<<<<< Local')
    if remaining_conflicts > 0:
        print(f"  ⚠ WARNING: {remaining_conflicts} conflicts remain after first pass")
        # Try again for nested conflicts
        resolved_content = re.sub(pattern, r'\1', resolved_content, flags=re.DOTALL)
        remaining_conflicts = resolved_content.count('<<<<<<< Local')
        
    if remaining_conflicts == 0:
        print(f"  ✓ All conflicts resolved")
    else:
        print(f"  ✗ ERROR: {remaining_conflicts} conflicts still remain")
        return False
    
    # Write resolved content back
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(resolved_content)
    
    print(f"  ✓ File updated successfully")
    return True

def main():
    """Main execution function"""
    print("=" * 60)
    print("Merge Conflict Resolution Script")
    print("Strategy: Keep Remote version, discard Local content")
    print("=" * 60)
    print()
    
    base_dir = Path(__file__).parent
    processed_count = 0
    error_count = 0
    
    for rel_path in CONFLICT_FILES:
        filepath = base_dir / rel_path
        
        if not filepath.exists():
            print(f"⚠ File not found: {rel_path}")
            print()
            continue
        
        try:
            success = resolve_conflicts_in_file(filepath)
            if success:
                processed_count += 1
        except Exception as e:
            print(f"  ✗ ERROR: {e}")
            error_count += 1
        
        print()
    
    print("=" * 60)
    print(f"Summary:")
    print(f"  Files processed: {processed_count}")
    print(f"  Errors: {error_count}")
    print("=" * 60)

if __name__ == "__main__":
    main()
