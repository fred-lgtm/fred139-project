#!/usr/bin/env pwsh

Write-Host "Starting Brickface Enterprise workflow..." -ForegroundColor Cyan
Write-Host "Date: $(Get-Date)" -ForegroundColor Gray

# Check if we're in the right directory
if (-not (Test-Path "brickface-enterprise.code-workspace")) {
    Write-Host "ERROR: Not in Brickface Enterprise directory" -ForegroundColor Red
    exit 1
}

# Step 1: Git Sync
Write-Host "`nSyncing with GitHub..." -ForegroundColor Blue
try {
    git fetch origin main
    git pull origin main
    Write-Host "OK: Repository synced" -ForegroundColor Green
}
catch {
    Write-Host "WARNING: Git sync failed" -ForegroundColor Yellow
}

# Step 2: Environment check
Write-Host "`nChecking environment..." -ForegroundColor Blue
if (-not (Test-Path ".env")) {
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" ".env"
        Write-Host "WARNING: Created .env from template - please edit with your credentials" -ForegroundColor Yellow
    }
}

# Step 3: Open VS Code
Write-Host "`nOpening VS Code workspace..." -ForegroundColor Blue
if (Get-Command "code" -ErrorAction SilentlyContinue) {
    code brickface-enterprise.code-workspace
    Write-Host "OK: VS Code workspace opened" -ForegroundColor Green
}
else {
    Write-Host "WARNING: VS Code not found" -ForegroundColor Yellow
}

Write-Host "`nBrickface Enterprise is ready! Have a productive day!" -ForegroundColor Green