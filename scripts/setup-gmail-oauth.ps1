# Gmail OAuth Setup with GCP Secret Manager (PowerShell)
# This script creates OAuth credentials and stores them securely

$ErrorActionPreference = "Stop"
$PROJECT_ID = "boxwood-charmer-467423-f0"
$OAUTH_CLIENT_NAME = "gmail-inbox-audit-oauth"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Gmail OAuth Credentials Setup" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Enable required APIs
Write-Host "1. Enabling required APIs..." -ForegroundColor Yellow
gcloud services enable secretmanager.googleapis.com iamcredentials.googleapis.com --project=$PROJECT_ID
Write-Host "✓ APIs enabled" -ForegroundColor Green
Write-Host ""

# Open browser to create OAuth credentials
Write-Host "2. Creating OAuth 2.0 Client ID..." -ForegroundColor Yellow
Write-Host ""
Write-Host "⚠️  OAuth credentials must be created via Google Cloud Console:" -ForegroundColor Magenta
Write-Host ""
Write-Host "   1. Opening browser to credentials page..."
Write-Host "   2. Click 'CREATE CREDENTIALS' → 'OAuth client ID'"
Write-Host "   3. Application type: Web application"
Write-Host "   4. Name: $OAUTH_CLIENT_NAME"
Write-Host "   5. Authorized redirect URIs:"
Write-Host "      - http://localhost:3000/oauth2callback"
Write-Host "      - http://127.0.0.1:3000/oauth2callback"
Write-Host "   6. Click 'CREATE'"
Write-Host "   7. Download the JSON file"
Write-Host ""

Start-Process "https://console.cloud.google.com/apis/credentials?project=$PROJECT_ID"

Read-Host "Press Enter after you've downloaded the OAuth credentials JSON file"

# Prompt for the downloaded file path
$OAUTH_FILE = Read-Host "Enter the full path to the downloaded OAuth JSON file"

if (-not (Test-Path $OAUTH_FILE)) {
    Write-Host "❌ File not found: $OAUTH_FILE" -ForegroundColor Red
    exit 1
}

# Parse JSON and extract credentials
$oauthContent = Get-Content $OAUTH_FILE -Raw | ConvertFrom-Json
$CLIENT_ID = $oauthContent.web.client_id
$CLIENT_SECRET = $oauthContent.web.client_secret

if (-not $CLIENT_ID -or -not $CLIENT_SECRET) {
    Write-Host "❌ Could not extract client_id or client_secret from the file" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✓ Extracted OAuth credentials" -ForegroundColor Green
Write-Host "   Client ID: $CLIENT_ID"
Write-Host ""

# Store in GCP Secret Manager
Write-Host "3. Storing credentials in GCP Secret Manager..." -ForegroundColor Yellow

# Store Client ID
try {
    $CLIENT_ID | gcloud secrets create gmail-oauth-client-id --project=$PROJECT_ID --replication-policy="automatic" --data-file=- 2>&1 | Out-Null
} catch {
    $CLIENT_ID | gcloud secrets versions add gmail-oauth-client-id --project=$PROJECT_ID --data-file=- | Out-Null
}

# Store Client Secret
try {
    $CLIENT_SECRET | gcloud secrets create gmail-oauth-client-secret --project=$PROJECT_ID --replication-policy="automatic" --data-file=- 2>&1 | Out-Null
} catch {
    $CLIENT_SECRET | gcloud secrets versions add gmail-oauth-client-secret --project=$PROJECT_ID --data-file=- | Out-Null
}

Write-Host "✓ Credentials stored in Secret Manager" -ForegroundColor Green
Write-Host ""

# Securely delete the downloaded file
Write-Host "4. Cleaning up..." -ForegroundColor Yellow
Remove-Item $OAUTH_FILE -Force
Write-Host "✓ Downloaded credentials file deleted" -ForegroundColor Green
Write-Host ""

# Store in 1Password
Write-Host "5. Storing in 1Password..." -ForegroundColor Yellow
$date = Get-Date -Format "yyyy-MM-dd"
try {
    op item create `
        --category=login `
        --title="Gmail OAuth - Inbox Audit $date" `
        --vault="Brickface Manager" `
        "client_id[password]=$CLIENT_ID" `
        "client_secret[password]=$CLIENT_SECRET" `
        "url[url]=https://console.cloud.google.com/apis/credentials?project=$PROJECT_ID" `
        | Out-Null
    Write-Host "✓ Credentials stored in 1Password" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not store in 1Password (continuing anyway)" -ForegroundColor Yellow
}
Write-Host ""

# Create .env.local file with references
Write-Host "6. Creating .env.local file..." -ForegroundColor Yellow
@"
# Gmail OAuth Credentials (automatically loaded from GCP Secret Manager)
# DO NOT commit this file to git!
GMAIL_OAUTH_CLIENT_ID=$CLIENT_ID
GMAIL_OAUTH_CLIENT_SECRET=$CLIENT_SECRET
"@ | Out-File -FilePath ".env.local" -Encoding UTF8

Write-Host "✓ Created .env.local file" -ForegroundColor Green
Write-Host ""

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "✓ Setup Complete!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your Gmail OAuth credentials are now stored in:"
Write-Host "  • GCP Secret Manager (gmail-oauth-client-id, gmail-oauth-client-secret)"
Write-Host "  • 1Password (Gmail OAuth - Inbox Audit)"
Write-Host "  • .env.local (local development only)"
Write-Host ""
Write-Host "To retrieve credentials:"
Write-Host "  gcloud secrets versions access latest --secret=gmail-oauth-client-id"
Write-Host "  gcloud secrets versions access latest --secret=gmail-oauth-client-secret"
Write-Host ""
Write-Host "To run the inbox audit:"
Write-Host "  node audit-email-inbox-oauth.js"
Write-Host ""
