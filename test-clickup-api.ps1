# Test ClickUp API
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match "^([^#].+?)=(.+)$") {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

$token = $env:CLICKUP_TOKEN
Write-Host "Testing ClickUp API..."
Write-Host "Token: $($token.Substring(0, 15))..."

$headers = @{
    "Authorization" = $token
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri "https://api.clickup.com/api/v2/team" -Method Get -Headers $headers
    Write-Host "API Connection Successful"
    Write-Host "Team ID: $($response.teams[0].id)"
    Write-Host "Team Name: $($response.teams[0].name)"

    $spacesResponse = Invoke-RestMethod -Uri "https://api.clickup.com/api/v2/team/$($response.teams[0].id)/space?archived=false" -Method Get -Headers $headers
    Write-Host "Existing Spaces:"
    $spacesResponse.spaces | ForEach-Object {
        Write-Host "  - $($_.name) (ID: $($_.id))"
    }
} catch {
    Write-Host "API Error:"
    Write-Host $_.Exception.Message
    if ($_.ErrorDetails) {
        Write-Host $_.ErrorDetails.Message
    }
}
