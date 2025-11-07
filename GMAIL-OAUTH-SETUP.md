# Gmail OAuth Setup Guide

This guide will help you set up OAuth 2.0 authentication for the Gmail inbox audit scripts.

## Current Status

- **Service Account**: Already configured (`google-workspace-access@boxwood-charmer-467423-f0.iam.gserviceaccount.com`)
- **Issue**: Domain-wide delegation not properly configured, causing authentication failures
- **Solution**: Use OAuth 2.0 user authentication instead (more reliable for individual access)

## Two Authentication Methods

### Method 1: OAuth 2.0 User Authentication (RECOMMENDED)

This method is simpler and doesn't require Google Workspace Admin access.

#### Step 1: Enable Gmail API

```bash
gcloud services enable gmail.googleapis.com
```

#### Step 2: Create OAuth 2.0 Credentials

1. Go to [Google Cloud Console - Credentials](https://console.cloud.google.com/apis/credentials?project=boxwood-charmer-467423-f0)

2. Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**

3. If prompted, configure the OAuth consent screen:
   - User Type: **External**
   - App name: **Brickface Gmail Integration**
   - User support email: **fred@brickface.com**
   - Developer contact: **fred@brickface.com**
   - Scopes: Add these scopes:
     - `https://www.googleapis.com/auth/gmail.readonly`
     - `https://www.googleapis.com/auth/gmail.labels`

4. Create OAuth Client ID:
   - Application type: **Web application**
   - Name: **Brickface Gmail Audit**
   - Authorized redirect URIs:
     - `http://localhost:3000/oauth2callback`
     - `http://127.0.0.1:3000/oauth2callback`

5. Download the credentials JSON file

#### Step 3: Add Credentials to .env

Open your `.env` file and add:

```env
GMAIL_OAUTH_CLIENT_ID=your_client_id_from_credentials.json
GMAIL_OAUTH_CLIENT_SECRET=your_client_secret_from_credentials.json
```

#### Step 4: Run the OAuth Audit Script

```bash
node audit-email-inbox-oauth.js
```

The script will:
1. Open your browser for authentication
2. Ask you to grant permissions
3. Save the token for future use (`gmail-oauth-token.json`)
4. Run the inbox audit

#### Step 5: Subsequent Runs

After the first authentication, the script will use the saved token automatically.

---

### Method 2: Service Account with Domain-Wide Delegation

This method requires Google Workspace Admin access.

#### Configure Domain-Wide Delegation

1. Go to [Google Workspace Admin Console](https://admin.google.com/)
2. Navigate to: **Security → Access and data control → API Controls → Domain-wide Delegation**
3. Click **"Add new"**
4. Add the following:
   - **Client ID**: `104951098191722372431`
   - **OAuth Scopes**:
     ```
     https://www.googleapis.com/auth/gmail.readonly,https://www.googleapis.com/auth/gmail.labels
     ```
5. Click **Authorize**

#### Run Service Account Audit

```bash
node audit-email-inbox.js
```

---

## Gmail Inbox Audit Features

Both scripts provide comprehensive inbox analysis:

- **Email categorization** (spam vs business)
- **Top senders analysis**
- **Domain reputation tracking**
- **Spam pattern detection**
- **Business email breakdown**
- **Label management insights**
- **30-day historical analysis**

## Output Files

- **OAuth version**: `email-audit-results-oauth.json`
- **Service Account version**: `email-audit-results.json`

## Automated Audits (GitHub Actions)

The GitHub workflow (`.github/workflows/ci-cd.yml`) includes:

- **Weekly scheduled audit**: Every Monday at 9 AM UTC
- **Artifact storage**: Results saved for 90 days
- **Environment**: Uses `GOOGLE_SERVICE_ACCOUNT_CREDENTIALS` secret

### Setting up GitHub Secrets

Add this secret to your repository:

```bash
# Get the service account credentials
cat google-service-account.json

# Add to GitHub:
# Repository → Settings → Secrets and variables → Actions → New repository secret
# Name: GOOGLE_SERVICE_ACCOUNT_CREDENTIALS
# Value: [paste the entire JSON content]
```

## Troubleshooting

### "Invalid grant" error

This means domain-wide delegation isn't configured. Use OAuth method instead.

### OAuth consent screen not configured

Follow Step 3 in Method 1 to configure the consent screen.

### Port 3000 already in use

The OAuth callback server uses port 3000. Make sure no other application is using this port.

### Token expired

Delete `gmail-oauth-token.json` and run the script again to re-authenticate.

## Security Notes

- **OAuth tokens** are stored locally in `gmail-oauth-token.json` (add to `.gitignore`)
- **Service account keys** should never be committed to git
- Both files are already in `.gitignore`
- Tokens have refresh capabilities for long-term use

## Next Steps

1. Choose authentication method (OAuth recommended)
2. Follow setup steps above
3. Run the audit script
4. Review results in the JSON output file
5. Optionally set up automated audits in GitHub Actions

---

**Need help?** Contact the development team or check the [Google Gmail API Documentation](https://developers.google.com/gmail/api).
