# Get All Tasks from AI Agents Space
if (Test-Path "../../.env") {
    Get-Content "../../.env" | ForEach-Object {
        if ($_ -match "^([^#].+?)=(.+)$") {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

$token = $env:CLICKUP_TOKEN
$teamId = "90131096188"
$spaceId = "901311568040"

$headers = @{
    "Authorization" = $token
    "Content-Type" = "application/json"
}

Write-Host "Fetching ALL tasks from AI Agents space..." -ForegroundColor Cyan

# Get all tasks in the space
$tasksResponse = Invoke-RestMethod -Uri "https://api.clickup.com/api/v2/space/$spaceId/task?archived=false&include_closed=true" -Method GET -Headers $headers

$allTasks = $tasksResponse.tasks
Write-Host "Total tasks found: $($allTasks.Count)" -ForegroundColor Green
Write-Host ""

# Group by status
$completed = $allTasks | Where-Object { $_.status.status -eq "complete" }
$inProgress = $allTasks | Where-Object { $_.status.status -eq "in progress" }
$toDo = $allTasks | Where-Object { $_.status.status -ne "complete" -and $_.status.status -ne "in progress" }

Write-Host "Completed Tasks: $($completed.Count)" -ForegroundColor Green
$completed | ForEach-Object {
    Write-Host "  - $($_.name)" -ForegroundColor White
    Write-Host "    List: $($_.list.name) | Folder: $($_.folder.name)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "In Progress: $($inProgress.Count)" -ForegroundColor Yellow
$inProgress | ForEach-Object {
    Write-Host "  - $($_.name)" -ForegroundColor White
}

Write-Host ""
Write-Host "To Do: $($toDo.Count)" -ForegroundColor Cyan

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Direct link to view all tasks:" -ForegroundColor Cyan
Write-Host "https://app.clickup.com/90131096188/v/o/s/901311568040" -ForegroundColor Yellow
