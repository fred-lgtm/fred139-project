#!/usr/bin/env pwsh

Write-Host "Ending workday for Brickface Enterprise..." -ForegroundColor Cyan
Write-Host "Date: $(Get-Date)" -ForegroundColor Gray

# Check if we're in the right directory
if (-not (Test-Path "brickface-enterprise.code-workspace")) {
    Write-Host "ERROR: Not in Brickface Enterprise directory" -ForegroundColor Red
    exit 1
}

# Step 1: Check for changes
Write-Host "`nChecking for changes..." -ForegroundColor Blue
$hasChanges = git status --porcelain

if (-not $hasChanges) {
    Write-Host "OK: No changes to save - all caught up!" -ForegroundColor Green
    exit 0
}

# Step 2: Show changes
Write-Host "`nFiles changed:" -ForegroundColor Blue
git status --short

# Step 3: Commit changes
$commitMessage = "feat: End of day save - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Write-Host "`nSaving work..." -ForegroundColor Blue

try {
    git add .
    git commit -m $commitMessage
    Write-Host "OK: Changes committed" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to commit changes" -ForegroundColor Red
    exit 1
}

# Step 4: Push to GitHub
Write-Host "`nSyncing to GitHub..." -ForegroundColor Blue
try {
    git push origin main
    Write-Host "OK: Changes pushed to GitHub" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to push to GitHub" -ForegroundColor Red
}

Write-Host "`nWork saved and synced! Ready for next computer." -ForegroundColor Green
Write-Host "To continue on another computer, just run start-work.ps1" -ForegroundColor Cyan