#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Automated daily startup script for Brickface Enterprise
.DESCRIPTION
    Automatically handles git sync, opens workspace, and sets up environment
    NO COMMANDS TO REMEMBER!
#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$SkipSync = $false
)

# Set console title
$Host.UI.RawUI.WindowTitle = "🏢 Brickface Enterprise - Daily Startup"

Write-Host "🚀 Starting Brickface Enterprise Daily Workflow..." -ForegroundColor Cyan
Write-Host "📅 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# Function to show progress
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

# Check if we're in the right directory
if (-not (Test-Path "brickface-enterprise.code-workspace")) {
    Show-Error "Not in Brickface Enterprise directory. Please run from project root."
    exit 1
}

# Step 1: Auto Git Sync (unless skipped)
if (-not $SkipSync) {
    Write-Host "`n📥 Syncing with remote repository..." -ForegroundColor Blue
    
    try {
        # Fetch latest changes
        git fetch origin main 2>$null
        
        # Check if we have any uncommitted changes
        $hasChanges = git status --porcelain
        
        if ($hasChanges) {
            Show-Warning "You have uncommitted changes. Stashing them..."
            git stash push -m "Auto-stash before daily sync - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        }
        
        # Pull latest changes
        git pull origin main
        Show-Progress "Repository synced with latest changes"
        
        # Pop stash if we had changes
        if ($hasChanges) {
            Write-Host "📦 Restoring your work..." -ForegroundColor Blue
            git stash pop
            Show-Progress "Your previous work restored"
        }
        
    }
    catch {
        Show-Error "Git sync failed: $($_.Exception.Message)"
        Show-Warning "Continuing with local version..."
    }
}
else {
    Show-Warning "Skipping git sync (--SkipSync flag used)"
}

# Step 2: Environment Check
Write-Host "`n🔧 Checking environment..." -ForegroundColor Blue

# Check if .env exists
if (-not (Test-Path ".env")) {
    Show-Warning ".env file not found. Creating from template..."
    Copy-Item ".env.example" ".env"
    Show-Warning "Please edit .env file with your credentials before continuing"
    
    # Open .env for editing
    if (Get-Command "code" -ErrorAction SilentlyContinue) {
        code .env
    }
    else {
        notepad .env
    }
    
    Read-Host "Press Enter after editing .env file..."
}

# Check Node.js dependencies
if (Test-Path "package.json") {
    $packageLockExists = Test-Path "package-lock.json"
    $nodeModulesExists = Test-Path "node_modules"
    
    if (-not $nodeModulesExists -or -not $packageLockExists) {
        Write-Host "📦 Installing Node.js dependencies..." -ForegroundColor Blue
        npm install --silent
        Show-Progress "Node.js dependencies installed"
    }
    else {
        Show-Progress "Node.js dependencies up to date"
    }
}

# Check Python dependencies
if (Test-Path "requirements.txt") {
    Write-Host "🐍 Checking Python environment..." -ForegroundColor Blue
    try {
        pip install -r requirements.txt --quiet --disable-pip-version-check
        Show-Progress "Python dependencies up to date"
    }
    catch {
        Show-Warning "Some Python dependencies may need attention"
    }
}

# Step 3: GCP Authentication Check
Write-Host "`n☁️ Checking Google Cloud authentication..." -ForegroundColor Blue
try {
    $gcpAuth = gcloud auth list --format="value(account)" --filter="status:ACTIVE" 2>$null
    if ($gcpAuth) {
        Show-Progress "Google Cloud authenticated as: $gcpAuth"
        
        # Set correct project
        gcloud config set project boxwood-charmer-467423-f0 --quiet
        Show-Progress "GCP project set to: boxwood-charmer-467423-f0"
    }
    else {
        Show-Warning "Google Cloud not authenticated"
        Show-Warning "Run: gcloud auth login"
    }
}
catch {
    Show-Warning "Google Cloud CLI not available"
}

# Step 4: GitHub Authentication Check
Write-Host "`n🐙 Checking GitHub authentication..." -ForegroundColor Blue
try {
    gh auth status 2>$null
    if ($LASTEXITCODE -eq 0) {
        Show-Progress "GitHub authenticated"
    }
    else {
        Show-Warning "GitHub not authenticated. Run: gh auth login"
    }
}
catch {
    Show-Warning "GitHub CLI not available"
}

# Step 5: Open VS Code Workspace
Write-Host "`n🎯 Opening Brickface Enterprise workspace..." -ForegroundColor Blue

if (Get-Command "code" -ErrorAction SilentlyContinue) {
    # Open the workspace
    code brickface-enterprise.code-workspace
    Show-Progress "VS Code workspace opened"
    
    # Wait a moment for VS Code to start
    Start-Sleep -Seconds 2
    
    # Show helpful information
    Write-Host "`n📋 Today's Quick Reference:" -ForegroundColor Magenta
    Write-Host "  • Workspace: 🏢 Brickface Enterprise (multi-folder view)" -ForegroundColor White
    Write-Host "  • MCP Servers: HubSpot, ClickUp, Dialpad, Ramp, Google Workspace" -ForegroundColor White
    Write-Host "  • Cloud Project: boxwood-charmer-467423-f0" -ForegroundColor White
    Write-Host "  • GitLens: Advanced Git features active" -ForegroundColor White
    Write-Host "  • Claude AI: MCP servers auto-connecting" -ForegroundColor White
    
    Write-Host "`n🎉 Ready to work! VS Code is loading your environment..." -ForegroundColor Green
    Write-Host "💡 Tip: All your integrations will connect automatically" -ForegroundColor Cyan
    
}
else {
    Show-Error "VS Code not found in PATH"
    Show-Warning "Please install VS Code or add it to your PATH"
    
    # Alternative: open the folder in Windows Explorer
    if ($IsWindows) {
        explorer .
        Show-Progress "Opened project folder in Explorer"
    }
}

# Step 6: Optional - Check service status
Write-Host "`n🔍 Checking Cloud Run services..." -ForegroundColor Blue
try {
    $services = gcloud run services list --platform=managed --format="value(metadata.name,status.url)" 2>$null
    if ($services) {
        Show-Progress "Active services found:"
        $services | ForEach-Object {
            Write-Host "  • $_" -ForegroundColor Gray
        }
    }
}
catch {
    Show-Warning "Unable to check Cloud Run services"
}

Write-Host "`n✨ Daily startup complete! Have a productive day! ✨" -ForegroundColor Green
Write-Host "📞 Need help? Check the docs folder or ask Claude AI in VS Code" -ForegroundColor Cyan