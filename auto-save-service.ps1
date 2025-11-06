#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Brickface Enterprise - Auto-Save Background Service
.DESCRIPTION
    Automatically saves work periodically without user intervention
    Monitors file changes and commits/pushes to GitHub seamlessly
    
    Features:
    - File change monitoring with debouncing
    - Smart commit batching
    - Background operation
    - Cross-PC conflict resolution
    - Network-aware (only saves when connected)
    
    Author: Fred Ohen
    Date: November 5, 2025
    Version: 1.0
#>

param(
  [Parameter(Mandatory = $false)]
  [int]$SaveIntervalMinutes = 5,
  [Parameter(Mandatory = $false)]
  [int]$MaxCommitsPerHour = 12,
  [Parameter(Mandatory = $false)]
  [switch]$Verbose = $false,
  [Parameter(Mandatory = $false)]
  [switch]$TestMode = $false
)

# Configuration
$ErrorActionPreference = "Continue"
$WorkspaceRoot = if (Test-Path "brickface-enterprise.code-workspace") { $PWD } else { Split-Path -Parent $PSScriptRoot }
$LogFile = Join-Path $WorkspaceRoot "auto-save-$(Get-Date -Format 'yyyy-MM-dd').log"
$StatusFile = Join-Path $WorkspaceRoot "auto-save-status.json"
$PidFile = Join-Path $WorkspaceRoot "auto-save.pid"

# Global state
$LastSaveTime = Get-Date
$CommitCount = 0
$CommitCountResetTime = Get-Date
$FileWatcher = $null
$ChangedFiles = @{}
$IsRunning = $true

# Logging function
function Write-Log {
  param($Message, $Level = "INFO")
  $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $LogEntry = "[$Timestamp] [$Level] $Message"
  Add-Content -Path $LogFile -Value $LogEntry -ErrorAction SilentlyContinue
    
  if ($Verbose -or $Level -eq "ERROR") {
    switch ($Level) {
      "SUCCESS" { Write-Host "✅ $Message" -ForegroundColor Green }
      "ERROR" { Write-Host "❌ $Message" -ForegroundColor Red }
      "WARN" { Write-Host "⚠️  $Message" -ForegroundColor Yellow }
      "INFO" { Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
      default { Write-Host "  $Message" -ForegroundColor Gray }
    }
  }
}

# Check if another instance is running
function Test-AutoSaveRunning {
  if (Test-Path $PidFile) {
    $ExistingPid = Get-Content $PidFile -ErrorAction SilentlyContinue
    if ($ExistingPid -and (Get-Process -Id $ExistingPid -ErrorAction SilentlyContinue)) {
      return $true
    }
  }
  return $false
}

# Network connectivity check
function Test-NetworkConnectivity {
  try {
    $result = Test-NetConnection -ComputerName "github.com" -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue
    return $result
  }
  catch {
    return $false
  }
}

# Check if git repository is clean (no conflicts)
function Test-GitClean {
  try {
    Set-Location $WorkspaceRoot
        
    # Check for merge conflicts
    $conflictFiles = git diff --name-only --diff-filter=U 2>$null
    if ($conflictFiles) {
      Write-Log "Git conflicts detected, skipping auto-save" "WARN"
      return $false
    }
        
    # Check if we're in middle of a merge/rebase
    $gitStatus = git status --porcelain=v1 2>$null
    if ($gitStatus -match "^UU ") {
      Write-Log "Git merge in progress, skipping auto-save" "WARN"
      return $false
    }
        
    return $true
  }
  catch {
    Write-Log "Git status check failed: $($_.Exception.Message)" "ERROR"
    return $false
  }
}

# Smart commit message generation
function Get-SmartCommitMessage {
  param($ChangedFiles)
    
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
  $fileCount = $ChangedFiles.Count
    
  if ($fileCount -eq 0) {
    return "chore: Auto-save checkpoint - $timestamp"
  }
    
  # Analyze file types for better commit messages
  $categories = @{
    code   = @('*.js', '*.ts', '*.py', '*.ps1', '*.json', '*.yaml', '*.yml')
    docs   = @('*.md', '*.txt', '*.rst')
    config = @('*.env*', '*.config*', '*rc*', 'Dockerfile*')
    data   = @('*.csv', '*.xlsx', '*.json', '*.xml')
  }
    
  $changes = @{
    code   = 0
    docs   = 0
    config = 0
    data   = 0
    other  = 0
  }
    
  foreach ($file in $ChangedFiles.Keys) {
    $categorized = $false
    foreach ($category in $categories.Keys) {
      foreach ($pattern in $categories[$category]) {
        if ($file -like $pattern) {
          $changes[$category]++
          $categorized = $true
          break
        }
      }
      if ($categorized) { break }
    }
    if (-not $categorized) {
      $changes.other++
    }
  }
    
  # Generate smart message
  $parts = @()
  if ($changes.code -gt 0) { $parts += "code updates" }
  if ($changes.docs -gt 0) { $parts += "documentation" }
  if ($changes.config -gt 0) { $parts += "configuration" }
  if ($changes.data -gt 0) { $parts += "data files" }
  if ($changes.other -gt 0) { $parts += "misc files" }
    
  $description = if ($parts.Count -gt 0) { $parts -join ", " } else { "file changes" }
    
  return "feat: Auto-save - $description ($fileCount files) - $timestamp"
}

# Perform auto-save operation
function Invoke-AutoSave {
  param($ForceCommit = $false)
    
  Write-Log "Starting auto-save operation..." "INFO"
    
  # Check prerequisites
  if (-not (Test-NetworkConnectivity)) {
    Write-Log "No network connectivity, skipping auto-save" "WARN"
    return $false
  }
    
  if (-not (Test-GitClean)) {
    Write-Log "Git repository not clean, skipping auto-save" "WARN"
    return $false
  }
    
  # Check commit rate limiting
  $hoursSinceReset = (Get-Date).Subtract($CommitCountResetTime).TotalHours
  if ($hoursSinceReset -ge 1) {
    $script:CommitCount = 0
    $script:CommitCountResetTime = Get-Date
  }
    
  if ($CommitCount -ge $MaxCommitsPerHour -and -not $ForceCommit) {
    Write-Log "Rate limit reached ($MaxCommitsPerHour commits/hour), skipping auto-save" "WARN"
    return $false
  }
    
  try {
    Set-Location $WorkspaceRoot
        
    # Check for changes
    $hasChanges = git status --porcelain 2>$null
    if (-not $hasChanges -and -not $ForceCommit) {
      Write-Log "No changes to save" "INFO"
      return $true
    }
        
    # Pull latest changes first to avoid conflicts
    Write-Log "Pulling latest changes from remote..." "INFO"
    git fetch origin main 2>$null
        
    # Check if remote has new commits
    $localCommit = git rev-parse HEAD 2>$null
    $remoteCommit = git rev-parse origin/main 2>$null
        
    if ($localCommit -ne $remoteCommit) {
      Write-Log "Remote has new changes, attempting merge..." "INFO"
            
      # Stash local changes if any
      if ($hasChanges) {
        git stash push -m "Auto-save stash before pull - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" 2>$null
        $stashCreated = $true
      }
            
      # Pull with rebase
      git pull origin main --rebase 2>$null
      if ($LASTEXITCODE -ne 0) {
        Write-Log "Auto-merge failed, manual intervention required" "ERROR"
        return $false
      }
            
      # Restore stashed changes
      if ($stashCreated) {
        git stash pop 2>$null
        if ($LASTEXITCODE -ne 0) {
          Write-Log "Stash pop failed, manual intervention required" "ERROR"
          return $false
        }
      }
    }
        
    # Stage all changes
    git add . 2>$null
        
    # Create commit
    $commitMessage = Get-SmartCommitMessage -ChangedFiles $ChangedFiles
    git commit -m $commitMessage 2>$null
        
    if ($LASTEXITCODE -eq 0) {
      Write-Log "Changes committed: $commitMessage" "SUCCESS"
      $script:CommitCount++
            
      # Push to remote
      git push origin main 2>$null
      if ($LASTEXITCODE -eq 0) {
        Write-Log "Changes pushed to GitHub successfully" "SUCCESS"
        $script:LastSaveTime = Get-Date
        $script:ChangedFiles = @{}
        return $true
      }
      else {
        Write-Log "Failed to push to GitHub" "ERROR"
        return $false
      }
    }
    else {
      Write-Log "No changes to commit or commit failed" "INFO"
      return $true
    }
        
  }
  catch {
    Write-Log "Auto-save failed: $($_.Exception.Message)" "ERROR"
    return $false
  }
}

# File system watcher setup
function Start-FileWatcher {
  if ($FileWatcher) {
    $FileWatcher.Dispose()
  }
    
  try {
    $FileWatcher = New-Object System.IO.FileSystemWatcher
    $FileWatcher.Path = $WorkspaceRoot
    $FileWatcher.IncludeSubdirectories = $true
    $FileWatcher.EnableRaisingEvents = $true
        
    # Filter out temporary and system files
    $FileWatcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::DirectoryName
        
    # Event handlers
    $action = {
      param($sender, $eventArgs)
            
      $file = $eventArgs.FullPath
      $relativePath = $file.Replace($WorkspaceRoot, "").TrimStart('\', '/')
            
      # Skip certain files
      $skipPatterns = @(
        '*.tmp', '*.log', '*.pid', '*.lock',
        '.git\*', 'node_modules\*', '.vscode\*',
        '*.swp', '*~', '.env.local',
        'auto-save-*.log', 'auto-save-status.json'
      )
            
      $shouldSkip = $false
      foreach ($pattern in $skipPatterns) {
        if ($relativePath -like $pattern) {
          $shouldSkip = $true
          break
        }
      }
            
      if (-not $shouldSkip) {
        $script:ChangedFiles[$relativePath] = Get-Date
        Write-Log "File changed: $relativePath" "INFO"
      }
    }
        
    Register-ObjectEvent -InputObject $FileWatcher -EventName "Changed" -Action $action | Out-Null
    Register-ObjectEvent -InputObject $FileWatcher -EventName "Created" -Action $action | Out-Null
    Register-ObjectEvent -InputObject $FileWatcher -EventName "Deleted" -Action $action | Out-Null
    Register-ObjectEvent -InputObject $FileWatcher -EventName "Renamed" -Action $action | Out-Null
        
    Write-Log "File system watcher started" "SUCCESS"
        
  }
  catch {
    Write-Log "Failed to start file watcher: $($_.Exception.Message)" "ERROR"
  }
}

# Status tracking
function Update-Status {
  $status = @{
    timestamp             = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    is_running            = $IsRunning
    last_save             = $LastSaveTime.ToString("yyyy-MM-dd HH:mm:ss")
    commits_this_hour     = $CommitCount
    changed_files         = $ChangedFiles.Count
    workspace_root        = $WorkspaceRoot
    process_id            = $PID
    save_interval_minutes = $SaveIntervalMinutes
    max_commits_per_hour  = $MaxCommitsPerHour
  }
    
  try {
    $status | ConvertTo-Json -Depth 3 | Set-Content $StatusFile
  }
  catch {
    Write-Log "Failed to update status file: $($_.Exception.Message)" "ERROR"
  }
}

# Cleanup function
function Stop-AutoSave {
  Write-Log "Stopping auto-save service..." "INFO"
    
  $script:IsRunning = $false
    
  if ($FileWatcher) {
    $FileWatcher.Dispose()
    Write-Log "File watcher stopped" "INFO"
  }
    
  # Remove event handlers
  Get-EventSubscriber | Unregister-Event -Force
    
  # Remove PID file
  if (Test-Path $PidFile) {
    Remove-Item $PidFile -Force
  }
    
  Write-Log "Auto-save service stopped" "SUCCESS"
}

# Signal handlers
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Stop-AutoSave }

# Trap Ctrl+C
[Console]::TreatControlCAsInput = $false
[Console]::CancelKeyPress += {
  param($sender, $eventArgs)
  $eventArgs.Cancel = $true
  Stop-AutoSave
  exit 0
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

Write-Host @"

🔄 BRICKFACE ENTERPRISE - AUTO-SAVE SERVICE
==========================================
Automatic background save every $SaveIntervalMinutes minutes
Maximum $MaxCommitsPerHour commits per hour

📁 Workspace: $WorkspaceRoot
📝 Log: $LogFile
📊 Status: $StatusFile

"@ -ForegroundColor Cyan

# Check if already running
if (Test-AutoSaveRunning) {
  Write-Log "Auto-save service is already running" "ERROR"
  Write-Host "❌ Another auto-save instance is already running." -ForegroundColor Red
  Write-Host "   Use: Stop-AutoSave.ps1 to stop it first" -ForegroundColor Yellow
  exit 1
}

# Create PID file
$PID | Set-Content $PidFile

Write-Log "Starting Brickface Enterprise Auto-Save Service..." "INFO"
Write-Log "PID: $PID" "INFO"
Write-Log "Save interval: $SaveIntervalMinutes minutes" "INFO"
Write-Log "Max commits per hour: $MaxCommitsPerHour" "INFO"

# Verify we're in the right directory
if (-not (Test-Path (Join-Path $WorkspaceRoot "brickface-enterprise.code-workspace"))) {
  Write-Log "Not in Brickface Enterprise workspace directory" "ERROR"
  exit 1
}

# Initial git check
Set-Location $WorkspaceRoot
try {
  $gitStatus = git status 2>$null
  if ($LASTEXITCODE -ne 0) {
    Write-Log "Not a git repository or git not available" "ERROR"
    exit 1
  }
  Write-Log "Git repository verified" "SUCCESS"
}
catch {
  Write-Log "Git verification failed: $($_.Exception.Message)" "ERROR"
  exit 1
}

# Start file watcher
Start-FileWatcher

# Test mode - run once and exit
if ($TestMode) {
  Write-Log "Test mode: running single auto-save cycle" "INFO"
  $result = Invoke-AutoSave -ForceCommit
  Update-Status
  Write-Log "Test completed. Result: $result" "INFO"
  Stop-AutoSave
  exit 0
}

# Main loop
Write-Log "Auto-save service started successfully" "SUCCESS"
Write-Host "✅ Auto-save service is now running in the background" -ForegroundColor Green
Write-Host "   Changes will be saved every $SaveIntervalMinutes minutes automatically" -ForegroundColor Cyan
Write-Host "   Press Ctrl+C to stop the service" -ForegroundColor Yellow

$saveIntervalSeconds = $SaveIntervalMinutes * 60

while ($IsRunning) {
  try {
    # Update status
    Update-Status
        
    # Check if it's time to save
    $timeSinceLastSave = (Get-Date).Subtract($LastSaveTime).TotalSeconds
        
    if ($timeSinceLastSave -ge $saveIntervalSeconds -or $ChangedFiles.Count -gt 0) {
      $saveResult = Invoke-AutoSave
      if ($saveResult) {
        Write-Log "Auto-save cycle completed successfully" "SUCCESS"
      }
      else {
        Write-Log "Auto-save cycle failed or skipped" "WARN"
      }
    }
        
    # Sleep for a bit before next check
    Start-Sleep -Seconds 30
        
  }
  catch {
    Write-Log "Main loop error: $($_.Exception.Message)" "ERROR"
    Start-Sleep -Seconds 60  # Wait longer on error
  }
}

# Cleanup
Stop-AutoSave