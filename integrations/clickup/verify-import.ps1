# Verify ClickUp Import
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

Write-Host "Verifying ClickUp Import..." -ForegroundColor Cyan
Write-Host ""

# Get space details
try {
    $space = Invoke-RestMethod -Uri "https://api.clickup.com/api/v2/space/$aiAgentsSpaceId" -Method GET -Headers $headers
    Write-Host "Space: $($space.name)" -ForegroundColor Green
    Write-Host "Space ID: $($space.id)" -ForegroundColor Yellow
    Write-Host ""

    # Get folders in space
    $foldersResponse = Invoke-RestMethod -Uri "https://api.clickup.com/api/v2/space/$aiAgentsSpaceId/folder?archived=false" -Method GET -Headers $headers
    $folders = $foldersResponse.folders

    Write-Host "Folders Created: $($folders.Count)" -ForegroundColor Cyan
    Write-Host ""

    $totalLists = 0
    $totalTasks = 0

    foreach ($folder in $folders) {
        Write-Host "Folder: $($folder.name)" -ForegroundColor Yellow

        # Get lists in folder
        $listsResponse = Invoke-RestMethod -Uri "https://api.clickup.com/api/v2/folder/$($folder.id)/list?archived=false" -Method GET -Headers $headers
        $lists = $listsResponse.lists

        foreach ($list in $lists) {
            $totalLists++
            Write-Host "  List: $($list.name)" -ForegroundColor White

            # Get task count in list
            $tasksResponse = Invoke-RestMethod -Uri "https://api.clickup.com/api/v2/list/$($list.id)/task?archived=false" -Method GET -Headers $headers
            $tasks = $tasksResponse.tasks

            $totalTasks += $tasks.Count
            Write-Host "    Tasks: $($tasks.Count)" -ForegroundColor Gray

            # Show first few tasks
            $tasks | Select-Object -First 3 | ForEach-Object {
                Write-Host "      - $($_.name) [$($_.status.status)]" -ForegroundColor DarkGray
            }

            if ($tasks.Count -gt 3) {
                Write-Host "      ... and $($tasks.Count - 3) more" -ForegroundColor DarkGray
            }
        }

        Write-Host ""
    }

    Write-Host "========================================" -ForegroundColor Green
    Write-Host "IMPORT VERIFICATION COMPLETE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  Folders: $($folders.Count)" -ForegroundColor White
    Write-Host "  Lists: $totalLists" -ForegroundColor White
    Write-Host "  Tasks: $totalTasks" -ForegroundColor White
    Write-Host ""
    Write-Host "Workspace URL:" -ForegroundColor Cyan
    Write-Host "  https://app.clickup.com/90131096188/v/o/s/$aiAgentsSpaceId" -ForegroundColor Yellow
    Write-Host ""

} catch {
    Write-Host "API Error:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
