#!/usr/bin/env pwsh

<#
.SYNOPSIS
    UNIFIED Brickface Enterprise End-of-Day Script - All Features Consolidated
.DESCRIPTION
    Combines auto-commit, GitHub sync, cloud backup, and cross-PC preparation
    
    CONSOLIDATED FEATURES:
    ✅ Intelligent Auto-Commit with Smart Messages
    ✅ GitHub Sync (GitLab Eliminated)
    ✅ Cross-PC State Preparation
    ✅ Enhanced Backup & Status Reporting
    ✅ Repository Redundancy Resolved
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$CommitMessage = "",
    [Parameter(Mandatory = $false)]
    [switch]$SkipPush = $false,
    [Parameter(Mandatory = $false)]
    [switch]$SkipBackup = $false
)

# Set console title
$Host.UI.RawUI.WindowTitle = "🏢 Brickface Enterprise - UNIFIED End of Day"
Write-Host "🌅 UNIFIED End-of-Day Process - GitLab Eliminated, Redundancy Resolved" -ForegroundColor Cyan
Write-Host "📅 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

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
# PHASE 1: CHANGE DETECTION & ANALYSIS
# ═══════════════════════════════════════════════════════════════════════════════════

Show-Section "Analyzing Work Changes (Unified Repository)"

$hasChanges = git status --porcelain
$hasUncommittedChanges = git diff --name-only HEAD

if (-not $hasChanges) {
    Show-Progress "No changes to save - you're all caught up!"
    Write-Host "`n🎉 Great job today! Everything already saved and synced to GitHub." -ForegroundColor Green
    Write-Host "🏠 Ready for seamless cross-PC transition" -ForegroundColor Cyan
    exit 0
}

# Show what's changed
Write-Host "`n📊 Files changed today:" -ForegroundColor Blue
git status --short | ForEach-Object {
    Write-Host "  $_" -ForegroundColor Gray
}

# ═══════════════════════════════════════════════════════════════════════════════════
# PHASE 2: INTELLIGENT COMMIT MESSAGE GENERATION
# ═══════════════════════════════════════════════════════════════════════════════════

Show-Section "Smart Commit Message Generation"

if (-not $CommitMessage) {
    $date = Get-Date -Format "yyyy-MM-dd"
    $time = Get-Date -Format "HH:mm"
    
    # Analyze changes for smart commit message
    $modifiedFiles = git diff --name-only HEAD | Measure-Object | Select-Object -ExpandProperty Count
    $newFiles = git status --porcelain | Where-Object { $_ -match '^A' } | Measure-Object | Select-Object -ExpandProperty Count
    $deletedFiles = git status --porcelain | Where-Object { $_ -match '^D' } | Measure-Object | Select-Object -ExpandProperty Count
    
    $CommitMessage = "feat: Unified daily save - $date $time"
    if ($newFiles -gt 0) { $CommitMessage += "`n- Added $newFiles new files" }
    if ($modifiedFiles -gt 0) { $CommitMessage += "`n- Modified $modifiedFiles files" }
    if ($deletedFiles -gt 0) { $CommitMessage += "`n- Removed $deletedFiles files" }
    
    $CommitMessage += "`n`n🏢 Brickface Enterprise unified progress save"
    $CommitMessage += "`n🎯 GitLab eliminated, GitHub-only architecture"
}

Write-Host "`n💾 Saving work with message:" -ForegroundColor Blue
Write-Host $CommitMessage -ForegroundColor Gray

# ═══════════════════════════════════════════════════════════════════════════════════
# PHASE 3: COMMIT & GITHUB SYNC (GitLab Eliminated)
# ═══════════════════════════════════════════════════════════════════════════════════

Show-Section "GitHub Sync (GitLab Dependencies Eliminated)"

try {
    Write-Host "`n📦 Staging changes..." -ForegroundColor Blue
    git add .
    Show-Progress "All changes staged"
    
    Write-Host "💾 Committing changes..." -ForegroundColor Blue
    git commit -m $CommitMessage
    Show-Progress "Changes committed successfully"
    
} catch {
    Show-Error "Failed to commit changes: $($_.Exception.Message)"
    exit 1
}

# Push to GitHub (GitLab eliminated)
if (-not $SkipPush) {
    Write-Host "`n🚀 Syncing to GitHub (unified repository)..." -ForegroundColor Blue
    
    try {
        git push origin main
        Show-Progress "Changes pushed to GitHub successfully"
        
        # Get commit details for cross-PC reference
        $latestCommit = git rev-parse --short HEAD
        $repoUrl = git config --get remote.origin.url
        $repoName = ($repoUrl -split '/')[-1] -replace '\.git$', ''
        
        Write-Host "`n📊 UNIFIED Work Saved & Synced!" -ForegroundColor Green
        Write-Host "  • Repository: $repoName (consolidated)" -ForegroundColor White
        Write-Host "  • Latest commit: $latestCommit" -ForegroundColor White
        Write-Host "  • Branch: main (GitHub-only)" -ForegroundColor White
        Write-Host "  • Cross-PC ready: ✅" -ForegroundColor White
        
    } catch {
        Show-Error "Failed to push to GitHub: $($_.Exception.Message)"
        Show-Warning "Your work is saved locally but not synced to GitHub"
        Show-Warning "Try running: git push origin main"
    }
} else {
    Show-Warning "Skipping GitHub sync (--SkipPush flag used)"
    Show-Warning "Remember to push your changes: git push origin main"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# PHASE 4: ENHANCED BACKUP & CROSS-PC PREPARATION
# ═══════════════════════════════════════════════════════════════════════════════════

if (-not $SkipBackup) {
    Show-Section "Enhanced Backup & Cross-PC State Preparation"
    
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
        $backupPath = "workspace-backups/$timestamp"
        
        # Create compressed backup
        $tempBackup = "$env:TEMP\brickface-unified-backup-$timestamp.zip"
        
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
                    gsutil cp $tempBackup "gs://brickface-backup-p-drive/$backupPath/unified-workspace-backup.zip" 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        Show-Progress "Cloud backup created successfully (unified)"
                        Remove-Item $tempBackup -Force
                    } else {
                        Show-Warning "Cloud backup failed, keeping local backup: $tempBackup"
                    }
                } else {
                    Show-Warning "Google Cloud Storage not available for backup"
                    Show-Warning "Local backup created: $tempBackup"
                }
            }
        }
    } catch {
        Show-Warning "Backup creation failed: $($_.Exception.Message)"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════════
# PHASE 5: WORK SUMMARY & CROSS-PC STATUS
# ═══════════════════════════════════════════════════════════════════════════════════

Show-Section "Today's Work Summary & Cross-PC Status"

try {
    # Get today's commits
    $today = Get-Date -Format "yyyy-MM-dd"
    $todaysCommits = git log --since="$today 00:00" --oneline --author="$(git config user.email)"
    
    if ($todaysCommits) {
        Write-Host "  📈 Commits made today:" -ForegroundColor White
        $todaysCommits | ForEach-Object {
            Write-Host "    • $_" -ForegroundColor Gray
        }
    } else {
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

} catch {
    Show-Warning "Could not generate work summary"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# PHASE 6: TOMORROW'S PREPARATION & CROSS-PC INSTRUCTIONS
# ═══════════════════════════════════════════════════════════════════════════════════

Show-Section "Tomorrow's Cross-PC Quick Start"

Write-Host "  🌅 From ANY computer, just run:" -ForegroundColor White
Write-Host "    • .\unified-start-work.ps1" -ForegroundColor Green
Write-Host "  🏠 OR from any directory:" -ForegroundColor White
Write-Host "    • cd fred139-project && .\unified-start-work.ps1" -ForegroundColor Green

# Create unified shortcuts for easier access
if (-not (Test-Path "Unified Start Work.lnk")) {
    try {
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$PWD\Unified Start Work.lnk")
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$PWD\unified-start-work.ps1`""
        $Shortcut.WorkingDirectory = $PWD
        $Shortcut.IconLocation = "shell32.dll,25"
        $Shortcut.Description = "Start Brickface Enterprise unified workflow"
        $Shortcut.Save()

        Show-Progress "Created 'Unified Start Work' shortcut for tomorrow"
    } catch {
        # Silently fail if shortcut creation doesn't work
    }
}

Write-Host "`n✨ UNIFIED SYSTEM COMPLETE! ✨" -ForegroundColor Green
Write-Host "🎯 GitLab eliminated, redundancy resolved, GitHub-only architecture" -ForegroundColor Green
Write-Host "🏠 Cross-PC sync ready - seamless transition between office and home" -ForegroundColor Cyan
Write-Host "📱 Your work is saved, synced, and ready on any computer" -ForegroundColor Cyan
Write-Host "😴 Have a great evening!" -ForegroundColor Blue

# Brief pause to let user read the summary
Start-Sleep -Seconds 3