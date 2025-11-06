#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Enhanced VS Code Integration for Auto-Save
.DESCRIPTION
    Automatically starts auto-save when VS Code workspace opens
    Integrates with VS Code tasks and settings
#>

param(
  [switch]$StartAutoSave,
  [switch]$SetupVSCodeIntegration,
  [switch]$SkipAutoSave,
  [switch]$SkipVSCodeSetup
)

# Set defaults
$StartAutoSave = $StartAutoSave -or (-not $SkipAutoSave)
$SetupVSCodeIntegration = $SetupVSCodeIntegration -or (-not $SkipVSCodeSetup)

$WorkspaceRoot = if (Test-Path "brickface-enterprise.code-workspace") { $PWD } else { Split-Path -Parent $PSScriptRoot }

Write-Host "🎯 Setting up VS Code Auto-Save Integration..." -ForegroundColor Cyan

# =============================================================================
# VS CODE WORKSPACE CONFIGURATION
# =============================================================================

if ($SetupVSCodeIntegration) {
  $workspaceFile = Join-Path $WorkspaceRoot "brickface-enterprise.code-workspace"
    
  if (Test-Path $workspaceFile) {
    try {
      $workspace = Get-Content $workspaceFile | ConvertFrom-Json
            
      # Ensure settings exist
      if (-not $workspace.settings) {
        $workspace | Add-Member -MemberType NoteProperty -Name "settings" -Value @{}
      }
            
      # Add auto-save friendly settings
      $autoSaveSettings = @{
        "files.autoSave"                                 = "onFocusChange"
        "files.autoSaveDelay"                            = 1000
        "git.autofetch"                                  = $true
        "git.autofetchPeriod"                            = 180
        "git.confirmSync"                                = $false
        "git.enableSmartCommit"                          = $true
        "git.suggestSmartCommit"                         = $false
        "extensions.autoUpdate"                          = $true
        "workbench.settings.enableNaturalLanguageSearch" = $true
      }
            
      foreach ($key in $autoSaveSettings.Keys) {
        $workspace.settings.$key = $autoSaveSettings[$key]
      }
            
      # Ensure tasks exist
      if (-not $workspace.tasks) {
        $workspace | Add-Member -MemberType NoteProperty -Name "tasks" -Value @{}
      }
            
      # Add auto-save tasks
      $autoSaveTasks = @{
        "version" = "2.0.0"
        "tasks"   = @(
          @{
            "label"          = "Start Auto-Save"
            "type"           = "shell"
            "command"        = "powershell"
            "args"           = @("-ExecutionPolicy", "Bypass", "-File", "`${workspaceFolder}/auto-save-service.ps1")
            "group"          = "build"
            "presentation"   = @{
              "echo"             = $true
              "reveal"           = "silent"
              "focus"            = $false
              "panel"            = "shared"
              "showReuseMessage" = $true
              "clear"            = $false
            }
            "isBackground"   = $true
            "problemMatcher" = @()
            "runOptions"     = @{
              "runOn" = "folderOpen"
            }
          },
          @{
            "label"        = "Stop Auto-Save"
            "type"         = "shell"
            "command"      = "powershell"
            "args"         = @("-ExecutionPolicy", "Bypass", "-File", "`${workspaceFolder}/stop-auto-save.ps1")
            "group"        = "build"
            "presentation" = @{
              "echo"   = $true
              "reveal" = "always"
              "focus"  = $false
              "panel"  = "shared"
            }
          },
          @{
            "label"        = "Auto-Save Status"
            "type"         = "shell"
            "command"      = "powershell"
            "args"         = @("-Command", "Get-Content `${workspaceFolder}/auto-save-status.json | ConvertFrom-Json | ConvertTo-Json -Depth 3")
            "group"        = "test"
            "presentation" = @{
              "echo"   = $true
              "reveal" = "always"
              "focus"  = $true
              "panel"  = "shared"
            }
          }
        )
      }
            
      $workspace.tasks = $autoSaveTasks
            
      # Save updated workspace
      $workspace | ConvertTo-Json -Depth 10 | Set-Content $workspaceFile
      Write-Host "✅ VS Code workspace updated with auto-save integration" -ForegroundColor Green
            
    }
    catch {
      Write-Host "⚠️  Failed to update VS Code workspace: $($_.Exception.Message)" -ForegroundColor Yellow
    }
  }
}

# =============================================================================
# AUTO-START AUTO-SAVE SERVICE
# =============================================================================

if ($StartAutoSave) {
  # Check if auto-save is already running
  $pidFile = Join-Path $WorkspaceRoot "auto-save.pid"
    
  if (Test-Path $pidFile) {
    $existingPid = Get-Content $pidFile -ErrorAction SilentlyContinue
    if ($existingPid -and (Get-Process -Id $existingPid -ErrorAction SilentlyContinue)) {
      Write-Host "ℹ️  Auto-save service is already running (PID: $existingPid)" -ForegroundColor Cyan
    }
    else {
      # Start auto-save service
      Write-Host "🚀 Starting auto-save service..." -ForegroundColor Blue
      $autoSaveScript = Join-Path $WorkspaceRoot "auto-save-service.ps1"
            
      if (Test-Path $autoSaveScript) {
        # Start in background
        Start-Process -FilePath "powershell" -ArgumentList @(
          "-ExecutionPolicy", "Bypass",
          "-WindowStyle", "Hidden",
          "-File", $autoSaveScript
        ) -NoNewWindow
                
        Write-Host "✅ Auto-save service started in background" -ForegroundColor Green
        Write-Host "   • Changes will be saved automatically every 5 minutes" -ForegroundColor White
        Write-Host "   • Use 'Stop Auto-Save' task or run stop-auto-save.ps1 to stop" -ForegroundColor White
      }
      else {
        Write-Host "❌ Auto-save script not found: $autoSaveScript" -ForegroundColor Red
      }
    }
  }
  else {
    # Start auto-save service
    Write-Host "🚀 Starting auto-save service..." -ForegroundColor Blue
    $autoSaveScript = Join-Path $WorkspaceRoot "auto-save-service.ps1"
        
    if (Test-Path $autoSaveScript) {
      # Start in background
      Start-Process -FilePath "powershell" -ArgumentList @(
        "-ExecutionPolicy", "Bypass",
        "-WindowStyle", "Hidden",
        "-File", $autoSaveScript
      ) -NoNewWindow
            
      Start-Sleep -Seconds 2  # Give it time to start
            
      # Verify it started
      if (Test-Path $pidFile) {
        $newPid = Get-Content $pidFile -ErrorAction SilentlyContinue
        Write-Host "✅ Auto-save service started (PID: $newPid)" -ForegroundColor Green
        Write-Host "   • Changes will be saved automatically every 5 minutes" -ForegroundColor White
        Write-Host "   • Use Ctrl+Shift+P > 'Tasks: Run Task' > 'Stop Auto-Save' to stop" -ForegroundColor White
      }
      else {
        Write-Host "⚠️  Auto-save service may not have started properly" -ForegroundColor Yellow
      }
    }
    else {
      Write-Host "❌ Auto-save script not found: $autoSaveScript" -ForegroundColor Red
    }
  }
}

Write-Host "`n🎉 VS Code Auto-Save Integration Complete!" -ForegroundColor Green
Write-Host "   Your workspace now automatically saves changes in the background" -ForegroundColor Cyan