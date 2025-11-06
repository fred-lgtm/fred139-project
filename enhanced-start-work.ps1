# Brickface Enterprise - Auto-Authentication Orchestrator
# =====================================================
# Runs automatically when VS Code workspace opens
# Handles all authentication, environment setup, and git sync
# Version: 1.0 | Date: November 5, 2025

param(
    [switch]$Verbose,
    [switch]$Force
)

# Configuration
$ErrorActionPreference = "Continue"
$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$LogFile = Join-Path $PSScriptRoot "auth-check-$(Get-Date -Format 'yyyy-MM-dd').log"
$StatusFile = Join-Path $PSScriptRoot "auth-status.json"
$EnvTemplate = Join-Path $WorkspaceRoot ".env.template"
$EnvFile = Join-Path $WorkspaceRoot ".env"

# Logging function
function Write-Log {
    param($Message, $Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $LogEntry
    if ($Verbose -or $Level -eq "ERROR") {
        Write-Host $LogEntry -ForegroundColor $(if($Level -eq "ERROR") {"Red"} elseif($Level -eq "WARN") {"Yellow"} else {"Green"})
    }
}

# Status tracking
$Status = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    workspace_root = $WorkspaceRoot
    checks = @{}
    errors = @()
    warnings = @()
}

Write-Log "Brickface Enterprise Auto-Authentication Starting..." "INFO"
Write-Log "Workspace: $WorkspaceRoot" "INFO"

# =============================================================================
# 1. GOOGLE CLOUD ADC VERIFICATION
# =============================================================================

Write-Log "Checking Google Cloud Application Default Credentials..." "INFO"

$ADCPath = "$env:APPDATA\gcloud\application_default_credentials.json"
$ADCStatus = @{
    path = $ADCPath
    exists = $false
    valid = $false
    type = $null
    project = $null
    client_id = $null
}

if (Test-Path $ADCPath) {
    $ADCStatus.exists = $true
    try {
        $ADCContent = Get-Content $ADCPath | ConvertFrom-Json
        $ADCStatus.type = $ADCContent.type
        $ADCStatus.client_id = $ADCContent.client_id
        
        # Set environment variable
        $env:GOOGLE_APPLICATION_CREDENTIALS = $ADCPath
        $env:GOOGLE_CLOUD_PROJECT = "boxwood-charmer-467423-f0"
        
        if ($ADCContent.type -eq "authorized_user" -and $ADCContent.client_id) {
            $ADCStatus.valid = $true
            $ADCStatus.project = "boxwood-charmer-467423-f0"
            Write-Log "Google Cloud ADC: Valid (OAuth 2.0)" "INFO"
        } else {
            Write-Log "Google Cloud ADC: Invalid format" "WARN"
            $Status.warnings += "ADC file exists but format is invalid"
        }
    } catch {
        Write-Log "Google Cloud ADC: Parse error - $($_.Exception.Message)" "ERROR"
        $Status.errors += "ADC file parse error: $($_.Exception.Message)"
    }
} else {
    Write-Log "Google Cloud ADC: Not found" "ERROR"
    $Status.errors += "ADC file not found at $ADCPath"
}

$Status.checks.google_cloud_adc = $ADCStatus

# =============================================================================
# 2. 1PASSWORD CLI VERIFICATION  
# =============================================================================

Write-Log "Checking 1Password CLI authentication..." "INFO"

$OpStatus = @{
    installed = $false
    authenticated = $false
    vault_accessible = $false
}

try {
    $OpVersion = & op --version 2>$null
    if ($OpVersion) {
        $OpStatus.installed = $true
        Write-Log "1Password CLI: Installed ($OpVersion)" "INFO"
        
        # Test authentication
        try {
            $OpAccount = & op account list --format=json 2>$null
            if ($LASTEXITCODE -eq 0 -and $OpAccount) {
                $OpStatus.authenticated = $true
                Write-Log "1Password CLI: Authenticated" "INFO"
                
                # Test vault access
                try {
                    $Vaults = & op vault list --format=json 2>$null
                    if ($LASTEXITCODE -eq 0 -and $Vaults) {
                        $OpStatus.vault_accessible = $true
                        Write-Log "1Password CLI: Vault access verified" "INFO"
                    }
                } catch {
                    Write-Log "1Password CLI: Vault access failed" "WARN"
                }
            } else {
                Write-Log "1Password CLI: Not authenticated (run: op signin)" "WARN"
                $Status.warnings += "1Password CLI requires authentication"
            }
        } catch {
            Write-Log "1Password CLI: Auth check failed" "WARN"
        }
    } else {
        Write-Log "1Password CLI: Not installed" "ERROR"
        $Status.errors += "1Password CLI not found in PATH"
    }
} catch {
    Write-Log "1Password CLI: Check failed - $($_.Exception.Message)" "ERROR"
    $Status.errors += "1Password CLI check error: $($_.Exception.Message)"
}

$Status.checks.onepassword_cli = $OpStatus

# =============================================================================
# 3. GIT CONFIGURATION
# =============================================================================

Write-Log "Configuring Git user..." "INFO"

$GitStatus = @{
    user_name = $null
    user_email = $null
    configured = $false
}

try {
    # Set Git user configuration
    & git config --global user.email "fred@brickface.com" 2>$null
    & git config --global user.name "Fred Ohen" 2>$null
    
    # Verify configuration
    $GitEmail = & git config --global user.email 2>$null
    $GitName = & git config --global user.name 2>$null
    
    if ($GitEmail -eq "fred@brickface.com" -and $GitName -eq "Fred Ohen") {
        $GitStatus.user_email = $GitEmail
        $GitStatus.user_name = $GitName
        $GitStatus.configured = $true
        Write-Log "Git: User configured ($GitEmail)" "INFO"
    } else {
        Write-Log "Git: Configuration verification failed" "WARN"
    }
} catch {
    Write-Log "Git: Configuration failed - $($_.Exception.Message)" "ERROR"
    $Status.errors += "Git configuration error: $($_.Exception.Message)"
}

$Status.checks.git_config = $GitStatus

# =============================================================================
# 4. ENVIRONMENT FILE MANAGEMENT
# =============================================================================

Write-Log "Checking environment file..." "INFO"

$EnvStatus = @{
    template_exists = (Test-Path $EnvTemplate)
    env_exists = (Test-Path $EnvFile)
    created = $false
}

if (-not $EnvStatus.env_exists -and $EnvStatus.template_exists) {
    try {
        Copy-Item $EnvTemplate $EnvFile
        $EnvStatus.created = $true
        $EnvStatus.env_exists = $true
        Write-Log "Environment: Created .env from template" "INFO"
    } catch {
        Write-Log "Environment: Failed to create .env - $($_.Exception.Message)" "ERROR"
        $Status.errors += "Environment file creation error: $($_.Exception.Message)"
    }
} elseif ($EnvStatus.env_exists) {
    Write-Log "Environment: .env file exists" "INFO"
} else {
    Write-Log "Environment: No .env or .env.template found" "WARN"
    $Status.warnings += "No environment files found"
}

$Status.checks.environment = $EnvStatus

# =============================================================================
# 5. CROSS-PC GIT SYNC (OFFICE ↔ HOME SEAMLESS WORKFLOW)
# =============================================================================

Write-Log "Checking Cross-PC Git sync for Office ↔ Home workflow..." "INFO"

$GitSyncStatus = @{
    is_git_repo = $false
    is_clean = $false
    pulled = $false
    current_branch = $null
    brickface_synced = $false
    fred139-project_synced = $false
    cross_pc_ready = $false
}

try {
    # Check brickface-enterprise GitHub sync (via fred139-project repo)
    Set-Location $WorkspaceRoot
    
    $GitRepo = & git rev-parse --is-inside-work-tree 2>$null
    if ($GitRepo -eq "true") {
        $GitSyncStatus.is_git_repo = $true
        $GitSyncStatus.current_branch = & git branch --show-current 2>$null
        
        # Check if workspace is clean
        $GitStatusOutput = & git status --porcelain 2>$null
        if (-not $GitStatusOutput) {
            $GitSyncStatus.is_clean = $true
            
            # Pull latest changes from GitHub (fred139-project repo)
            try {
                & git pull --rebase origin main 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $GitSyncStatus.pulled = $true
                    $GitSyncStatus.brickface_synced = $true
                    Write-Log "Cross-PC Sync: Brickface-enterprise synced from GitHub" "INFO"
                } else {
                    Write-Log "Cross-PC Sync: GitHub pull failed" "WARN"
                    $Status.warnings += "GitHub sync failed - may need manual resolution"
                }
            } catch {
                Write-Log "Cross-PC Sync: GitHub pull failed" "WARN"
                $Status.warnings += "GitHub sync failed - may need manual resolution"
            }
        } else {
            Write-Log "Cross-PC Sync: Workspace has uncommitted changes, skipping GitHub pull" "WARN"
        }
    }
    
    # Check fred139-project folder GitHub sync
    $fred139-projectPath = Split-Path -Parent $WorkspaceRoot
    if (Test-Path $fred139-projectPath) {
        Set-Location $fred139-projectPath
        
        $DocsGitRepo = & git rev-parse --is-inside-work-tree 2>$null
        if ($DocsGitRepo -eq "true") {
            try {
                # Check if GitHub remote exists
                $GitRemote = & git remote get-url origin 2>$null
                if ($GitRemote -like "*github.com*") {
                    # Pull latest from GitHub fred139-project repo
                    & git pull --rebase origin main 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        $GitSyncStatus.fred139-project_synced = $true
                        Write-Log "Cross-PC Sync: fred139-project folder synced from GitHub" "INFO"
                    } else {
                        Write-Log "Cross-PC Sync: GitHub fred139-project sync failed" "WARN"
                        $Status.warnings += "GitHub fred139-project sync failed"
                    }
                } else {
                    Write-Log "Cross-PC Sync: fred139-project folder not connected to GitHub" "WARN"
                    $Status.warnings += "fred139-project folder needs GitHub setup for cross-PC sync"
                }
            } catch {
                Write-Log "Cross-PC Sync: fred139-project GitHub check failed" "WARN"
            }
        } else {
            Write-Log "Cross-PC Sync: fred139-project folder not a Git repository" "WARN"
            $Status.warnings += "fred139-project folder needs Git initialization for cross-PC sync"
        }
    }
    
    # Set cross-PC ready status
    $GitSyncStatus.cross_pc_ready = $GitSyncStatus.brickface_synced -and $GitSyncStatus.fred139-project_synced
    
    if ($GitSyncStatus.cross_pc_ready) {
        Write-Log "Cross-PC Sync: ✅ Office ↔ Home workflow ready!" "INFO"
        $env:BRICKFACE_CROSS_PC_STATUS = "READY"
    } else {
        Write-Log "Cross-PC Sync: ⚠️ Setup required - run SETUP-CROSS-PC-SYNC.ps1" "WARN"
        $env:BRICKFACE_CROSS_PC_STATUS = "NEEDS_SETUP"
    }
        
    Write-Log "Cross-PC Sync: Status checked (branch: $($GitSyncStatus.current_branch))" "INFO"
} catch {
    Write-Log "Cross-PC Sync: Check failed - $($_.Exception.Message)" "ERROR"
    $Status.errors += "Cross-PC sync check error: $($_.Exception.Message)"
} finally {
    # Return to workspace root
    Set-Location $WorkspaceRoot
}

$Status.checks.cross_pc_git_sync = $GitSyncStatus

# =============================================================================
# 6. LOAD 1PASSWORD SECRETS (IF AUTHENTICATED)
# =============================================================================

if ($OpStatus.authenticated -and $OpStatus.vault_accessible) {
    Write-Log "Loading 1Password secrets..." "INFO"
    
    $SecretStatus = @{
        loaded = @()
        failed = @()
    }
    
    # Define secrets to load
    $Secrets = @(
        @{ name = "N8N_API_KEY"; item = "n8n"; field = "api_key" },
        @{ name = "QUICKBOOKS_REALM_ID"; item = "QuickBooks-OAuth"; field = "realm_id" },
        @{ name = "QUICKBOOKS_ACCESS_TOKEN"; item = "QuickBooks-OAuth"; field = "access_token" },
        @{ name = "ANTHROPIC_API_KEY"; item = "Anthropic-Claude"; field = "api_key" },
        @{ name = "HUBSPOT_API_KEY"; item = "HubSpot-CRM"; field = "api_key" },
        @{ name = "CLICKUP_API_KEY"; item = "ClickUp"; field = "api_key" }
    )
    
    foreach ($Secret in $Secrets) {
        try {
            $Value = & op item get $Secret.item --field $Secret.field 2>$null
            if ($Value -and $LASTEXITCODE -eq 0) {
                Set-Item -Path "env:$($Secret.name)" -Value $Value
                $SecretStatus.loaded += $Secret.name
                Write-Log "Secret: Loaded $($Secret.name)" "INFO"
            } else {
                $SecretStatus.failed += $Secret.name
                Write-Log "Secret: Failed to load $($Secret.name)" "WARN"
            }
        } catch {
            $SecretStatus.failed += $Secret.name
            Write-Log "Secret: Error loading $($Secret.name)" "WARN"
        }
    }
    
    $Status.checks.secrets = $SecretStatus
}

# =============================================================================
# 7. SAVE STATUS AND SUMMARY
# =============================================================================

# Calculate summary
$TotalChecks = $Status.checks.Count
$SuccessfulChecks = 0
foreach ($CheckName in $Status.checks.Keys) {
    $Check = $Status.checks[$CheckName]
    if ($Check -is [hashtable]) {
        $CheckSuccess = $false
        if ($Check.ContainsKey("valid") -and $Check.valid) { $CheckSuccess = $true }
        elseif ($Check.ContainsKey("authenticated") -and $Check.authenticated) { $CheckSuccess = $true }
        elseif ($Check.ContainsKey("configured") -and $Check.configured) { $CheckSuccess = $true }
        elseif ($Check.ContainsKey("env_exists") -and $Check.env_exists) { $CheckSuccess = $true }
        elseif ($Check.ContainsKey("is_git_repo") -and $Check.is_git_repo) { $CheckSuccess = $true }
        elseif ($Check.ContainsKey("loaded") -and $Check.loaded -and $Check.loaded.Count -gt 0) { $CheckSuccess = $true }
        
        if ($CheckSuccess) { $SuccessfulChecks++ }
    }
}

$Status.summary = @{
    total_checks = $TotalChecks
    successful_checks = $SuccessfulChecks
    success_rate = if ($TotalChecks -gt 0) { [math]::Round(($SuccessfulChecks / $TotalChecks) * 100, 1) } else { 0 }
    error_count = $Status.errors.Count
    warning_count = $Status.warnings.Count
    overall_status = if ($Status.errors.Count -eq 0) { "SUCCESS" } elseif ($Status.errors.Count -le 2) { "WARNING" } else { "ERROR" }
}

# Save status to JSON
try {
    $Status | ConvertTo-Json -Depth 10 | Set-Content $StatusFile
    Write-Log "Status: Saved to auth-status.json" "INFO"
} catch {
    Write-Log "Status: Failed to save status file" "ERROR"
}

# Final summary
Write-Log "===============================================" "INFO"
Write-Log "AUTO-AUTHENTICATION SUMMARY" "INFO"
Write-Log "===============================================" "INFO"
Write-Log "Success Rate: $($Status.summary.success_rate)% ($($Status.summary.successful_checks)/$($Status.summary.total_checks))" "INFO"
Write-Log "Errors: $($Status.summary.error_count)" "INFO"
Write-Log "Warnings: $($Status.summary.warning_count)" "INFO"
Write-Log "Overall Status: $($Status.summary.overall_status)" "INFO"

if ($Status.errors.Count -gt 0) {
    Write-Log "ERRORS DETECTED:" "ERROR"
    foreach ($ErrorMsg in $Status.errors) {
        Write-Log "  - $ErrorMsg" "ERROR"
    }
}

if ($Status.warnings.Count -gt 0) {
    Write-Log "WARNINGS:" "WARN"
    foreach ($Warning in $Status.warnings) {
        Write-Log "  - $Warning" "WARN"
    }
}

Write-Log "Log saved: $LogFile" "INFO"
Write-Log "Status saved: $StatusFile" "INFO"
Write-Log "===============================================" "INFO"

# Set final environment variables for this session
$env:BRICKFACE_AUTH_STATUS = $Status.summary.overall_status
$env:BRICKFACE_AUTH_RATE = $Status.summary.success_rate

Write-Log "Brickface Enterprise Auto-Authentication Complete!" "INFO"
