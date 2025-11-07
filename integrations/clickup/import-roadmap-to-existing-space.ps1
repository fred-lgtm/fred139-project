# Import Roadmap to Existing ClickUp Space
# Creates lists and tasks in the existing "AI Agents" space (901311568040)

if (Test-Path "../../.env") {
    Get-Content "../../.env" | ForEach-Object {
        if ($_ -match "^([^#].+?)=(.+)$") {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

$token = $env:CLICKUP_TOKEN
$teamId = "90131096188"
$aiAgentsSpaceId = "901311568040"

Write-Host "Starting ClickUp Roadmap Import to AI Agents Space..." -ForegroundColor Cyan

$headers = @{
    "Authorization" = $token
    "Content-Type" = "application/json"
}

# Load roadmap JSON
$roadmapPath = "..\..\clickup-roadmap-complete.json"
$roadmap = Get-Content $roadmapPath -Raw | ConvertFrom-Json

Write-Host "Loaded roadmap: $($roadmap.workspace.name)" -ForegroundColor Green
Write-Host "Creating in existing space: AI Agents (ID: $aiAgentsSpaceId)" -ForegroundColor Yellow
Write-Host ""

$stats = @{
    lists = 0
    tasks = 0
    subtasks = 0
}

# Process each space from roadmap as a list in ClickUp
foreach ($spaceData in $roadmap.spaces) {
    Write-Host "Creating folder: $($spaceData.name)..." -ForegroundColor Cyan

    # Create folder in the AI Agents space - remove emojis from name for API compatibility
    $folderName = $spaceData.name -replace '[^\x00-\x7F]', ''  # Remove non-ASCII characters
    $folderBody = @{
        name = $folderName.Trim()
    } | ConvertTo-Json -Depth 10

    try {
        $folder = Invoke-RestMethod -Uri "https://api.clickup.com/api/v2/space/$aiAgentsSpaceId/folder" -Method POST -Headers $headers -Body $folderBody
        Write-Host "  Folder created: $($folder.id)" -ForegroundColor Green

        # Create each list in the folder
        foreach ($listData in $spaceData.lists) {
            Write-Host "    Creating list: $($listData.name)..." -ForegroundColor Yellow

            $listBody = @{
                name = $listData.name
                content = $listData.description
                priority = $null
                status = $null
            } | ConvertTo-Json -Depth 10

            $list = Invoke-RestMethod -Uri "https://api.clickup.com/api/v2/folder/$($folder.id)/list" -Method POST -Headers $headers -Body $listBody
            $stats.lists++
            Write-Host "      List created: $($list.id)" -ForegroundColor Green

            # Create tasks in the list
            foreach ($taskData in $listData.tasks) {
                Write-Host "        Creating task: $($taskData.name)..." -ForegroundColor Gray

                # Map status
                $statusMap = @{
                    'Complete' = 'complete'
                    'In Progress' = 'in progress'
                    'To Do' = 'to do'
                    'Blocked' = 'blocked'
                    'Review' = 'review'
                }
                $status = $statusMap[$taskData.status]
                if (-not $status) { $status = 'to do' }

                # Map priority
                $priorityMap = @{
                    'Urgent' = 1
                    'High' = 2
                    'Normal' = 3
                    'Low' = 4
                }
                $priority = $priorityMap[$taskData.priority]
                if (-not $priority) { $priority = 3 }

                # Convert dates to Unix timestamps (milliseconds)
                $dueDate = $null
                if ($taskData.due_date) {
                    $dueDate = [int64]([DateTime]::Parse($taskData.due_date).ToUniversalTime() - [DateTime]'1970-01-01').TotalMilliseconds
                }

                $startDate = $null
                if ($taskData.start_date) {
                    $startDate = [int64]([DateTime]::Parse($taskData.start_date).ToUniversalTime() - [DateTime]'1970-01-01').TotalMilliseconds
                }

                $taskBody = @{
                    name = $taskData.name
                    description = $taskData.description
                    status = $status
                    priority = $priority
                    tags = $taskData.tags
                }

                if ($dueDate) { $taskBody.due_date = $dueDate }
                if ($startDate) { $taskBody.start_date = $startDate }

                $taskBodyJson = $taskBody | ConvertTo-Json -Depth 10

                try {
                    $task = Invoke-RestMethod -Uri "https://api.clickup.com/api/v2/list/$($list.id)/task" -Method POST -Headers $headers -Body $taskBodyJson
                    $stats.tasks++

                    # Add subtasks as checklist items
                    if ($taskData.subtasks -and $taskData.subtasks.Count -gt 0) {
                        $checklistBody = @{
                            name = "Subtasks"
                        } | ConvertTo-Json

                        $checklist = Invoke-RestMethod -Uri "https://api.clickup.com/api/v2/task/$($task.id)/checklist" -Method POST -Headers $headers -Body $checklistBody

                        foreach ($subtask in $taskData.subtasks) {
                            $itemBody = @{
                                name = $subtask.name
                                resolved = ($subtask.status -eq 'Complete')
                            } | ConvertTo-Json

                            Invoke-RestMethod -Uri "https://api.clickup.com/api/v2/checklist/$($checklist.id)/checklist_item" -Method POST -Headers $headers -Body $itemBody | Out-Null
                            $stats.subtasks++
                        }
                    }

                    # Rate limiting
                    Start-Sleep -Milliseconds 100

                } catch {
                    Write-Host "          Failed to create task: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }

        # Wait between folders
        Start-Sleep -Milliseconds 500

    } catch {
        Write-Host "  Failed to create folder: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails) {
            Write-Host "  $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "ROADMAP IMPORT COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Import Summary:" -ForegroundColor Cyan
Write-Host "  Lists Created: $($stats.lists)" -ForegroundColor White
Write-Host "  Tasks Created: $($stats.tasks)" -ForegroundColor White
Write-Host "  Subtasks Created: $($stats.subtasks)" -ForegroundColor White
Write-Host ""
Write-Host "Access your workspace at:" -ForegroundColor Cyan
Write-Host "  https://app.clickup.com/90131096188/v/o/s/901311568040" -ForegroundColor Yellow
Write-Host ""

# Save workspace URL
$workspaceUrl = "https://app.clickup.com/90131096188/v/o/s/901311568040"
$urlContent = @"
Brickface Enterprise Development Workspace
AI Agents Space - Comprehensive Roadmap

Workspace URL: $workspaceUrl

Created: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Statistics:
- Lists: $($stats.lists)
- Tasks: $($stats.tasks)
- Subtasks: $($stats.subtasks)
"@

Set-Content -Path "..\..\CLICKUP-WORKSPACE-URL.txt" -Value $urlContent
Write-Host "Workspace URL saved to: CLICKUP-WORKSPACE-URL.txt" -ForegroundColor Green
