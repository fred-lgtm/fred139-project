# Check if task exists
if (Test-Path "../../.env") {
    Get-Content "../../.env" | ForEach-Object {
        if ($_ -match "^([^#].+?)=(.+)$") {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

$token = $env:CLICKUP_TOKEN
$headers = @{
    "Authorization" = $token
    "Content-Type" = "application/json"
}

# Check one of the tasks we created
$taskId = "86ad3h6db"  # Initial Repository Setup

try {
    $task = Invoke-RestMethod -Uri "https://api.clickup.com/api/v2/task/$taskId" -Method GET -Headers $headers
    Write-Host "SUCCESS! Task exists in ClickUp:" -ForegroundColor Green
    Write-Host "  Name: $($task.name)" -ForegroundColor White
    Write-Host "  Status: $($task.status.status)" -ForegroundColor Yellow
    Write-Host "  List: $($task.list.name)" -ForegroundColor Cyan
    Write-Host "  Folder: $($task.folder.name)" -ForegroundColor Cyan
    Write-Host "  URL: $($task.url)" -ForegroundColor Green
    Write-Host ""
    Write-Host "View all tasks in workspace:" -ForegroundColor Cyan
    Write-Host "https://app.clickup.com/90131096188/v/o/s/901311568040" -ForegroundColor Yellow
} catch {
    Write-Host "Error checking task: $($_.Exception.Message)" -ForegroundColor Red
}
