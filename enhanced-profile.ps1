# Brickface Enterprise - PowerShell Profile
# =========================================
# Auto-loads in every VS Code integrated terminal
# Provides environment setup, navigation, and helper commands
# Version: 1.0 | Date: November 5, 2025

# Suppress errors for cleaner startup
$ErrorActionPreference = "SilentlyContinue"

# =============================================================================
# WORKSPACE NAVIGATION & SETUP
# =============================================================================

# Navigate to project directory
$BrickfaceProject = "C:\Users\frede\fred139-project\brickface-enterprise"
if (Test-Path $BrickfaceProject) {
    Set-Location $BrickfaceProject
}

# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================

# Google Cloud configuration
$env:GOOGLE_CLOUD_PROJECT = "boxwood-charmer-467423-f0"

# Set ADC path if available
$ADCPath = "$env:APPDATA\gcloud\application_default_credentials.json"
if (Test-Path $ADCPath) {
    $env:GOOGLE_APPLICATION_CREDENTIALS = $ADCPath
}

# =============================================================================
# 1PASSWORD SECRET LOADING
# =============================================================================

function Load-Secrets {
    <#
    .SYNOPSIS
    Loads secrets from 1Password into environment variables
    
    .DESCRIPTION
    Retrieves API keys and credentials from 1Password vault and sets them as environment variables
    #>
    
    Write-Host "🔐 Loading secrets from 1Password..." -ForegroundColor Cyan
    
    # Check if 1Password CLI is authenticated
    try {
        $null = & op account list 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ 1Password CLI not authenticated. Run: op signin" -ForegroundColor Red
            return
        }
    } catch {
        Write-Host "❌ 1Password CLI not available. Install from: https://1password.com/downloads/command-line/" -ForegroundColor Red
        return
    }
    
    # Define secrets to load
    $Secrets = @(
        @{ name = "N8N_API_KEY"; item = "n8n"; field = "api_key"; display = "n8n API Key" },
        @{ name = "QUICKBOOKS_REALM_ID"; item = "QuickBooks-OAuth"; field = "realm_id"; display = "QuickBooks Realm ID" },
        @{ name = "QUICKBOOKS_ACCESS_TOKEN"; item = "QuickBooks-OAuth"; field = "access_token"; display = "QuickBooks Access Token" },
        @{ name = "ANTHROPIC_API_KEY"; item = "Anthropic-Claude"; field = "api_key"; display = "Claude API Key" },
        @{ name = "HUBSPOT_API_KEY"; item = "HubSpot-CRM"; field = "api_key"; display = "HubSpot API Key" },
        @{ name = "CLICKUP_API_KEY"; item = "ClickUp"; field = "api_key"; display = "ClickUp API Key" }
    )
    
    $LoadedCount = 0
    foreach ($Secret in $Secrets) {
        try {
            $Value = & op item get $Secret.item --field $Secret.field 2>$null
            if ($Value -and $LASTEXITCODE -eq 0) {
                Set-Item -Path "env:$($Secret.name)" -Value $Value
                Write-Host "  ✓ $($Secret.display)" -ForegroundColor Green
                $LoadedCount++
            } else {
                Write-Host "  ⚠ $($Secret.display) - Not found" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  ❌ $($Secret.display) - Error loading" -ForegroundColor Red
        }
    }
    
    Write-Host "🎯 Loaded $LoadedCount/$($Secrets.Count) secrets" -ForegroundColor Cyan
}

# =============================================================================
# AUTHENTICATION CHECK
# =============================================================================

function Check-Auth {
    <#
    .SYNOPSIS
    Displays current authentication status for all services
    
    .DESCRIPTION
    Checks Google Cloud ADC, 1Password CLI, Git config, and environment variables
    #>
    
    Write-Host ""
    Write-Host "🔍 BRICKFACE ENTERPRISE - AUTHENTICATION STATUS" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor DarkCyan
    
    # Google Cloud ADC
    $ADCPath = "$env:APPDATA\gcloud\application_default_credentials.json"
    Write-Host "Google Cloud ADC:" -ForegroundColor White
    if (Test-Path $ADCPath) {
        try {
            $ADC = Get-Content $ADCPath | ConvertFrom-Json
            Write-Host "  ✓ File: $ADCPath" -ForegroundColor Green
            Write-Host "  ✓ Type: $($ADC.type)" -ForegroundColor Green
            Write-Host "  ✓ Client ID: $($ADC.client_id.Substring(0,20))..." -ForegroundColor Green
            Write-Host "  ✓ Project: $env:GOOGLE_CLOUD_PROJECT" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ Invalid ADC file format" -ForegroundColor Red
        }
    } else {
        Write-Host "  ❌ ADC file not found" -ForegroundColor Red
    }
    
    # 1Password CLI
    Write-Host ""
    Write-Host "1Password CLI:" -ForegroundColor White
    try {
        $OpVersion = & op --version 2>$null
        if ($OpVersion) {
            Write-Host "  ✓ Version: $OpVersion" -ForegroundColor Green
            
            try {
                $null = & op account list 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  ✓ Authenticated" -ForegroundColor Green
                } else {
                    Write-Host "  ⚠ Not authenticated (run: op signin)" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "  ⚠ Authentication check failed" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  ❌ Not installed" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ Not available" -ForegroundColor Red
    }
    
    # Git Configuration
    Write-Host ""
    Write-Host "Git Configuration:" -ForegroundColor White
    try {
        $GitEmail = & git config --global user.email 2>$null
        $GitName = & git config --global user.name 2>$null
        
        if ($GitEmail) {
            Write-Host "  ✓ Email: $GitEmail" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Email not configured" -ForegroundColor Red
        }
        
        if ($GitName) {
            Write-Host "  ✓ Name: $GitName" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Name not configured" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ Git not available" -ForegroundColor Red
    }
    
    # Environment Variables
    Write-Host ""
    Write-Host "Environment Variables:" -ForegroundColor White
    
    $EnvVars = @(
        "GOOGLE_CLOUD_PROJECT",
        "GOOGLE_APPLICATION_CREDENTIALS",
        "N8N_API_KEY",
        "QUICKBOOKS_REALM_ID",
        "ANTHROPIC_API_KEY",
        "HUBSPOT_API_KEY",
        "CLICKUP_API_KEY"
    )
    
    foreach ($Var in $EnvVars) {
        $Value = Get-Item -Path "env:$Var" -ErrorAction SilentlyContinue
        if ($Value -and $Value.Value) {
            if ($Var -like "*KEY*" -or $Var -like "*TOKEN*") {
                $DisplayValue = $Value.Value.Substring(0, [Math]::Min(15, $Value.Value.Length)) + "..."
            } else {
                $DisplayValue = $Value.Value
            }
            Write-Host "  ✓ $Var = $DisplayValue" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ $Var = Not set" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "=" * 50 -ForegroundColor DarkCyan
}

# =============================================================================
# GIT HELPER COMMANDS
# =============================================================================

function gs { 
    <#
    .SYNOPSIS
    Git status with enhanced formatting
    #>
    git status --short --branch 
}

function gp { 
    <#
    .SYNOPSIS
    Git pull with rebase
    #>
    git pull --rebase 
}

function gsync {
    <#
    .SYNOPSIS
    Cross-PC git sync: syncs both brickface-enterprise (GitHub) and fred139-project (GitHub)
    #>
    param(
        [string]$Message = "Auto-sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    )
    
    Write-Host "🔄 Cross-PC Sync: $Message" -ForegroundColor Green
    $CurrentPath = $PWD.Path
    
    try {
        # Sync current brickface-enterprise to GitHub
        Write-Host "📤 Syncing auto-authentication system to GitHub..." -ForegroundColor Cyan
        $Status = git status --porcelain
        if ($Status) {
            git add -A
            git commit -m $Message
            git push origin main
            Write-Host "✅ Brickface-enterprise synced to GitHub" -ForegroundColor Green
        } else {
            Write-Host "✓ No changes in brickface-enterprise" -ForegroundColor Green
        }
        
        # Sync fred139-project folder to GitHub (if configured)
        $fred139-projectPath = Split-Path -Parent $PWD.Path
        if (Test-Path $fred139-projectPath) {
            Set-Location $fred139-projectPath
            
            $GitRemote = git remote get-url origin 2>$null
            if ($GitRemote -like "*github.com*") {
                Write-Host "📤 Syncing fred139-project folder to GitHub..." -ForegroundColor Cyan
                $DocsStatus = git status --porcelain
                if ($DocsStatus) {
                    git add -A
                    git commit -m $Message
                    git push origin main
                    Write-Host "✅ fred139-project folder synced to GitHub" -ForegroundColor Green
                } else {
                    Write-Host "✓ No changes in fred139-project folder" -ForegroundColor Green
                }
                Write-Host "🎯 Cross-PC sync complete! Ready for Office ↔ Home transition." -ForegroundColor Green
            } else {
                Write-Host "⚠️  fred139-project folder not connected to GitHub. Run SETUP-CROSS-PC-SYNC.ps1" -ForegroundColor Yellow
                Write-Host "   Only brickface-enterprise synced to GitHub." -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "❌ Sync error: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        Set-Location $CurrentPath
    }
}

function office-sync {
    <#
    .SYNOPSIS
    Pull latest changes FROM Home PC (use on Office PC)
    #>
    Write-Host "📥 Office PC: Syncing FROM Home PC..." -ForegroundColor Green
    $CurrentPath = $PWD.Path
    
    try {
        # Pull fred139-project from GitHub
        $fred139-projectPath = Split-Path -Parent $PWD.Path
        Set-Location $fred139-projectPath
        
        $GitRemote = git remote get-url origin 2>$null
        if ($GitRemote -like "*github.com*") {
            git pull --rebase origin main
            Write-Host "✅ fred139-project synced from GitHub" -ForegroundColor Green
        } else {
            Write-Host "⚠️  fred139-project folder not connected to GitHub" -ForegroundColor Yellow
        }
        
        # Pull brickface-enterprise from GitHub
        Set-Location $CurrentPath
        git pull --rebase origin main
        Write-Host "✅ Auto-authentication system synced from GitHub" -ForegroundColor Green
        Write-Host "🎯 Office PC sync complete!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Office sync error: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        Set-Location $CurrentPath
    }
}

function home-sync {
    <#
    .SYNOPSIS
    Push latest changes TO Office PC (use on Home PC)
    #>
    Write-Host "📤 Home PC: Syncing TO Office PC..." -ForegroundColor Green
    gsync "Home PC sync - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
}

function gc {
    <#
    .SYNOPSIS
    Git commit with message
    #>
    param([string]$Message)
    
    if (-not $Message) {
        Write-Host "Usage: gc 'commit message'" -ForegroundColor Yellow
        return
    }
    
    git add .
    git commit -m $Message
}

# =============================================================================
# CUSTOM PROMPT
# =============================================================================

function prompt {
    $GitBranch = ""
    try {
        $Branch = & git branch --show-current 2>$null
        if ($Branch) {
            $GitBranch = " [$Branch]"
        }
    } catch {
        # Not in a git repo
    }
    
    $Location = Get-Location
    $ProjectRoot = "C:\Users\frede\fred139-project\brickface-enterprise"
    
    if ($Location.Path.StartsWith($ProjectRoot)) {
        $RelativePath = $Location.Path.Replace($ProjectRoot, ".\brickface-enterprise")
    } else {
        $RelativePath = $Location.Path
    }
    
    return "PS $RelativePath$GitBranch> "
}

# =============================================================================
# AUTO-LOAD SECRETS ON STARTUP
# =============================================================================

# Only auto-load if 1Password is authenticated
try {
    $null = & op account list 2>$null
    if ($LASTEXITCODE -eq 0) {
        Load-Secrets
    }
} catch {
    # 1Password CLI not available or not authenticated
}

# =============================================================================
# WELCOME MESSAGE
# =============================================================================

Write-Host ""
Write-Host "🚀 " -ForegroundColor Green -NoNewline
Write-Host "Brickface Enterprise Development Environment" -ForegroundColor Cyan
Write-Host "   Project: " -ForegroundColor White -NoNewline
Write-Host "$env:GOOGLE_CLOUD_PROJECT" -ForegroundColor Yellow
Write-Host "   Location: " -ForegroundColor White -NoNewline
Write-Host "$(Get-Location)" -ForegroundColor Yellow

# Show git branch if in repo
try {
    $Branch = & git branch --show-current 2>$null
    if ($Branch) {
        Write-Host "   Branch: " -ForegroundColor White -NoNewline
        Write-Host "$Branch" -ForegroundColor Green
    }
} catch {
    # Not in git repo
}

Write-Host ""
Write-Host "Quick Commands:" -ForegroundColor DarkCyan
Write-Host "  Check-Auth     - Show authentication status" -ForegroundColor White
Write-Host "  Load-Secrets   - Reload 1Password secrets" -ForegroundColor White
Write-Host "  gs             - Git status (short)" -ForegroundColor White
Write-Host "  gc 'message'   - Git commit with message" -ForegroundColor White
Write-Host "  gp             - Git pull with rebase" -ForegroundColor White
Write-Host "  gsync          - Quick add, commit, push" -ForegroundColor White
Write-Host ""

# Reset error action preference
$ErrorActionPreference = "Continue"
