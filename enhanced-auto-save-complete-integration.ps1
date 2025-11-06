# Enhanced Auto-Save Service with GitKraken Desktop + ClickUp Integration
# Monitors workspace for changes and automates git commits with project management updates

param(
    [switch]$Install,
    [switch]$Start,
    [switch]$Stop,
    [switch]$Status,
    [switch]$Debug
)

# Import environment variables if available
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match "^([^#].+?)=(.+)$") {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

# Configuration
$WorkspacePath = "c:\Users\frede\fred139-project"
$ServiceName = "BrickfaceAutoSave"
$LogFile = Join-Path $WorkspacePath "auto-save.log"
$StatusFile = Join-Path $WorkspacePath "service-status.json"
$GitKrakenPath = "$env:LOCALAPPDATA\gitkraken\Update.exe"
$VSCodeWorkspace = Join-Path $WorkspacePath "brickface-enterprise.code-workspace"

# ClickUp Configuration
$ClickUpToken = $env:CLICKUP_TOKEN
$ClickUpListId = $env:CLICKUP_LIST_ID
$ClickUpTaskId = $env:CLICKUP_TASK_ID

function Write-ServiceLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
}

function Test-GitKrakenInstalled {
    return Test-Path $GitKrakenPath
}

function Install-GitKraken {
    Write-ServiceLog "Installing GitKraken Desktop..."
    try {
        $downloadUrl = "https://release.gitkraken.com/win64/GitKrakenSetup.exe"
        $installerPath = "$env:TEMP\GitKrakenSetup.exe"
        
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath
        Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
        
        Write-ServiceLog "GitKraken Desktop installed successfully"
        return $true
    } catch {
        Write-ServiceLog "Failed to install GitKraken: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Start-GitKraken {
    if (Test-GitKrakenInstalled) {
        try {
            Start-Process -FilePath $GitKrakenPath -ArgumentList "--processStart", "gitkraken.exe", "--process-start-args", "`"$WorkspacePath`""
            Write-ServiceLog "GitKraken Desktop started with workspace"
            return $true
        } catch {
            Write-ServiceLog "Failed to start GitKraken: $($_.Exception.Message)" "ERROR"
            return $false
        }
    } else {
        Write-ServiceLog "GitKraken not installed, attempting installation..." "WARN"
        return Install-GitKraken
    }
}

function Update-ClickUpTask {
    param(
        [string]$Action,
        [string]$Details = ""
    )
    
    if (-not $ClickUpToken -or -not $ClickUpTaskId) {
        Write-ServiceLog "ClickUp configuration missing, skipping task update" "WARN"
        return
    }
    
    try {
        $headers = @{
            "Authorization" = $ClickUpToken
            "Content-Type" = "application/json"
        }
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $comment = "Auto-save: $Action at $timestamp"
        if ($Details) {
            $comment += " - $Details"
        }
        
        $body = @{
            "comment_text" = $comment
            "notify_all" = $false
        } | ConvertTo-Json
        
        $uri = "https://api.clickup.com/api/v2/task/$ClickUpTaskId/comment"
        Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
        
        Write-ServiceLog "ClickUp task updated: $comment"
        
        # Also update time tracking if configured
        $timeBody = @{
            "description" = "Auto-save development work"
            "time" = 300000  # 5 minutes in milliseconds
            "start" = [DateTimeOffset]::UtcNow.AddMinutes(-5).ToUnixTimeMilliseconds()
            "billable" = $true
        } | ConvertTo-Json
        
        $timeUri = "https://api.clickup.com/api/v2/task/$ClickUpTaskId/time"
        Invoke-RestMethod -Uri $timeUri -Method POST -Headers $headers -Body $timeBody
        
        Write-ServiceLog "Time tracking updated in ClickUp"
        
    } catch {
        Write-ServiceLog "Failed to update ClickUp task: $($_.Exception.Message)" "ERROR"
    }
}

function Initialize-GitRepository {
    Set-Location $WorkspacePath
    
    if (-not (Test-Path ".git")) {
        git init
        Write-ServiceLog "Initialized git repository"
    }
    
    # Ensure remote is set
    $remoteUrl = git remote get-url origin 2>$null
    if (-not $remoteUrl) {
        git remote add origin https://github.com/fred139/brickface-enterprise.git
        Write-ServiceLog "Added remote origin"
    }
    
    # Configure git if needed
    $userName = git config user.name 2>$null
    $userEmail = git config user.email 2>$null
    
    if (-not $userName) {
        git config user.name "Brickface Auto-Save"
        Write-ServiceLog "Configured git user name"
    }
    
    if (-not $userEmail) {
        git config user.email "auto-save@brickface.com"
        Write-ServiceLog "Configured git user email"
    }
    
    # Initial commit if needed
    $hasCommits = git log --oneline -1 2>$null
    if (-not $hasCommits) {
        git add .
        git commit -m "Initial auto-save setup with GitKraken + ClickUp integration"
        git push -u origin main
        Write-ServiceLog "Created initial commit and pushed to remote"
    }
}

function Start-AutoSaveService {
    Write-ServiceLog "Starting Enhanced Auto-Save Service with GitKraken + ClickUp Integration"
    
    # Initialize git repository
    Initialize-GitRepository
    
    # Start GitKraken
    Start-GitKraken
    
    # Update status
    $status = @{
        "running" = $true
        "started" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "last_save" = $null
        "save_count" = 0
        "gitkraken_running" = Test-GitKrakenInstalled
        "clickup_configured" = ($null -ne $ClickUpToken -and $null -ne $ClickUpTaskId)
    }
    $status | ConvertTo-Json | Set-Content $StatusFile
    
    # Update ClickUp
    Update-ClickUpTask "Service Started" "Auto-save monitoring initiated with GitKraken integration"
    
    # Create file system watcher
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $WorkspacePath
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true
    
    # Define action for file changes
    $action = {
        param($sender, $eventArgs)
        
        $filePath = $eventArgs.FullPath
        $fileName = Split-Path $filePath -Leaf
        
        # Skip certain files
        if ($fileName -match "\.(log|tmp|temp|cache)$|~\$|\.git\\|node_modules\\|\.vscode\\settings\.json$") {
            return
        }
        
        # Debounce rapid changes (wait 2 seconds)
        Start-Sleep -Seconds 2
        
        try {
            Set-Location $WorkspacePath
            
            # Check for changes
            $status = git status --porcelain
            if ($status) {
                $changedFiles = ($status | ForEach-Object { $_.Substring(3) }) -join ", "
                $commitMessage = "Auto-save: Updated $changedFiles"
                
                git add .
                git commit -m $commitMessage
                git push origin main
                
                Write-ServiceLog "Auto-saved and pushed: $changedFiles"
                
                # Update ClickUp
                Update-ClickUpTask "Files Updated" $changedFiles
                
                # Update status
                $currentStatus = Get-Content $StatusFile | ConvertFrom-Json
                $currentStatus.last_save = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $currentStatus.save_count++
                $currentStatus | ConvertTo-Json | Set-Content $StatusFile
                
                # Refresh GitKraken view
                if (Test-GitKrakenInstalled) {
                    # GitKraken auto-refreshes, but we can trigger a focus event
                    Add-Type -AssemblyName Microsoft.VisualBasic
                    [Microsoft.VisualBasic.Interaction]::AppActivate("GitKraken")
                }
            }
        } catch {
            Write-ServiceLog "Error during auto-save: $($_.Exception.Message)" "ERROR"
        }
    }
    
    # Register event handlers
    Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action
    
    Write-ServiceLog "File system monitoring active. Auto-save service running with GitKraken + ClickUp integration."
    
    # Keep the service running
    try {
        while ($true) {
            Start-Sleep -Seconds 30
            
            # Periodic health check
            $currentStatus = Get-Content $StatusFile | ConvertFrom-Json
            if ($currentStatus.running) {
                Write-ServiceLog "Service health check: OK" "DEBUG"
            }
        }
    } finally {
        # Cleanup on exit
        $watcher.EnableRaisingEvents = $false
        $watcher.Dispose()
        Get-EventSubscriber | Unregister-Event
        
        $status = @{
            "running" = $false
            "stopped" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        $status | ConvertTo-Json | Set-Content $StatusFile
        
        Update-ClickUpTask "Service Stopped" "Auto-save monitoring ended"
        Write-ServiceLog "Auto-save service stopped"
    }
}

function Stop-AutoSaveService {
    Write-ServiceLog "Stopping auto-save service..."
    
    # Kill any running PowerShell processes for this service
    Get-Process | Where-Object { $_.ProcessName -eq "powershell" -and $_.CommandLine -like "*enhanced-auto-save-complete-integration*" } | Stop-Process -Force
    
    $status = @{
        "running" = $false
        "stopped" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    $status | ConvertTo-Json | Set-Content $StatusFile
    
    Update-ClickUpTask "Service Manually Stopped" "Auto-save monitoring manually terminated"
    Write-ServiceLog "Auto-save service stopped"
}

function Get-ServiceStatus {
    if (Test-Path $StatusFile) {
        $status = Get-Content $StatusFile | ConvertFrom-Json
        Write-Host "Auto-Save Service Status:" -ForegroundColor Cyan
        Write-Host "Running: $($status.running)" -ForegroundColor $(if ($status.running) { "Green" } else { "Red" })
        if ($status.started) { Write-Host "Started: $($status.started)" -ForegroundColor Gray }
        if ($status.last_save) { Write-Host "Last Save: $($status.last_save)" -ForegroundColor Gray }
        if ($status.save_count) { Write-Host "Save Count: $($status.save_count)" -ForegroundColor Gray }
        Write-Host "GitKraken Available: $(Test-GitKrakenInstalled)" -ForegroundColor $(if (Test-GitKrakenInstalled) { "Green" } else { "Yellow" })
        Write-Host "ClickUp Configured: $($null -ne $ClickUpToken -and $null -ne $ClickUpTaskId)" -ForegroundColor $(if ($ClickUpToken -and $ClickUpTaskId) { "Green" } else { "Yellow" })
    } else {
        Write-Host "Service not initialized" -ForegroundColor Red
    }
}

# Main execution
switch ($true) {
    $Install {
        Write-Host "Installing Enhanced Auto-Save Service..." -ForegroundColor Green
        # Install as scheduled task for persistence
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$PSCommandPath`" -Start"
        $trigger = New-ScheduledTaskTrigger -AtStartup
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        Register-ScheduledTask -TaskName $ServiceName -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force
        Write-Host "Service installed as scheduled task" -ForegroundColor Green
    }
    $Start {
        Start-AutoSaveService
    }
    $Stop {
        Stop-AutoSaveService
    }
    $Status {
        Get-ServiceStatus
    }
    $Debug {
        $DebugPreference = "Continue"
        Start-AutoSaveService
    }
    default {
        Write-Host "Enhanced Auto-Save Service with GitKraken + ClickUp Integration" -ForegroundColor Cyan
        Write-Host "Usage: .\enhanced-auto-save-complete-integration.ps1 [-Install] [-Start] [-Stop] [-Status] [-Debug]" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor White
        Write-Host "  -Install    Install as Windows scheduled task" -ForegroundColor Gray
        Write-Host "  -Start      Start the auto-save monitoring service" -ForegroundColor Gray
        Write-Host "  -Stop       Stop the auto-save service" -ForegroundColor Gray
        Write-Host "  -Status     Show current service status" -ForegroundColor Gray
        Write-Host "  -Debug      Start with debug logging" -ForegroundColor Gray
        Write-Host ""
        Get-ServiceStatus
    }
}