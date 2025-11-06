#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Stop the Brickface Enterprise Auto-Save Service
.DESCRIPTION
    Gracefully stops the running auto-save background service
#>

$WorkspaceRoot = if (Test-Path "brickface-enterprise.code-workspace") { $PWD } else { Split-Path -Parent $PSScriptRoot }
$PidFile = Join-Path $WorkspaceRoot "auto-save.pid"
$StatusFile = Join-Path $WorkspaceRoot "auto-save-status.json"

Write-Host "🛑 Stopping Brickface Enterprise Auto-Save Service..." -ForegroundColor Yellow

if (Test-Path $PidFile) {
  $ProcessId = Get-Content $PidFile -ErrorAction SilentlyContinue
    
  if ($ProcessId) {
    $Process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
        
    if ($Process) {
      try {
        Stop-Process -Id $ProcessId -Force
        Write-Host "✅ Auto-save service stopped (PID: $ProcessId)" -ForegroundColor Green
      }
      catch {
        Write-Host "❌ Failed to stop process: $($_.Exception.Message)" -ForegroundColor Red
      }
    }
    else {
      Write-Host "⚠️  Process not found (PID: $ProcessId)" -ForegroundColor Yellow
    }
  }
    
  # Clean up PID file
  Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
}
else {
  Write-Host "ℹ️  Auto-save service is not running" -ForegroundColor Cyan
}

# Clean up status file
if (Test-Path $StatusFile) {
  Remove-Item $StatusFile -Force -ErrorAction SilentlyContinue
}

Write-Host "🔄 Auto-save service cleanup complete" -ForegroundColor Green#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Stop the Brickface Enterprise Auto-Save Service
.DESCRIPTION
    Gracefully stops the running auto-save background service
#>

$WorkspaceRoot = if (Test-Path "brickface-enterprise.code-workspace") { $PWD } else { Split-Path -Parent $PSScriptRoot }
$PidFile = Join-Path $WorkspaceRoot "auto-save.pid"
$StatusFile = Join-Path $WorkspaceRoot "auto-save-status.json"

Write-Host "🛑 Stopping Brickface Enterprise Auto-Save Service..." -ForegroundColor Yellow

if (Test-Path $PidFile) {
  $Pid = Get-Content $PidFile -ErrorAction SilentlyContinue
    
  if ($Pid) {
    $Process = Get-Process -Id $Pid -ErrorAction SilentlyContinue
        
    if ($Process) {
      try {
        Stop-Process -Id $Pid -Force
        Write-Host "✅ Auto-save service stopped (PID: $Pid)" -ForegroundColor Green
      }
      catch {
        Write-Host "❌ Failed to stop process: $($_.Exception.Message)" -ForegroundColor Red
      }
    }
    else {
      Write-Host "⚠️  Process not found (PID: $Pid)" -ForegroundColor Yellow
    }
  }
    
  # Clean up PID file
  Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
}
else {
  Write-Host "ℹ️  Auto-save service is not running" -ForegroundColor Cyan
}

# Clean up status file
if (Test-Path $StatusFile) {
  Remove-Item $StatusFile -Force -ErrorAction SilentlyContinue
}

Write-Host "🔄 Auto-save service cleanup complete" -ForegroundColor Green