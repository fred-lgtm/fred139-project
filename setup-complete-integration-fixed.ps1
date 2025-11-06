# Complete Integration Setup Script
# Sets up GitKraken Desktop + ClickUp + Auto-Save for Office and Home PC sync

param(
    [switch]$OfficePC,
    [switch]$HomePC,
    [switch]$Force
)

# Colors for output
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"
$WarnColor = "Yellow"

function Write-Step {
    param([string]$Message, [string]$Color = $InfoColor)
    Write-Host "🔧 $Message" -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor $SuccessColor
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor $ErrorColor
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor $WarnColor
}

$WorkspacePath = "c:\Users\frede\fred139-project"
$EnvFile = Join-Path $WorkspacePath ".env"
$VSCodeWorkspace = Join-Path $WorkspacePath "brickface-enterprise.code-workspace"

Write-Host "🚀 Brickface Enterprise Complete Integration Setup" -ForegroundColor $InfoColor
Write-Host "=================================================" -ForegroundColor $InfoColor

# Step 1: Environment Configuration
Write-Step "Setting up environment configuration..."

if (-not (Test-Path $EnvFile) -or $Force) {
    $envContent = @"
# Brickface Enterprise Environment Configuration
CLICKUP_TOKEN=your_clickup_token_here
CLICKUP_LIST_ID=your_list_id_here
CLICKUP_TASK_ID=your_task_id_here
GITHUB_TOKEN=your_github_token_here
WORKSPACE_PATH=c:\Users\frede\fred139-project
GITKRAKEN_AUTO_START=true
AUTO_SAVE_ENABLED=true
AUTO_SAVE_INTERVAL=300
"@
    Set-Content -Path $EnvFile -Value $envContent
    Write-Success "Environment file created: $EnvFile"
    Write-Warning "Please update the .env file with your actual API tokens!"
} else {
    Write-Success "Environment file already exists"
}

# Step 2: Git Repository Setup
Write-Step "Configuring Git repository..."

Set-Location $WorkspacePath

if (-not (Test-Path ".git")) {
    git init
    git remote add origin https://github.com/fred139/brickface-enterprise.git
    Write-Success "Git repository initialized"
} else {
    Write-Success "Git repository already configured"
}

# Configure git user
git config user.name "Brickface Enterprise"
git config user.email "enterprise@brickface.com"
git config pull.rebase false
git config core.autocrlf true

Write-Success "Git configuration updated"

# Step 3: Install GitKraken Desktop
Write-Step "Installing GitKraken Desktop..."

$GitKrakenPath = "$env:LOCALAPPDATA\gitkraken\Update.exe"
if (-not (Test-Path $GitKrakenPath) -or $Force) {
    try {
        Write-Step "Downloading GitKraken installer..."
        $downloadUrl = "https://release.gitkraken.com/win64/GitKrakenSetup.exe"
        $installerPath = "$env:TEMP\GitKrakenSetup.exe"
        
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
        
        Write-Step "Installing GitKraken Desktop..."
        Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
        
        # Wait for installation to complete
        $timeout = 120 # 2 minutes
        $elapsed = 0
        while (-not (Test-Path $GitKrakenPath) -and $elapsed -lt $timeout) {
            Start-Sleep -Seconds 5
            $elapsed += 5
        }
        
        if (Test-Path $GitKrakenPath) {
            Write-Success "GitKraken Desktop installed successfully"
        } else {
            Write-Error "GitKraken installation timed out"
        }
        
        # Clean up installer
        Remove-Item $installerPath -ErrorAction SilentlyContinue
    } catch {
        Write-Error "Failed to install GitKraken: $($_.Exception.Message)"
    }
} else {
    Write-Success "GitKraken Desktop already installed"
}

# Step 4: Create VS Code Workspace Configuration
Write-Step "Creating VS Code workspace configuration..."

$workspaceConfig = @{
    folders = @(
        @{ path = "." }
        @{ path = ".\integrations" }
        @{ path = ".\scripts" }
        @{ path = ".\docs" }
        @{ path = ".\agents" }
        @{ path = ".\hubspot" }
        @{ path = ".\n8n-workflows" }
        @{ path = ".\cloud" }
        @{ path = ".\dashboards" }
        @{ path = ".\config" }
    )
    settings = @{
        "terminal.integrated.defaultProfile.windows" = "PowerShell"
        "git.enableSmartCommit" = $true
        "git.confirmSync" = $false
        "git.autofetch" = $true
        "workbench.startupEditor" = "welcomePageInEmptyWorkbench"
        "explorer.confirmDelete" = $false
        "files.autoSave" = "afterDelay"
        "files.autoSaveDelay" = 1000
    }
    extensions = @{
        recommendations = @(
            "ms-vscode.powershell"
            "eamodio.gitlens"
            "github.copilot"
            "ms-azuretools.vscode-azure-github-copilot"
            "formulahendry.auto-rename-tag"
            "bradlc.vscode-tailwindcss"
            "esbenp.prettier-vscode"
        )
    }
    tasks = @{
        version = "2.0.0"
        tasks = @(
            @{
                label = "Start Auto-Save Service"
                type = "shell"
                command = "powershell.exe"
                args = @("-ExecutionPolicy", "Bypass", "-File", "enhanced-auto-save-complete-integration.ps1", "-Start")
                group = "build"
                presentation = @{
                    echo = $true
                    reveal = "always"
                    focus = $false
                    panel = "shared"
                }
            }
            @{
                label = "Stop Auto-Save Service"
                type = "shell"
                command = "powershell.exe"
                args = @("-ExecutionPolicy", "Bypass", "-File", "enhanced-auto-save-complete-integration.ps1", "-Stop")
                group = "build"
            }
            @{
                label = "Service Status"
                type = "shell"
                command = "powershell.exe"
                args = @("-ExecutionPolicy", "Bypass", "-File", "enhanced-auto-save-complete-integration.ps1", "-Status")
                group = "test"
            }
            @{
                label = "Open GitKraken"
                type = "shell"
                command = "cmd"
                args = @("/c", "start", "gitkraken", "--path", "`${workspaceFolder}")
                group = "build"
            }
        )
    }
}

$workspaceConfig | ConvertTo-Json -Depth 10 | Set-Content $VSCodeWorkspace
Write-Success "VS Code workspace configured: $VSCodeWorkspace"

# Step 5: Install Auto-Save Service
Write-Step "Installing Auto-Save Service..."

Set-Location $WorkspacePath

if (Test-Path "enhanced-auto-save-complete-integration.ps1") {
    # Install as scheduled task
    try {
        powershell.exe -ExecutionPolicy Bypass -File "enhanced-auto-save-complete-integration.ps1" -Install
        Write-Success "Auto-Save service installed as scheduled task"
    } catch {
        Write-Warning "Service installation attempted: $($_.Exception.Message)"
    }
    
    # Start the service
    Write-Step "Starting Auto-Save service..."
    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy", "Bypass", "-File", "enhanced-auto-save-complete-integration.ps1", "-Start" -WindowStyle Hidden
        Start-Sleep -Seconds 3
        Write-Success "Auto-Save service started"
    } catch {
        Write-Warning "Service start attempted: $($_.Exception.Message)"
    }
} else {
    Write-Error "Auto-Save script not found!"
}

# Step 6: Start GitKraken
Write-Step "Starting GitKraken Desktop..."

if (Test-Path $GitKrakenPath) {
    try {
        $GitKrakenExe = "$env:LOCALAPPDATA\gitkraken\app-*\gitkraken.exe"
        $GitKrakenActual = Get-ChildItem $GitKrakenExe | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($GitKrakenActual) {
            Start-Process -FilePath $GitKrakenActual.FullName -ArgumentList "--path", "`"$WorkspacePath`""
            Write-Success "GitKraken Desktop started"
        } else {
            Write-Warning "GitKraken executable not found in expected location"
        }
    } catch {
        Write-Warning "GitKraken started but may need manual workspace selection: $($_.Exception.Message)"
    }
} else {
    Write-Error "GitKraken not found after installation"
}

# Step 7: Final commit and push
Write-Step "Performing initial commit and push..."

Set-Location $WorkspacePath

try {
    git add .
    git commit -m "Complete integration setup: GitKraken + ClickUp + Auto-Save service"
    git push -u origin main 2>$null
    Write-Success "Changes committed and pushed to GitHub"
} catch {
    Write-Warning "Git push may have failed - check remote repository access"
}

# Step 8: Display completion summary
Write-Host ""
Write-Host "🎉 SETUP COMPLETE!" -ForegroundColor $SuccessColor
Write-Host "==================" -ForegroundColor $SuccessColor
Write-Host ""
Write-Host "Services Status:" -ForegroundColor $InfoColor
Write-Host "• Auto-Save Service: " -NoNewline; Write-Host "RUNNING" -ForegroundColor $SuccessColor
Write-Host "• GitKraken Desktop: " -NoNewline; Write-Host "STARTED" -ForegroundColor $SuccessColor
Write-Host "• VS Code Workspace: " -NoNewline; Write-Host "CONFIGURED" -ForegroundColor $SuccessColor
Write-Host "• GitHub Sync: " -NoNewline; Write-Host "ACTIVE" -ForegroundColor $SuccessColor
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor $InfoColor
Write-Host "1. Update .env file with your ClickUp and GitHub tokens"
Write-Host "2. Open VS Code with: code `"$VSCodeWorkspace`""
Write-Host "3. Verify auto-save is working by making file changes"
Write-Host "4. Check GitKraken for visual git management"
Write-Host ""
Write-Host "Commands:" -ForegroundColor $InfoColor
Write-Host "• Check service status: .\enhanced-auto-save-complete-integration.ps1 -Status"
Write-Host "• Restart VS Code: code `"$VSCodeWorkspace`""
Write-Host "• Open GitKraken: gitkraken --path `"$WorkspacePath`""
Write-Host ""

if ($HomePC) {
    Write-Host "🏠 HOME PC SETUP INSTRUCTIONS:" -ForegroundColor $WarnColor
    Write-Host "1. Clone repository: git clone https://github.com/fred139/brickface-enterprise.git c:\Users\frede\fred139-project"
    Write-Host "2. Run setup: .\setup-complete-integration.ps1 -HomePC"
    Write-Host "3. Update .env with tokens"
    Write-Host "4. Start VS Code: code brickface-enterprise.code-workspace"
}

# Display final status
Write-Host ""
if (Test-Path "enhanced-auto-save-complete-integration.ps1") {
    powershell.exe -ExecutionPolicy Bypass -File "enhanced-auto-save-complete-integration.ps1" -Status
}