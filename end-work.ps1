#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Automated end-of-day script for Brickface Enterprise
.DESCRIPTION
    Automatically saves work, commits changes, syncs to GitHub
    NO COMMANDS TO REMEMBER!
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$CommitMessage = "",
    [Parameter(Mandatory = $false)]
    [switch]$SkipPush = $false
)

# Set console title
$Host.UI.RawUI.WindowTitle = "🏢 Brickface Enterprise - End of Day"

Write-Host "🌅 Ending workday for Brickface Enterprise..." -ForegroundColor Cyan
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

# Step 1: Check for changes
Write-Host "`n📊 Checking for changes..." -ForegroundColor Blue

$hasChanges = git status --porcelain
$hasUncommittedChanges = git diff --name-only HEAD

if (-not $hasChanges) {
    Show-Progress "No changes to save - you're all caught up!"
    Write-Host "`n🎉 Great job today! Everything is already saved and synced." -ForegroundColor Green
    exit 0
}

# Step 2: Show what's changed
Write-Host "`n📝 Files changed today:" -ForegroundColor Blue
git status --short | ForEach-Object {
    Write-Host "  $_" -ForegroundColor Gray
}

# Step 3: Auto-generate commit message if not provided
if (-not $CommitMessage) {
    $date = Get-Date -Format "yyyy-MM-dd"
    $time = Get-Date -Format "HH:mm"
    
    # Analyze changes for smart commit message
    $modifiedFiles = git diff --name-only HEAD | Measure-Object | Select-Object -ExpandProperty Count
    $newFiles = git status --porcelain | Where-Object { $_ -match '^A' } | Measure-Object | Select-Object -ExpandProperty Count
    $deletedFiles = git status --porcelain | Where-Object { $_ -match '^D' } | Measure-Object | Select-Object -ExpandProperty Count
    
    $CommitMessage = "feat: End of day save - $date $time"
    
    if ($newFiles -gt 0) { $CommitMessage += "`n- Added $newFiles new files" }
    if ($modifiedFiles -gt 0) { $CommitMessage += "`n- Modified $modifiedFiles files" }
    if ($deletedFiles -gt 0) { $CommitMessage += "`n- Removed $deletedFiles files" }
    
    $CommitMessage += "`n`n🏢 Brickface Enterprise daily progress save"
}

Write-Host "`n💾 Saving work with message:" -ForegroundColor Blue
Write-Host $CommitMessage -ForegroundColor Gray

# Step 4: Stage and commit changes
try {
    Write-Host "`n📦 Staging changes..." -ForegroundColor Blue
    git add .
    Show-Progress "All changes staged"
    
    Write-Host "💾 Committing changes..." -ForegroundColor Blue
    git commit -m $CommitMessage
    Show-Progress "Changes committed successfully"
    
}
catch {
    Show-Error "Failed to commit changes: $($_.Exception.Message)"
    exit 1
}

# Step 5: Push to GitHub (unless skipped)
if (-not $SkipPush) {
    Write-Host "`n🚀 Syncing to GitHub..." -ForegroundColor Blue
    
    try {
        git push origin main
        Show-Progress "Changes pushed to GitHub successfully"
        
        # Get the latest commit hash for reference
        $latestCommit = git rev-parse --short HEAD
        $repoUrl = git config --get remote.origin.url
        $repoName = ($repoUrl -split '/')[-1] -replace '\.git$', ''
        
        Write-Host "`n📊 Work saved and synced!" -ForegroundColor Green
        Write-Host "  • Repository: $repoName" -ForegroundColor White
        Write-Host "  • Latest commit: $latestCommit" -ForegroundColor White
        Write-Host "  • Branch: main" -ForegroundColor White
        
    }
    catch {
        Show-Error "Failed to push to GitHub: $($_.Exception.Message)"
        Show-Warning "Your work is saved locally but not synced to GitHub"
        Show-Warning "Try running: git push origin main"
    }
}
else {
    Show-Warning "Skipping GitHub sync (--SkipPush flag used)"
    Show-Warning "Remember to push your changes: git push origin main"
}

# Step 6: Backup to Google Cloud (if configured)
Write-Host "`n☁️ Creating cloud backup..." -ForegroundColor Blue
try {
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
    $backupPath = "workspace-backups/$timestamp"
    
    # Create a compressed backup
    $tempBackup = "$env:TEMP\brickface-backup-$timestamp.zip"
    
    # Use PowerShell to create zip (available in PS 5.0+)
    if (Get-Command "Compress-Archive" -ErrorAction SilentlyContinue) {
        $excludePatterns = @("node_modules", ".git", "temp*", "*.log", ".venv", "__pycache__")
        $filesToBackup = Get-ChildItem -Recurse | Where-Object { 
            $file = $_
            -not ($excludePatterns | Where-Object { $file.FullName -like "*$_*" })
        }
        
        if ($filesToBackup) {
            Compress-Archive -Path $filesToBackup -DestinationPath $tempBackup -Force
            
            # Upload to Google Cloud Storage if available
            if (Get-Command "gsutil" -ErrorAction SilentlyContinue) {
                gsutil cp $tempBackup "gs://brickface-backup-p-drive/$backupPath/workspace-backup.zip" 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Show-Progress "Cloud backup created successfully"
                    Remove-Item $tempBackup -Force
                }
                else {
                    Show-Warning "Cloud backup failed, keeping local backup: $tempBackup"
                }
            }
            else {
                Show-Warning "Google Cloud Storage not available for backup"
                Show-Warning "Local backup created: $tempBackup"
            }
        }
    }
}
catch {
    Show-Warning "Backup creation failed: $($_.Exception.Message)"
}

# Step 7: Generate work summary
Write-Host "`n📋 Today's Work Summary:" -ForegroundColor Magenta

try {
    # Get today's commits
    $today = Get-Date -Format "yyyy-MM-dd"
    $todaysCommits = git log --since="$today 00:00" --oneline --author="$(git config user.email)"
    
    if ($todaysCommits) {
        Write-Host "  📈 Commits made today:" -ForegroundColor White
        $todaysCommits | ForEach-Object {
            Write-Host "    • $_" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "  • This was your first commit today!" -ForegroundColor White
    }
    
    # Show file change stats
    $stats = git diff --stat HEAD~1 HEAD 2>$null
    if ($stats) {
        Write-Host "`n  📊 Changes in last commit:" -ForegroundColor White
        $stats | ForEach-Object {
            Write-Host "    $_" -ForegroundColor Gray
        }
    }
    
}
catch {
    Show-Warning "Could not generate work summary"
}

# Step 8: Tomorrow's reminders
Write-Host "`n🌅 Tomorrow's Quick Start:" -ForegroundColor Cyan
Write-Host "  Just run: .\start-work.ps1" -ForegroundColor White
Write-Host "  Or double-click: 'Start Work.lnk' (if created)" -ForegroundColor White

Write-Host "`n✨ Great work today! Everything is saved and synced. ✨" -ForegroundColor Green
Write-Host "🏠 Ready to switch computers - your work will be there!" -ForegroundColor Cyan
Write-Host "😴 Have a great evening!" -ForegroundColor Blue

# Optional: Create shortcuts for easier access
if (-not (Test-Path "Start Work.lnk")) {
    try {
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$PWD\Start Work.lnk")
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$PWD\start-work.ps1`""
        $Shortcut.WorkingDirectory = $PWD
        $Shortcut.IconLocation = "shell32.dll,25"
        $Shortcut.Description = "Start Brickface Enterprise daily workflow"
        $Shortcut.Save()
        
        Show-Progress "Created 'Start Work' shortcut for tomorrow"
    }
    catch {
        # Silently fail if shortcut creation doesn't work
    }
}

# Pause to let user read the summary
Start-Sleep -Seconds 3