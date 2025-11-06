#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Complete Home PC Setup for Brickface Enterprise Cross-PC Sync
.DESCRIPTION
    One-click script to sync your entire work environment from Office PC to Home PC
    Handles: Git clone, environment setup, VS Code workspace, authentication
    
    USAGE: Just copy this file to your Home PC and run it!
    
    Author: Fred Ohen
    Date: November 5, 2025
    Version: 1.0
#>

param(
  [Parameter(Mandatory = $false)]
  [string]$HomePCWorkspaceRoot = "C:\Users\$env:USERNAME\fred139-project",
  [Parameter(Mandatory = $false)]
  [string]$GitHubRepo = "https://github.com/fred-lgtm/fred139-project.git",
  [Parameter(Mandatory = $false)]
  [switch]$SkipGitClone = $false,
  [Parameter(Mandatory = $false)]
  [switch]$Verbose = $false
)

# Set console title and colors
$Host.UI.RawUI.WindowTitle = "🏠 Brickface Enterprise - Home PC Setup"

Write-Host @"

🏠🔄🏢 BRICKFACE ENTERPRISE - HOME PC SETUP
================================================
Syncing your complete work environment...
Office PC → Home PC seamless workflow

📅 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

"@ -ForegroundColor Cyan

# Configuration
$ErrorActionPreference = "Continue"
$LogFile = Join-Path $env:TEMP "brickface-home-setup-$(Get-Date -Format 'yyyy-MM-dd-HHmm').log"

# Logging function
function Write-Log {
  param($Message, $Level = "INFO")
  $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $LogEntry = "[$Timestamp] [$Level] $Message"
  Add-Content -Path $LogFile -Value $LogEntry
    
  switch ($Level) {
    "SUCCESS" { Write-Host "✅ $Message" -ForegroundColor Green }
    "ERROR" { Write-Host "❌ $Message" -ForegroundColor Red }
    "WARN" { Write-Host "⚠️  $Message" -ForegroundColor Yellow }
    "INFO" { Write-Host "ℹ️  $Message" -ForegroundColor White }
    "STEP" { Write-Host "🔸 $Message" -ForegroundColor Blue }
    default { Write-Host "  $Message" -ForegroundColor Gray }
  }
}

# Progress tracking
$SetupStatus = @{
  timestamp       = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  steps_completed = @()
  steps_failed    = @()
  warnings        = @()
  home_pc_ready   = $false
}

Write-Log "Starting Brickface Enterprise Home PC Setup..." "STEP"
Write-Log "Target workspace: $HomePCWorkspaceRoot" "INFO"
Write-Log "Log file: $LogFile" "INFO"

# =============================================================================
# STEP 1: PREREQUISITES CHECK
# =============================================================================

Write-Log "Checking prerequisites..." "STEP"

# Check if Git is installed
try {
  $gitVersion = git --version 2>$null
  if ($gitVersion) {
    Write-Log "Git: $gitVersion" "SUCCESS"
    $SetupStatus.steps_completed += "git_check"
  }
  else {
    Write-Log "Git not found. Please install Git for Windows first: https://git-scm.com/download/win" "ERROR"
    $SetupStatus.steps_failed += "git_missing"
    exit 1
  }
}
catch {
  Write-Log "Git check failed: $($_.Exception.Message)" "ERROR"
  $SetupStatus.steps_failed += "git_check"
  exit 1
}

# Check if PowerShell version is sufficient
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -ge 5) {
  Write-Log "PowerShell: v$($psVersion)" "SUCCESS"
  $SetupStatus.steps_completed += "powershell_check"
}
else {
  Write-Log "PowerShell 5.0+ required. Current: v$($psVersion)" "ERROR"
  $SetupStatus.steps_failed += "powershell_version"
  exit 1
}

# Check if VS Code is available
try {
  $codeVersion = code --version 2>$null
  if ($codeVersion) {
    Write-Log "VS Code: Available" "SUCCESS"
    $SetupStatus.steps_completed += "vscode_check"
  }
  else {
    Write-Log "VS Code not found in PATH. Installing recommended." "WARN"
    $SetupStatus.warnings += "VS Code not in PATH - recommend installing from https://code.visualstudio.com/"
  }
}
catch {
  Write-Log "VS Code not available - recommend installing" "WARN"
  $SetupStatus.warnings += "VS Code installation recommended"
}

# =============================================================================
# STEP 2: WORKSPACE DIRECTORY SETUP
# =============================================================================

Write-Log "Setting up workspace directory..." "STEP"

# Create parent directory if it doesn't exist
$ParentDir = Split-Path -Parent $HomePCWorkspaceRoot
if (-not (Test-Path $ParentDir)) {
  try {
    New-Item -ItemType Directory -Path $ParentDir -Force | Out-Null
    Write-Log "Created parent directory: $ParentDir" "SUCCESS"
    $SetupStatus.steps_completed += "parent_dir_created"
  }
  catch {
    Write-Log "Failed to create parent directory: $($_.Exception.Message)" "ERROR"
    $SetupStatus.steps_failed += "parent_dir_creation"
    exit 1
  }
}

# Check if workspace already exists
if (Test-Path $HomePCWorkspaceRoot) {
  if (-not $SkipGitClone) {
    Write-Log "Workspace directory already exists: $HomePCWorkspaceRoot" "WARN"
    Write-Host "   Options:" -ForegroundColor Yellow
    Write-Host "   1. Backup existing and fresh clone (recommended)" -ForegroundColor Yellow
    Write-Host "   2. Update existing repository" -ForegroundColor Yellow
    Write-Host "   3. Cancel setup" -ForegroundColor Yellow
        
    $choice = Read-Host "Enter choice (1-3)"
        
    switch ($choice) {
      "1" {
        $backupPath = "$HomePCWorkspaceRoot-backup-$(Get-Date -Format 'yyyy-MM-dd-HHmm')"
        try {
          Move-Item $HomePCWorkspaceRoot $backupPath
          Write-Log "Existing workspace backed up to: $backupPath" "SUCCESS"
          $SetupStatus.steps_completed += "workspace_backup"
        }
        catch {
          Write-Log "Failed to backup existing workspace: $($_.Exception.Message)" "ERROR"
          $SetupStatus.steps_failed += "workspace_backup"
          exit 1
        }
      }
      "2" {
        $SkipGitClone = $true
        Write-Log "Will update existing repository instead of fresh clone" "INFO"
        $SetupStatus.steps_completed += "workspace_update_mode"
      }
      "3" {
        Write-Log "Setup cancelled by user" "INFO"
        exit 0
      }
      default {
        Write-Log "Invalid choice. Exiting..." "ERROR"
        exit 1
      }
    }
  }
}

# =============================================================================
# STEP 3: GIT REPOSITORY CLONE/UPDATE
# =============================================================================

Write-Log "Syncing repository from GitHub..." "STEP"

if (-not $SkipGitClone) {
  # Fresh clone
  try {
    Set-Location $ParentDir
    git clone $GitHubRepo (Split-Path -Leaf $HomePCWorkspaceRoot) --progress
        
    if ($LASTEXITCODE -eq 0) {
      Write-Log "Repository cloned successfully from GitHub" "SUCCESS"
      $SetupStatus.steps_completed += "git_clone"
    }
    else {
      Write-Log "Git clone failed with exit code: $LASTEXITCODE" "ERROR"
      $SetupStatus.steps_failed += "git_clone"
      exit 1
    }
  }
  catch {
    Write-Log "Git clone failed: $($_.Exception.Message)" "ERROR"
    $SetupStatus.steps_failed += "git_clone"
    exit 1
  }
}
else {
  # Update existing repository
  try {
    Set-Location $HomePCWorkspaceRoot
        
    # Check if it's a git repository
    $isGitRepo = git rev-parse --is-inside-work-tree 2>$null
    if ($isGitRepo -eq "true") {
      # Stash any local changes
      $hasChanges = git status --porcelain
      if ($hasChanges) {
        git stash push -m "Auto-stash before Home PC sync - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        Write-Log "Local changes stashed" "INFO"
      }
            
      # Pull latest changes
      git fetch origin main
      git pull origin main --rebase
            
      if ($LASTEXITCODE -eq 0) {
        Write-Log "Repository updated from GitHub" "SUCCESS"
        $SetupStatus.steps_completed += "git_update"
                
        # Restore stashed changes if any
        if ($hasChanges) {
          git stash pop
          Write-Log "Local changes restored" "INFO"
        }
      }
      else {
        Write-Log "Git pull failed with exit code: $LASTEXITCODE" "ERROR"
        $SetupStatus.steps_failed += "git_update"
      }
    }
    else {
      Write-Log "Existing directory is not a git repository. Converting..." "WARN"
      git init
      git remote add origin $GitHubRepo
      git fetch origin main
      git reset --hard origin/main
      Write-Log "Directory converted to git repository and synced" "SUCCESS"
      $SetupStatus.steps_completed += "git_convert"
    }
  }
  catch {
    Write-Log "Git update failed: $($_.Exception.Message)" "ERROR"
    $SetupStatus.steps_failed += "git_update"
  }
}

# =============================================================================
# STEP 4: GIT CONFIGURATION SETUP
# =============================================================================

Write-Log "Configuring Git user settings..." "STEP"

try {
  Set-Location $HomePCWorkspaceRoot
    
  # Set user configuration
  git config user.email "fred@brickface.com"
  git config user.name "Fred Ohen"
    
  # Verify configuration
  $gitEmail = git config user.email
  $gitName = git config user.name
    
  if ($gitEmail -eq "fred@brickface.com" -and $gitName -eq "Fred Ohen") {
    Write-Log "Git user configured: $gitName <$gitEmail>" "SUCCESS"
    $SetupStatus.steps_completed += "git_config"
  }
  else {
    Write-Log "Git configuration verification failed" "ERROR"
    $SetupStatus.steps_failed += "git_config"
  }
}
catch {
  Write-Log "Git configuration failed: $($_.Exception.Message)" "ERROR"
  $SetupStatus.steps_failed += "git_config"
}

# =============================================================================
# STEP 5: ENVIRONMENT FILE SETUP
# =============================================================================

Write-Log "Setting up environment configuration..." "STEP"

$envFile = Join-Path $HomePCWorkspaceRoot ".env"
$envExample = Join-Path $HomePCWorkspaceRoot ".env.example"

if (Test-Path $envExample) {
  if (-not (Test-Path $envFile)) {
    try {
      Copy-Item $envExample $envFile
      Write-Log "Created .env file from template" "SUCCESS"
      $SetupStatus.steps_completed += "env_file_created"
            
      Write-Log "IMPORTANT: Edit .env file with your credentials" "WARN"
      $SetupStatus.warnings += "Edit .env file with your actual API keys and credentials"
    }
    catch {
      Write-Log "Failed to create .env file: $($_.Exception.Message)" "ERROR"
      $SetupStatus.steps_failed += "env_file_creation"
    }
  }
  else {
    Write-Log ".env file already exists" "INFO"
    $SetupStatus.steps_completed += "env_file_exists"
  }
}
else {
  Write-Log ".env.example template not found" "WARN"
  $SetupStatus.warnings += ".env.example template missing"
}

# =============================================================================
# STEP 6: NODE.JS DEPENDENCIES
# =============================================================================

Write-Log "Installing Node.js dependencies..." "STEP"

$packageJson = Join-Path $HomePCWorkspaceRoot "package.json"
if (Test-Path $packageJson) {
  try {
    Set-Location $HomePCWorkspaceRoot
        
    # Check if npm is available
    $npmVersion = npm --version 2>$null
    if ($npmVersion) {
      Write-Log "npm: v$npmVersion" "INFO"
            
      # Install dependencies
      npm install --silent --no-fund --no-audit
            
      if ($LASTEXITCODE -eq 0) {
        Write-Log "Node.js dependencies installed successfully" "SUCCESS"
        $SetupStatus.steps_completed += "npm_install"
      }
      else {
        Write-Log "npm install failed" "ERROR"
        $SetupStatus.steps_failed += "npm_install"
      }
    }
    else {
      Write-Log "npm not found. Please install Node.js: https://nodejs.org/" "WARN"
      $SetupStatus.warnings += "Node.js installation required for full functionality"
    }
  }
  catch {
    Write-Log "Node.js dependency installation failed: $($_.Exception.Message)" "ERROR"
    $SetupStatus.steps_failed += "npm_install"
  }
}
else {
  Write-Log "No package.json found, skipping Node.js dependencies" "INFO"
}

# =============================================================================
# STEP 7: PYTHON ENVIRONMENT SETUP
# =============================================================================

Write-Log "Checking Python environment..." "STEP"

$requirementsTxt = Join-Path $HomePCWorkspaceRoot "requirements.txt"
if (Test-Path $requirementsTxt) {
  try {
    # Check if python is available
    $pythonVersion = python --version 2>$null
    if ($pythonVersion) {
      Write-Log "Python: $pythonVersion" "INFO"
            
      # Install requirements
      python -m pip install -r $requirementsTxt --quiet --disable-pip-version-check
            
      if ($LASTEXITCODE -eq 0) {
        Write-Log "Python dependencies installed successfully" "SUCCESS"
        $SetupStatus.steps_completed += "python_install"
      }
      else {
        Write-Log "Python dependency installation failed" "WARN"
        $SetupStatus.warnings += "Python dependency installation needs attention"
      }
    }
    else {
      Write-Log "Python not found. Some features may not work." "WARN"
      $SetupStatus.warnings += "Python installation recommended for full functionality"
    }
  }
  catch {
    Write-Log "Python environment setup failed: $($_.Exception.Message)" "WARN"
    $SetupStatus.warnings += "Python environment needs manual setup"
  }
}
else {
  Write-Log "No requirements.txt found, skipping Python dependencies" "INFO"
}

# =============================================================================
# STEP 8: VS CODE WORKSPACE SETUP
# =============================================================================

Write-Log "Setting up VS Code workspace..." "STEP"

$workspaceFile = Join-Path $HomePCWorkspaceRoot "brickface-enterprise.code-workspace"
if (Test-Path $workspaceFile) {
  Write-Log "VS Code workspace file found" "SUCCESS"
  $SetupStatus.steps_completed += "vscode_workspace"
    
  # Check if VS Code is available and offer to open
  try {
    $codeAvailable = Get-Command "code" -ErrorAction SilentlyContinue
    if ($codeAvailable) {
      Write-Host "`n🎯 Would you like to open the workspace in VS Code now? (y/n): " -ForegroundColor Yellow -NoNewline
      $openVSCode = Read-Host
            
      if ($openVSCode -eq "y" -or $openVSCode -eq "Y" -or $openVSCode -eq "yes") {
        code $workspaceFile
        Write-Log "VS Code workspace opened" "SUCCESS"
        $SetupStatus.steps_completed += "vscode_opened"
      }
      else {
        Write-Log "VS Code opening skipped by user" "INFO"
      }
    }
    else {
      Write-Log "VS Code not in PATH. You can manually open: $workspaceFile" "INFO"
    }
  }
  catch {
    Write-Log "VS Code setup failed: $($_.Exception.Message)" "WARN"
    $SetupStatus.warnings += "VS Code setup needs manual attention"
  }
}
else {
  Write-Log "VS Code workspace file not found" "WARN"
  $SetupStatus.warnings += "VS Code workspace file missing"
}

# =============================================================================
# STEP 9: CREATE HOME PC SCRIPTS
# =============================================================================

Write-Log "Creating Home PC workflow scripts..." "STEP"

try {
  # Create start-work shortcut for Home PC
  $startWorkScript = @"
#!/usr/bin/env pwsh

# Brickface Enterprise - Home PC Start Work
# Auto-generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Set-Location "$HomePCWorkspaceRoot"

Write-Host "🏠 Starting Brickface Enterprise on Home PC..." -ForegroundColor Cyan

# Git sync
Write-Host "📥 Syncing with GitHub..." -ForegroundColor Blue
git fetch origin main
git pull origin main --rebase

# Run the main start work script
if (Test-Path "start-work.ps1") {
    & .\start-work.ps1
} else {
    Write-Host "✅ Workspace ready!" -ForegroundColor Green
    if (Get-Command "code" -ErrorAction SilentlyContinue) {
        code brickface-enterprise.code-workspace
    }
}
"@

  $homeStartScript = Join-Path $HomePCWorkspaceRoot "start-work-home.ps1"
  Set-Content -Path $homeStartScript -Value $startWorkScript
  Write-Log "Created Home PC start script: start-work-home.ps1" "SUCCESS"
  $SetupStatus.steps_completed += "home_scripts"

  # Create end-work script that syncs back to GitHub
  $endWorkScript = @"
#!/usr/bin/env pwsh

# Brickface Enterprise - Home PC End Work
# Auto-generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Set-Location "$HomePCWorkspaceRoot"

Write-Host "🏠 Ending work session on Home PC..." -ForegroundColor Cyan

# Run the main end work script
if (Test-Path "end-work.ps1") {
    & .\end-work.ps1
} else {
    # Fallback manual save
    Write-Host "💾 Saving work..." -ForegroundColor Blue
    git add .
    git commit -m "Work session end - Home PC - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    git push origin main
    Write-Host "✅ Work saved and synced to GitHub!" -ForegroundColor Green
}

Write-Host "🏢 Ready to continue on Office PC!" -ForegroundColor Cyan
"@

  $homeEndScript = Join-Path $HomePCWorkspaceRoot "end-work-home.ps1"
  Set-Content -Path $homeEndScript -Value $endWorkScript
  Write-Log "Created Home PC end script: end-work-home.ps1" "SUCCESS"

}
catch {
  Write-Log "Failed to create Home PC scripts: $($_.Exception.Message)" "ERROR"
  $SetupStatus.steps_failed += "home_scripts"
}

# =============================================================================
# STEP 10: FINAL VERIFICATION
# =============================================================================

Write-Log "Running final verification..." "STEP"

# Verify workspace structure
$criticalFiles = @(
  "brickface-enterprise.code-workspace",
  "package.json",
  ".env.example",
  "README.md"
)

$missingFiles = @()
foreach ($file in $criticalFiles) {
  $filePath = Join-Path $HomePCWorkspaceRoot $file
  if (-not (Test-Path $filePath)) {
    $missingFiles += $file
  }
}

if ($missingFiles.Count -eq 0) {
  Write-Log "All critical files present" "SUCCESS"
  $SetupStatus.steps_completed += "file_verification"
}
else {
  Write-Log "Missing files: $($missingFiles -join ', ')" "WARN"
  $SetupStatus.warnings += "Some workspace files are missing"
}

# Check git repository status
try {
  Set-Location $HomePCWorkspaceRoot
  $gitStatus = git status --porcelain
  $currentBranch = git branch --show-current
    
  Write-Log "Git repository ready (branch: $currentBranch)" "SUCCESS"
  $SetupStatus.steps_completed += "git_verification"
    
  if ($gitStatus) {
    Write-Log "Note: Workspace has uncommitted changes" "INFO"
  }
}
catch {
  Write-Log "Git verification failed: $($_.Exception.Message)" "ERROR"
  $SetupStatus.steps_failed += "git_verification"
}

# =============================================================================
# SETUP COMPLETE - SUMMARY
# =============================================================================

$SetupStatus.home_pc_ready = ($SetupStatus.steps_failed.Count -eq 0)

Write-Host @"

🎉 BRICKFACE ENTERPRISE HOME PC SETUP COMPLETE!
================================================

"@ -ForegroundColor Green

# Summary statistics
$totalSteps = $SetupStatus.steps_completed.Count + $SetupStatus.steps_failed.Count
$successRate = if ($totalSteps -gt 0) { [math]::Round(($SetupStatus.steps_completed.Count / $totalSteps) * 100, 1) } else { 0 }

Write-Log "Setup Summary:" "STEP"
Write-Log "✅ Steps completed: $($SetupStatus.steps_completed.Count)" "SUCCESS"
Write-Log "❌ Steps failed: $($SetupStatus.steps_failed.Count)" "ERROR"
Write-Log "⚠️  Warnings: $($SetupStatus.warnings.Count)" "WARN"
Write-Log "📊 Success rate: $successRate%" "INFO"

if ($SetupStatus.steps_failed.Count -gt 0) {
  Write-Log "Failed steps:" "ERROR"
  foreach ($failed in $SetupStatus.steps_failed) {
    Write-Log "  - $failed" "ERROR"
  }
}

if ($SetupStatus.warnings.Count -gt 0) {
  Write-Log "Warnings to address:" "WARN"
  foreach ($warning in $SetupStatus.warnings) {
    Write-Log "  - $warning" "WARN"
  }
}

# Next steps
Write-Host @"

🚀 NEXT STEPS - YOUR HOME PC IS READY!
======================================

1. 📝 EDIT CREDENTIALS (IMPORTANT!)
   Edit: $HomePCWorkspaceRoot\.env
   Add your API keys and tokens

2. 🎯 START WORKING
   Quick start: .\start-work-home.ps1
   Or open VS Code: code brickface-enterprise.code-workspace

3. 💾 END WORK SESSION
   When done: .\end-work-home.ps1
   (Automatically syncs back to GitHub)

4. 🏢 CONTINUE ON OFFICE PC
   Your work will be automatically available!
   Just run: .\start-work.ps1 on Office PC

🔄 TWO-WAY SYNC ESTABLISHED!
============================
Home PC ←→ GitHub ←→ Office PC

📁 Workspace location: $HomePCWorkspaceRoot
📝 Log file: $LogFile
📊 Setup status: $(if ($SetupStatus.home_pc_ready) { "✅ READY" } else { "⚠️ NEEDS ATTENTION" })

"@ -ForegroundColor Cyan

# Create desktop shortcuts (optional)
if ($IsWindows) {
  try {
    $WshShell = New-Object -comObject WScript.Shell
        
    # Start work shortcut
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Brickface Start Work (Home).lnk")
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$HomePCWorkspaceRoot\start-work-home.ps1`""
    $Shortcut.WorkingDirectory = $HomePCWorkspaceRoot
    $Shortcut.IconLocation = "shell32.dll,25"
    $Shortcut.Description = "Start Brickface Enterprise work session on Home PC"
    $Shortcut.Save()
        
    # End work shortcut
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Brickface End Work (Home).lnk")
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$HomePCWorkspaceRoot\end-work-home.ps1`""
    $Shortcut.WorkingDirectory = $HomePCWorkspaceRoot
    $Shortcut.IconLocation = "shell32.dll,132"
    $Shortcut.Description = "End Brickface Enterprise work session on Home PC"
    $Shortcut.Save()
        
    Write-Log "Desktop shortcuts created!" "SUCCESS"
  }
  catch {
    Write-Log "Desktop shortcut creation failed (non-critical)" "WARN"
  }
}

Write-Host "💡 Tip: Pin the shortcuts to your taskbar for easy access!" -ForegroundColor Yellow
Write-Host "🎊 Welcome to seamless Office ↔ Home PC workflow!" -ForegroundColor Green

# Save setup status for future reference
$statusFile = Join-Path $HomePCWorkspaceRoot "home-pc-setup-status.json"
try {
  $SetupStatus | ConvertTo-Json -Depth 5 | Set-Content $statusFile
  Write-Log "Setup status saved to: home-pc-setup-status.json" "INFO"
}
catch {
  Write-Log "Failed to save setup status" "WARN"
}

Write-Host "`n🏠 Home PC setup complete! Time to start working..." -ForegroundColor Magenta

# End of script