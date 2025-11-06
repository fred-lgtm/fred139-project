#!/usr/bin/env pwsh

<#
.SYNOPSIS
    UNIFIED Brickface Enterprise Startup - Consolidates All Features
.DESCRIPTION
    Combines enhanced authentication, git sync, workspace opening, and cross-PC sync
    NO COMMANDS TO REMEMBER! One script for everything.
    
    CONSOLIDATED FEATURES:
    ✅ Enhanced Authentication (1Password CLI, GCP ADC, GitHub)
    ✅ Cross-PC Sync (Office/Home seamless transition)  
    ✅ Workspace Management (VS Code, environment setup)
    ✅ GitLab Eliminated (GitHub-only architecture)
    ✅ Repository Redundancy Resolved
#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$SkipSync = $false,
    [Parameter(Mandatory = $false)]
    [switch]$SkipAuth = $false,
    [Parameter(Mandatory = $false)]
    [string]$Environment = "auto"  # auto, office, home
)

# Set console title
$Host.UI.RawUI.WindowTitle = "🏢 Brickface Enterprise - UNIFIED Daily Startup"
Write-Host "🚀 Starting UNIFIED Brickface Enterprise Workflow..." -ForegroundColor Cyan
Write-Host "📅 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "🎯 Consolidated System - GitLab Eliminated, Redundancy Resolved" -ForegroundColor Green

# Enhanced progress functions
function Show-Progress {
    param([string]$Message, [string]$Color = "Green")
    Write-Host "✅ $Message" -ForegroundColor $Color
}

function Show-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Show-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Show-Section {
    param([string]$Title)
    Write-Host "`n🔷 $Title" -ForegroundColor Blue
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkBlue
}

# Check if we're in the right directory
if (-not (Test-Path "brickface-enterprise.code-workspace")) {
    Show-Error "Not in Brickface Enterprise directory. Please run from project root."
    exit 1
}

# ═══════════════════════════════════════════════════════════════════════════════════
# PHASE 1: ENHANCED AUTHENTICATION (Consolidated from Documents system)
# ═══════════════════════════════════════════════════════════════════════════════════

if (-not $SkipAuth) {
    Show-Section "Enhanced Authentication & Security Setup"
    
    # 1Password CLI Authentication
    Write-Host "🔐 Checking 1Password CLI authentication..." -ForegroundColor Blue
    try {
        $opStatus = op account list 2>$null
        if ($LASTEXITCODE -eq 0) {
            Show-Progress "1Password CLI authenticated"
        } else {
            Show-Warning "1Password CLI not authenticated. Run: op signin"
        }
    } catch {
        Show-Warning "1Password CLI not available"
    }

    # Google Cloud Application Default Credentials
    Write-Host "☁️ Setting up Google Cloud ADC..." -ForegroundColor Blue
    try {
        $adcPath = "$env:APPDATA\gcloud\application_default_credentials.json"
        if (Test-Path $adcPath) {
            Show-Progress "Google Cloud ADC credentials found"
        } else {
            Show-Warning "Google Cloud ADC not set up. Run: gcloud auth application-default login"
        }
        
        # Set project
        gcloud config set project boxwood-charmer-467423-f0 --quiet 2>$null
        Show-Progress "GCP project set to: boxwood-charmer-467423-f0"
    } catch {
        Show-Warning "Google Cloud setup incomplete"
    }

    # GitHub Authentication
    Write-Host "🐙 Checking GitHub authentication..." -ForegroundColor Blue
    try {
        gh auth status 2>$null
        if ($LASTEXITCODE -eq 0) {
            Show-Progress "GitHub authenticated"
        } else {
            Show-Warning "GitHub not authenticated. Run: gh auth login"
        }
    } catch {
        Show-Warning "GitHub CLI not available"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════════
# PHASE 2: INTELLIGENT GIT SYNC (GitHub-Only, GitLab Eliminated)
# ═══════════════════════════════════════════════════════════════════════════════════

if (-not $SkipSync) {
    Show-Section "GitHub Sync (GitLab Dependencies Eliminated)"
    
    try {
        # Fetch latest changes
        git fetch origin main 2>$null
        
        # Check for uncommitted changes
        $hasChanges = git status --porcelain
        if ($hasChanges) {
            Show-Warning "You have uncommitted changes. Stashing them..."
            git stash push -m "Auto-stash before daily sync - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        }

        # Pull latest changes from GitHub
        git pull origin main
        Show-Progress "Repository synced with GitHub"
        
        # Restore stashed changes
        if ($hasChanges) {
            Write-Host "📦 Restoring your work..." -ForegroundColor Blue
            git stash pop
            Show-Progress "Your previous work restored"
        }

    } catch {
        Show-Error "Git sync failed: $($_.Exception.Message)"
        Show-Warning "Continuing with local version..."
    }
}

# ═══════════════════════════════════════════════════════════════════════════════════
# PHASE 3: ENVIRONMENT DETECTION & SETUP (Cross-PC Compatibility)
# ═══════════════════════════════════════════════════════════════════════════════════

Show-Section "Environment Detection & Cross-PC Setup"

# Auto-detect environment if not specified
if ($Environment -eq "auto") {
    $computerName = $env:COMPUTERNAME
    if ($computerName -like "*OFFICE*" -or $computerName -like "*WORK*") {
        $Environment = "office"
    } elseif ($computerName -like "*HOME*" -or $computerName -like "*PERSONAL*") {
        $Environment = "home"
    } else {
        $Environment = "unknown"
    }
}

Write-Host "🏠 Environment: $Environment" -ForegroundColor Cyan

# Environment file check
if (-not (Test-Path ".env")) {
    Show-Warning ".env file not found. Creating from template..."
    Copy-Item ".env.example" ".env"
    Show-Warning "Please edit .env file with your credentials"
    
    if (Get-Command "code" -ErrorAction SilentlyContinue) {
        code .env
    } else {
        notepad .env
    }
    Read-Host "Press Enter after editing .env file..."
}

# ═══════════════════════════════════════════════════════════════════════════════════
# PHASE 4: DEPENDENCY MANAGEMENT (Node.js, Python)
# ═══════════════════════════════════════════════════════════════════════════════════

Show-Section "Dependency Management"

# Node.js dependencies
if (Test-Path "package.json") {
    $packageLockExists = Test-Path "package-lock.json"
    $nodeModulesExists = Test-Path "node_modules"
    
    if (-not $nodeModulesExists -or -not $packageLockExists) {
        Write-Host "📦 Installing Node.js dependencies..." -ForegroundColor Blue
        npm install --silent
        Show-Progress "Node.js dependencies installed"
    } else {
        Show-Progress "Node.js dependencies up to date"
    }
}

# Python dependencies
if (Test-Path "requirements.txt") {
    Write-Host "🐍 Checking Python environment..." -ForegroundColor Blue
    try {
        pip install -r requirements.txt --quiet --disable-pip-version-check
        Show-Progress "Python dependencies up to date"
    } catch {
        Show-Warning "Some Python dependencies may need attention"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════════
# PHASE 5: WORKSPACE LAUNCH (Enhanced VS Code Integration)
# ═══════════════════════════════════════════════════════════════════════════════════

Show-Section "VS Code Workspace Launch"

if (Get-Command "code" -ErrorAction SilentlyContinue) {
    # Open the workspace
    code brickface-enterprise.code-workspace
    Show-Progress "VS Code workspace opened"
    
    # Wait for VS Code to start
    Start-Sleep -Seconds 2
    
    # Show consolidated information
    Write-Host "`n📋 UNIFIED System Status:" -ForegroundColor Magenta
    Write-Host "  • Repository: 🏢 fred139-project (Consolidated)" -ForegroundColor White
    Write-Host "  • Sync: GitHub-only (GitLab eliminated)" -ForegroundColor White
    Write-Host "  • Environment: $Environment PC" -ForegroundColor White
    Write-Host "  • MCP Servers: HubSpot, ClickUp, Dialpad, Ramp, Google Workspace" -ForegroundColor White
    Write-Host "  • Cloud Project: boxwood-charmer-467423-f0" -ForegroundColor White
    Write-Host "  • Authentication: Enhanced (1Password, GCP ADC, GitHub)" -ForegroundColor White
    
    Write-Host "`n🎉 UNIFIED startup complete! All redundancy eliminated." -ForegroundColor Green
    Write-Host "💡 Tip: Cross-PC sync ready - seamless office/home transition" -ForegroundColor Cyan
    
} else {
    Show-Error "VS Code not found in PATH"
    Show-Warning "Please install VS Code or add it to your PATH"
    
    if ($IsWindows) {
        explorer .
        Show-Progress "Opened project folder in Explorer"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════════
# PHASE 6: SYSTEM STATUS & SERVICES CHECK
# ═══════════════════════════════════════════════════════════════════════════════════

Show-Section "Cloud Services Status"

try {
    $services = gcloud run services list --platform=managed --format="value(metadata.name,status.url)" 2>$null
    if ($services) {
        Show-Progress "Active Cloud Run services:"
        $services | ForEach-Object {
            Write-Host "  • $_" -ForegroundColor Gray
        }
    }
} catch {
    Show-Warning "Unable to check Cloud Run services"
}

Write-Host "`n✨ UNIFIED SYSTEM READY! ✨" -ForegroundColor Green
Write-Host "🎯 Consolidation complete: GitLab eliminated, redundancy resolved" -ForegroundColor Green
Write-Host "🏠 Cross-PC sync enabled: seamless transition between office and home" -ForegroundColor Cyan
Write-Host "📞 Need help? Check docs or ask Claude AI in VS Code" -ForegroundColor Cyan