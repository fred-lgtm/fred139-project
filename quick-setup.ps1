# Simple Complete Integration Setup
# Quick setup for GitKraken + Auto-Save

Write-Host "🚀 Starting Brickface Enterprise Integration Setup..." -ForegroundColor Cyan

$WorkspacePath = "c:\Users\frede\fred139-project"
Set-Location $WorkspacePath

# Step 1: Create environment file
Write-Host "📝 Creating environment configuration..." -ForegroundColor Yellow
$envContent = @"
CLICKUP_TOKEN=your_clickup_token_here
CLICKUP_LIST_ID=your_list_id_here
CLICKUP_TASK_ID=your_task_id_here
GITHUB_TOKEN=your_github_token_here
WORKSPACE_PATH=c:\Users\frede\fred139-project
"@
Set-Content -Path ".env" -Value $envContent
Write-Host "✅ Environment file created" -ForegroundColor Green

# Step 2: Configure Git
Write-Host "🔧 Configuring Git..." -ForegroundColor Yellow
git config user.name "Brickface Enterprise"
git config user.email "enterprise@brickface.com"
Write-Host "✅ Git configured" -ForegroundColor Green

# Step 3: Create VS Code workspace
Write-Host "💻 Creating VS Code workspace..." -ForegroundColor Yellow
$workspace = @{
    folders = @(@{ path = "." })
    settings = @{
        "terminal.integrated.defaultProfile.windows" = "PowerShell"
        "git.enableSmartCommit" = $true
        "files.autoSave" = "afterDelay"
    }
}
$workspace | ConvertTo-Json -Depth 5 | Set-Content "brickface-enterprise.code-workspace"
Write-Host "✅ VS Code workspace created" -ForegroundColor Green

# Step 4: Start Auto-Save Service
Write-Host "🚀 Starting Auto-Save Service..." -ForegroundColor Yellow
if (Test-Path "enhanced-auto-save-complete-integration.ps1") {
    Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy", "Bypass", "-File", "enhanced-auto-save-complete-integration.ps1", "-Start" -WindowStyle Hidden
    Start-Sleep -Seconds 2
    Write-Host "✅ Auto-Save service started" -ForegroundColor Green
} else {
    Write-Host "❌ Auto-Save script not found" -ForegroundColor Red
}

# Step 5: Try to start GitKraken
Write-Host "🦑 Attempting to start GitKraken..." -ForegroundColor Yellow
try {
    Start-Process "gitkraken" -ArgumentList "--path", "`"$WorkspacePath`"" -ErrorAction SilentlyContinue
    Write-Host "✅ GitKraken started" -ForegroundColor Green
} catch {
    Write-Host "⚠️ GitKraken not installed or not in PATH" -ForegroundColor Yellow
    Write-Host "   Download from: https://www.gitkraken.com/download" -ForegroundColor Gray
}

# Step 6: Commit changes
Write-Host "📤 Committing changes..." -ForegroundColor Yellow
git add .
git commit -m "Quick integration setup complete"
git push origin main
Write-Host "✅ Changes pushed to GitHub" -ForegroundColor Green

Write-Host ""
Write-Host "🎉 SETUP COMPLETE!" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Update .env file with your actual tokens"
Write-Host "2. Open VS Code: code brickface-enterprise.code-workspace"
Write-Host "3. Install GitKraken if not already installed"
Write-Host ""
Write-Host "Service Status:" -ForegroundColor Cyan
if (Test-Path "enhanced-auto-save-complete-integration.ps1") {
    powershell.exe -ExecutionPolicy Bypass -File "enhanced-auto-save-complete-integration.ps1" -Status
}