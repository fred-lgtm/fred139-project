# Add Missing Tasks to ClickUp
# Focuses on adding the critical completed tasks that failed during initial import

if (Test-Path "../../.env") {
    Get-Content "../../.env" | ForEach-Object {
        if ($_ -match "^([^#].+?)=(.+)$") {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

$token = $env:CLICKUP_TOKEN
$aiAgentsSpaceId = "901311568040"

$headers = @{
    "Authorization" = $token
    "Content-Type" = "application/json"
}

Write-Host "Adding Missing Critical Tasks to ClickUp..." -ForegroundColor Cyan
Write-Host ""

# Helper function to find list by name in folder
function Find-List {
    param($folderId, $listName)
    $listsResponse = Invoke-RestMethod -Uri "https://api.clickup.com/api/v2/folder/$folderId/list?archived=false" -Method GET -Headers $headers
    return $listsResponse.lists | Where-Object { $_.name -eq $listName } | Select-Object -First 1
}

# Helper function to create task
function Create-Task {
    param($listId, $taskName, $description, $status, $priority, $dueDate, $tags)

    Write-Host "  Creating: $taskName" -ForegroundColor Gray

    $taskBody = @{
        name = $taskName
        description = $description
        status = $status
        priority = $priority
        tags = $tags
    }

    if ($dueDate) {
        $taskBody.due_date = [int64]([DateTime]::Parse($dueDate).ToUniversalTime() - [DateTime]'1970-01-01').TotalMilliseconds
    }

    $taskBodyJson = $taskBody | ConvertTo-Json -Depth 10

    try {
        $task = Invoke-RestMethod -Uri "https://api.clickup.com/api/v2/list/$listId/task" -Method POST -Headers $headers -Body $taskBodyJson
        Write-Host "    Created task ID: $($task.id)" -ForegroundColor Green
        Start-Sleep -Milliseconds 200
        return $task
    } catch {
        Write-Host "    Failed: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Get all folders
$foldersResponse = Invoke-RestMethod -Uri "https://api.clickup.com/api/v2/space/$aiAgentsSpaceId/folder?archived=false" -Method GET -Headers $headers
$folders = $foldersResponse.folders

# Find Infrastructure folder
$infraFolder = $folders | Where-Object { $_.name -match "Infrastructure" } | Select-Object -First 1

if ($infraFolder) {
    Write-Host "Found Infrastructure folder: $($infraFolder.id)" -ForegroundColor Yellow

    # Initial Project Setup
    $setupList = Find-List -folderId $infraFolder.id -listName "Initial Project Setup"
    if ($setupList) {
        Write-Host "Adding tasks to Initial Project Setup..." -ForegroundColor Cyan
        Create-Task -listId $setupList.id -taskName "Initial Repository Setup" `
            -description "Created GitHub repository fred139-project with Node.js/Express setup, Docker containerization, and basic CI/CD workflow" `
            -status "complete" -priority 1 -dueDate "2025-10-05" -tags @("foundation", "setup", "infrastructure")

        Create-Task -listId $setupList.id -taskName "Core Dependencies Configuration" `
            -description "Setup ESLint, Jest, Nodemon, and development tooling with npm scripts" `
            -status "complete" -priority 2 -dueDate "2025-10-05" -tags @("devtools", "testing", "linting")
    }

    # CI/CD Pipeline
    $cicdList = Find-List -folderId $infraFolder.id -listName "CI/CD Pipeline"
    if ($cicdList) {
        Write-Host "Adding tasks to CI/CD Pipeline..." -ForegroundColor Cyan
        Create-Task -listId $cicdList.id -taskName "GitHub Actions Workflow Setup" `
            -description "Created .github/workflows/ci-cd.yml with test, lint, and build jobs" `
            -status "complete" -priority 1 -dueDate "2025-10-05" -tags @("ci-cd", "github-actions", "automation")

        Create-Task -listId $cicdList.id -taskName "Fix ESLint Configuration Issues" `
            -description "Created .eslintrc.json with Node.js environment settings to fix linting failures" `
            -status "complete" -priority 1 -dueDate "2025-11-06" -tags @("ci-cd", "bugfix", "linting")

        Create-Task -listId $cicdList.id -taskName "Configure Jest with passWithNoTests" `
            -description "Added --passWithNoTests flag to Jest command to handle zero-test scenario" `
            -status "complete" -priority 1 -dueDate "2025-11-06" -tags @("ci-cd", "testing", "bugfix")

        Create-Task -listId $cicdList.id -taskName "Add workflow_dispatch Trigger" `
            -description "Added manual trigger capability to GitHub Actions workflow" `
            -status "complete" -priority 3 -dueDate "2025-11-06" -tags @("ci-cd", "enhancement")

        Create-Task -listId $cicdList.id -taskName "Disable Deploy Job" `
            -description "Commented out GCP Cloud Run deploy job to stop failure notifications (development environment only)" `
            -status "complete" -priority 2 -dueDate "2025-11-06" -tags @("ci-cd", "configuration")
    }

    # Repository Consolidation
    $consolidationList = Find-List -folderId $infraFolder.id -listName "Repository Consolidation"
    if ($consolidationList) {
        Write-Host "Adding tasks to Repository Consolidation..." -ForegroundColor Cyan
        Create-Task -listId $consolidationList.id -taskName "GitLab Dependency Elimination" `
            -description "Removed all GitLab references from codebase, implemented GitHub-only architecture" `
            -status "complete" -priority 1 -dueDate "2025-10-15" -tags @("consolidation", "cleanup")

        Create-Task -listId $consolidationList.id -taskName "Documents Repository Consolidation" `
            -description "Merged auto-authentication system from Documents repo into fred139-project, eliminated redundancy" `
            -status "complete" -priority 1 -dueDate "2025-10-15" -tags @("consolidation", "migration")

        Create-Task -listId $consolidationList.id -taskName "Unified Workflow Scripts" `
            -description "Created unified-start-work.ps1 and unified-end-work.ps1 with enhanced features from both systems" `
            -status "complete" -priority 2 -dueDate "2025-10-20" -tags @("automation", "consolidation")
    }
}

# Find MCP folder
$mcpFolder = $folders | Where-Object { $_.name -match "MCP" } | Select-Object -First 1

if ($mcpFolder) {
    Write-Host "Found MCP folder: $($mcpFolder.id)" -ForegroundColor Yellow

    # HubSpot Integration
    $hubspotList = Find-List -folderId $mcpFolder.id -listName "HubSpot Integration"
    if ($hubspotList) {
        Write-Host "Adding tasks to HubSpot Integration..." -ForegroundColor Cyan
        Create-Task -listId $hubspotList.id -taskName "HubSpot MCP Server Implementation" `
            -description "Implemented MCP server for HubSpot CRM with contact management, deal tracking, and company operations" `
            -status "complete" -priority 1 -dueDate "2025-10-25" -tags @("mcp", "hubspot", "integration")
    }

    # ClickUp Integration
    $clickupList = Find-List -folderId $mcpFolder.id -listName "ClickUp Integration"
    if ($clickupList) {
        Write-Host "Adding tasks to ClickUp Integration..." -ForegroundColor Cyan
        Create-Task -listId $clickupList.id -taskName "ClickUp MCP Server Implementation" `
            -description "Implemented MCP server for ClickUp with task management, workspace sync, and automation capabilities" `
            -status "complete" -priority 1 -dueDate "2025-10-26" -tags @("mcp", "clickup", "integration")

        Create-Task -listId $clickupList.id -taskName "ClickUp Workspace Creation Automation" `
            -description "Created PowerShell scripts for automated ClickUp workspace setup and roadmap import" `
            -status "complete" -priority 2 -dueDate "2025-11-06" -tags @("clickup", "automation")
    }

    # Communication Integrations
    $commList = Find-List -folderId $mcpFolder.id -listName "Communication Integrations"
    if ($commList) {
        Write-Host "Adding tasks to Communication Integrations..." -ForegroundColor Cyan
        Create-Task -listId $commList.id -taskName "Dialpad MCP Server" `
            -description "Implemented MCP server for Dialpad communications with call logging and SMS capabilities" `
            -status "complete" -priority 2 -dueDate "2025-10-27" -tags @("mcp", "dialpad", "communications")

        Create-Task -listId $commList.id -taskName "Gmail MCP Server" `
            -description "Implemented Gmail MCP server with email management and Google Workspace authentication" `
            -status "complete" -priority 2 -dueDate "2025-10-28" -tags @("mcp", "gmail", "email")

        Create-Task -listId $commList.id -taskName "Mailchimp MCP Server" `
            -description "Implemented Mailchimp MCP server for email marketing campaigns and list management" `
            -status "complete" -priority 3 -dueDate "2025-10-29" -tags @("mcp", "mailchimp", "marketing")
    }

    # Business Tool Integrations
    $businessList = Find-List -folderId $mcpFolder.id -listName "Business Tool Integrations"
    if ($businessList) {
        Write-Host "Adding tasks to Business Tool Integrations..." -ForegroundColor Cyan
        Create-Task -listId $businessList.id -taskName "Ramp MCP Server" `
            -description "Implemented Python-based Ramp MCP server for financial operations and expense tracking" `
            -status "complete" -priority 2 -dueDate "2025-10-30" -tags @("mcp", "ramp", "finance")

        Create-Task -listId $businessList.id -taskName "Google Workspace MCP Server" `
            -description "Implemented Google Workspace MCP server with Sheets, Docs, and Drive integration" `
            -status "complete" -priority 1 -dueDate "2025-11-01" -tags @("mcp", "google-workspace", "integration")
    }
}

# Find Automation folder
$autoFolder = $folders | Where-Object { $_.name -match "Automation" } | Select-Object -First 1

if ($autoFolder) {
    Write-Host "Found Automation folder: $($autoFolder.id)" -ForegroundColor Yellow

    # Auto-Save System
    $autosaveList = Find-List -folderId $autoFolder.id -listName "Auto-Save System"
    if ($autosaveList) {
        Write-Host "Adding tasks to Auto-Save System..." -ForegroundColor Cyan
        Create-Task -listId $autosaveList.id -taskName "Background Auto-Save Service" `
            -description "Implemented PowerShell background service with FileSystemWatcher, rate limiting, and smart commit messages. Currently at 2,600+ commits." `
            -status "complete" -priority 1 -dueDate "2025-10-12" -tags @("automation", "git", "powershell")

        Create-Task -listId $autosaveList.id -taskName "VS Code Auto-Save Integration" `
            -description "Integrated auto-save service with VS Code workspace for seamless development workflow" `
            -status "complete" -priority 2 -dueDate "2025-10-13" -tags @("automation", "vscode")

        Create-Task -listId $autosaveList.id -taskName "Auto-Save Documentation" `
            -description "Created comprehensive documentation for auto-save system setup and usage" `
            -status "complete" -priority 3 -dueDate "2025-10-14" -tags @("documentation", "automation")
    }
}

# Find Sales & Marketing folder
$salesFolder = $folders | Where-Object { $_.name -match "Sales" } | Select-Object -First 1

if ($salesFolder) {
    Write-Host "Found Sales & Marketing folder: $($salesFolder.id)" -ForegroundColor Yellow

    # Sales Dashboard
    $dashboardList = Find-List -folderId $salesFolder.id -listName "Sales Dashboard (Google Sheets)"
    if ($dashboardList) {
        Write-Host "Adding tasks to Sales Dashboard..." -ForegroundColor Cyan
        Create-Task -listId $dashboardList.id -taskName "Sales Dashboard Development" `
            -description "Developed Google Apps Script-based sales dashboard with HubSpot integration and AI coaching insights" `
            -status "complete" -priority 1 -dueDate "2025-11-02" -tags @("sales", "google-sheets", "hubspot")
    }

    # SEO Strategy
    $seoList = Find-List -folderId $salesFolder.id -listName "SEO Strategy (Brickface.com)"
    if ($seoList) {
        Write-Host "Adding tasks to SEO Strategy..." -ForegroundColor Cyan
        Create-Task -listId $seoList.id -taskName "County + Service SEO Analysis" `
            -description "Analyzed Brickface.com SEO for 300+ county/city + service combinations across NJ/NY" `
            -status "complete" -priority 1 -dueDate "2025-11-03" -tags @("seo", "strategy", "analysis")
    }
}

# Find Documentation folder
$docsFolder = $folders | Where-Object { $_.name -match "Documentation" } | Select-Object -First 1

if ($docsFolder) {
    Write-Host "Found Documentation folder: $($docsFolder.id)" -ForegroundColor Yellow

    # Core Documentation
    $coreDocsList = Find-List -folderId $docsFolder.id -listName "Core Documentation"
    if ($coreDocsList) {
        Write-Host "Adding tasks to Core Documentation..." -ForegroundColor Cyan
        Create-Task -listId $coreDocsList.id -taskName "Project README" `
            -description "Created comprehensive README.md documenting project purpose, setup, and usage" `
            -status "complete" -priority 2 -dueDate "2025-10-06" -tags @("documentation")

        Create-Task -listId $coreDocsList.id -taskName "Setup Guide (SETUP.md)" `
            -description "Created detailed SETUP.md with environment configuration and integration setup" `
            -status "complete" -priority 1 -dueDate "2025-10-07" -tags @("documentation", "setup")

        Create-Task -listId $coreDocsList.id -taskName "Consolidation Documentation" `
            -description "Created CONSOLIDATION-COMPLETE.md documenting GitLab elimination and repository consolidation" `
            -status "complete" -priority 2 -dueDate "2025-10-20" -tags @("documentation", "consolidation")
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "TASK ADDITION COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Refresh your ClickUp workspace to see the new tasks:" -ForegroundColor Cyan
Write-Host "https://app.clickup.com/90131096188/v/o/s/901311568040" -ForegroundColor Yellow
