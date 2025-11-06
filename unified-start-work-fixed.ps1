#!/usr/bin/env pwsh

<#
.SYNOPSIS
    UNIFIED Brickface Enterprise Startup - All Features Consolidated
.DESCRIPTION
    GitLab eliminated, redundancy resolved, GitHub-only architecture
#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$SkipSync = $false,
    [Parameter(Mandatory = $false)]
    [switch]$SkipAuth = $false
)

# Set console title
$Host.UI.RawUI.WindowTitle = "Brickface Enterprise - UNIFIED Startup"
Write-Host "UNIFIED Brickface Enterprise Workflow Starting..." -ForegroundColor Cyan
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

function Show-Progress {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Show-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Show-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# Check workspace
if (-not (Test-Path "brickface-enterprise.code-workspace")) {
    Show-Error "Not in Brickface Enterprise directory. Please run from project root."
    exit 1
}

# Authentication checks
if (-not $SkipAuth) {
    Write-Host "`nChecking authentication..." -ForegroundColor Blue
    
    # 1Password CLI
    try {
        op account list 2>$null
        if ($LASTEXITCODE -eq 0) {
            Show-Progress "1Password CLI authenticated"
        } else {
            Show-Warning "1Password CLI not authenticated"
        }
    } catch {
        Show-Warning "1Password CLI not available"
    }

    # Google Cloud
    try {
        gcloud config set project boxwood-charmer-467423-f0 --quiet 2>$null
        Show-Progress "GCP project set"
    } catch {
        Show-Warning "Google Cloud setup incomplete"
    }

    # GitHub
    try {
        gh auth status 2>$null
        if ($LASTEXITCODE -eq 0) {
            Show-Progress "GitHub authenticated"
        } else {
            Show-Warning "GitHub not authenticated"
        }
    } catch {
        Show-Warning "GitHub CLI not available"
    }
}

# Git sync (GitHub-only, GitLab eliminated)
if (-not $SkipSync) {
    Write-Host "`nSyncing with GitHub..." -ForegroundColor Blue
    
    try {
        git fetch origin main 2>$null
        
        $hasChanges = git status --porcelain
        if ($hasChanges) {
            Show-Warning "Stashing uncommitted changes..."
            git stash push -m "Auto-stash before sync - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        }

        git pull origin main
        Show-Progress "Repository synced with GitHub"
        
        if ($hasChanges) {
            git stash pop
            Show-Progress "Previous work restored"
        }

    } catch {
        Show-Error "Git sync failed"
        Show-Warning "Continuing with local version..."
    }
}

# Environment setup
Write-Host "`nEnvironment setup..." -ForegroundColor Blue

if (-not (Test-Path ".env")) {
    Show-Warning ".env file not found. Creating from template..."
    Copy-Item ".env.example" ".env"
    if (Get-Command "code" -ErrorAction SilentlyContinue) {
        code .env
    }
    Read-Host "Press Enter after editing .env file..."
}

# Dependencies
if (Test-Path "package.json") {
    if (-not (Test-Path "node_modules")) {
        Write-Host "Installing Node.js dependencies..." -ForegroundColor Blue
        npm install --silent
        Show-Progress "Node.js dependencies installed"
    } else {
        Show-Progress "Node.js dependencies up to date"
    }
}

# Launch VS Code
Write-Host "`nLaunching VS Code..." -ForegroundColor Blue

if (Get-Command "code" -ErrorAction SilentlyContinue) {
    code brickface-enterprise.code-workspace
    Show-Progress "VS Code workspace opened"
    
    Start-Sleep -Seconds 2
    
    Write-Host "`nUNIFIED System Status:" -ForegroundColor Magenta
    Write-Host "  • Repository: fred139-project (Consolidated)" -ForegroundColor White
    Write-Host "  • Sync: GitHub-only (GitLab eliminated)" -ForegroundColor White
    Write-Host "  • Authentication: Enhanced" -ForegroundColor White
    
    Write-Host "`nUNIFIED startup complete!" -ForegroundColor Green
    
} else {
    Show-Error "VS Code not found in PATH"
    explorer .
}

Write-Host "Ready for cross-PC sync - seamless office/home transition" -ForegroundColor Cyan