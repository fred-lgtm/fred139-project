#!/bin/bash
# Gmail OAuth Setup with GCP Secret Manager
# This script creates OAuth credentials and stores them securely

set -e

PROJECT_ID="boxwood-charmer-467423-f0"
OAUTH_CLIENT_NAME="gmail-inbox-audit-oauth"

echo "=================================================="
echo "Gmail OAuth Credentials Setup"
echo "=================================================="
echo ""

# Enable required APIs
echo "1. Enabling required APIs..."
gcloud services enable \
  secretmanager.googleapis.com \
  iamcredentials.googleapis.com \
  --project=$PROJECT_ID

echo "✓ APIs enabled"
echo ""

# Note: OAuth client creation requires manual setup via console
echo "2. Creating OAuth 2.0 Client ID..."
echo ""
echo "⚠️  OAuth credentials must be created via Google Cloud Console:"
echo ""
echo "   1. Visit: https://console.cloud.google.com/apis/credentials?project=$PROJECT_ID"
echo "   2. Click 'CREATE CREDENTIALS' → 'OAuth client ID'"
echo "   3. Application type: Web application"
echo "   4. Name: $OAUTH_CLIENT_NAME"
echo "   5. Authorized redirect URIs:"
echo "      - http://localhost:3000/oauth2callback"
echo "      - http://127.0.0.1:3000/oauth2callback"
echo "   6. Click 'CREATE'"
echo "   7. Download the JSON file"
echo ""
read -p "Press Enter after you've downloaded the OAuth credentials JSON file..."

# Prompt for the downloaded file path
read -p "Enter the path to the downloaded OAuth JSON file: " OAUTH_FILE

if [ ! -f "$OAUTH_FILE" ]; then
  echo "❌ File not found: $OAUTH_FILE"
  exit 1
fi

# Extract client ID and secret from the JSON file
CLIENT_ID=$(cat "$OAUTH_FILE" | grep -o '"client_id":"[^"]*' | cut -d'"' -f4)
CLIENT_SECRET=$(cat "$OAUTH_FILE" | grep -o '"client_secret":"[^"]*' | cut -d'"' -f4)

if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ]; then
  echo "❌ Could not extract client_id or client_secret from the file"
  exit 1
fi

echo ""
echo "✓ Extracted OAuth credentials"
echo "   Client ID: $CLIENT_ID"
echo ""

# Store in GCP Secret Manager
echo "3. Storing credentials in GCP Secret Manager..."

# Store Client ID
echo "$CLIENT_ID" | gcloud secrets create gmail-oauth-client-id \
  --project=$PROJECT_ID \
  --replication-policy="automatic" \
  --data-file=- 2>/dev/null || \
echo "$CLIENT_ID" | gcloud secrets versions add gmail-oauth-client-id \
  --project=$PROJECT_ID \
  --data-file=-

# Store Client Secret
echo "$CLIENT_SECRET" | gcloud secrets create gmail-oauth-client-secret \
  --project=$PROJECT_ID \
  --replication-policy="automatic" \
  --data-file=- 2>/dev/null || \
echo "$CLIENT_SECRET" | gcloud secrets versions add gmail-oauth-client-secret \
  --project=$PROJECT_ID \
  --data-file=-

echo "✓ Credentials stored in Secret Manager"
echo ""

# Securely delete the downloaded file
echo "4. Cleaning up..."
rm "$OAUTH_FILE"
echo "✓ Downloaded credentials file deleted"
echo ""

# Store in 1Password
echo "5. Storing in 1Password..."
op item create \
  --category=login \
  --title="Gmail OAuth - Inbox Audit $(date +%Y-%m-%d)" \
  --vault="Brickface Manager" \
  "client_id[password]=$CLIENT_ID" \
  "client_secret[password]=$CLIENT_SECRET" \
  "url[url]=https://console.cloud.google.com/apis/credentials?project=$PROJECT_ID" \
  > /dev/null 2>&1

echo "✓ Credentials stored in 1Password"
echo ""

# Create .env.local file with references
echo "6. Creating .env.local file..."
cat > .env.local <<EOF
# Gmail OAuth Credentials (automatically loaded from GCP Secret Manager)
# DO NOT commit this file to git!
GMAIL_OAUTH_CLIENT_ID=$CLIENT_ID
GMAIL_OAUTH_CLIENT_SECRET=$CLIENT_SECRET
EOF

echo "✓ Created .env.local file"
echo ""

echo "=================================================="
echo "✓ Setup Complete!"
echo "=================================================="
echo ""
echo "Your Gmail OAuth credentials are now stored in:"
echo "  • GCP Secret Manager (gmail-oauth-client-id, gmail-oauth-client-secret)"
echo "  • 1Password (Gmail OAuth - Inbox Audit)"
echo "  • .env.local (local development only)"
echo ""
echo "To retrieve credentials:"
echo "  gcloud secrets versions access latest --secret=gmail-oauth-client-id"
echo "  gcloud secrets versions access latest --secret=gmail-oauth-client-secret"
echo ""
echo "To run the inbox audit:"
echo "  node audit-email-inbox-oauth.js"
echo ""
