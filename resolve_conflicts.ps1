# Merge Conflict Resolution Script (PowerShell)
# Systematically resolves Git merge conflicts by keeping Remote versions
# and removing Local content as per the design document.

$ErrorActionPreference = "Stop"

# Files to process
$conflictFiles = @(
    "backend\controllers\tournamentMatchController.js",
    "backend\controllers\tournamentTeamController.js",
    "backend\index.js",
    "cricket-league-db\complete_schema.sql",
    "frontend\lib\core\api_client.dart",
    "frontend\lib\core\theme\colors.dart",
    "frontend\lib\core\websocket_service.dart",
    "frontend\lib\features\matches\screens\scorecard_screen.dart",
    "frontend\lib\features\tournaments\screens\tournament_team_registration_screen.dart",
    "frontend\lib\main.dart",
    "IMPLEMENTATION_SUMMARY.md",
    "README.md"
)

function Resolve-ConflictsInFile {
    param (
        [string]$FilePath
    )
    
    Write-Host "Processing: $FilePath" -ForegroundColor Cyan
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "  File not found" -ForegroundColor Yellow
        return $false
    }
    
    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    
    # Count conflicts before resolution
    $conflictMatches = [regex]::Matches($content, '<<<<<<< Local')
    $conflictCount = $conflictMatches.Count
    if ($conflictCount -eq 0) {
        Write-Host "  No conflicts found" -ForegroundColor Green
        return $false
    }
    
    Write-Host "  Found $conflictCount conflict(s)" -ForegroundColor Yellow
    
    # Strategy: Keep everything after ======= until >>>>>>> Remote
    # Remove everything from <<<<<<< Local to ======= (inclusive)
    # Remove >>>>>>> Remote marker
    
    # Process conflicts iteratively to handle nested conflicts
    $maxIterations = 10
    $iteration = 0
    
    while (($content -match '<<<<<<< Local') -and ($iteration -lt $maxIterations)) {
        $iteration++
        
        # Find each conflict block and replace with Remote content
        $content = $content -replace '(?s)<<<<<<< Local.*?=======\r?\n(.*?)>>>>>>> Remote\r?\n?', '$1'
        
        $remainingMatches = [regex]::Matches($content, '<<<<<<< Local')
        $remainingConflicts = $remainingMatches.Count
        if ($remainingConflicts -gt 0) {
            Write-Host "  Iteration $iteration : $remainingConflicts conflicts remaining" -ForegroundColor Yellow
        }
    }
    
    # Verify all conflicts are resolved
    $finalMatches = [regex]::Matches($content, '<<<<<<< Local')
    $remainingConflicts = $finalMatches.Count
    if ($remainingConflicts -eq 0) {
        Write-Host "  All conflicts resolved" -ForegroundColor Green
        
        # Write resolved content back
        $content | Set-Content -Path $FilePath -NoNewline -Encoding UTF8
        Write-Host "  File updated successfully" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  ERROR: $remainingConflicts conflicts still remain" -ForegroundColor Red
        return $false
    }
}

# Main execution
$separator = "=" * 60
Write-Host $separator -ForegroundColor Cyan
Write-Host "Merge Conflict Resolution Script" -ForegroundColor Cyan
Write-Host "Strategy: Keep Remote version, discard Local content" -ForegroundColor Cyan
Write-Host $separator -ForegroundColor Cyan
Write-Host ""

$processedCount = 0
$errorCount = 0
$baseDir = Get-Location

foreach ($relPath in $conflictFiles) {
    $filePath = Join-Path $baseDir $relPath
    
    try {
        $success = Resolve-ConflictsInFile -FilePath $filePath
        if ($success) {
            $processedCount++
        }
    } catch {
        Write-Host "  ERROR: $_" -ForegroundColor Red
        $errorCount++
    }
    
    Write-Host ""
}

Write-Host $separator -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Files processed: $processedCount" -ForegroundColor Green
$errorColor = if ($errorCount -eq 0) { 'Green' } else { 'Red' }
Write-Host "  Errors: $errorCount" -ForegroundColor $errorColor
Write-Host $separator -ForegroundColor Cyan
