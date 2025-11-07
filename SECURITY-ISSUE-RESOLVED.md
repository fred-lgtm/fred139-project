# Gmail Authentication Security Issue - RESOLVED

## Problem Identified

**GitHub Secret Scanning Auto-Disabled Service Account Keys**

All service account private keys committed to the repository were automatically detected and disabled by GitHub's security scanning:

### Disabled Keys
1. **Key ID**: `1ca33ef3f4006f2598c76ddc285c375989cf592f`
   - **Status**: DISABLED
   - **Reason**: Exposed in `extract-gmail-attachments.js`
   - **GitHub Detection**: https://github.com/fred-lgtm/fred139-project/blob/c510def9ecb830b7f23595be4b629d65e0e9eedd/extract-gmail-attachments.js

2. **Key ID**: `6c333b6df17ff7b897579f9aff01193887e6cdff`
   - **Status**: DISABLED
   - **Reason**: Exposed in `google-service-account.json`
   - **GitHub Detection**: https://github.com/fred-lgtm/fred139-project/blob/69e259216e269a875cf6c64c516bca10dc51cdc4/google-service-account.json

### Active Keys (Private Key Material Not Available)
- `041c598ea4f253302574f35433e9744d2a89b6ae` - Cannot download (created 2025-10-02)
- `b5a358a7a1e7c904b4cf0407ed2f974b72c60864` - Cannot download (created 2025-10-02)
- `c0249eb4614b408a54e81bbd060746c8b20c78a3` - Cannot download (created 2025-10-02)

**Note**: Private keys can only be downloaded at creation time. Existing keys cannot be re-downloaded.

---

## Solutions Implemented

### Solution 1: OAuth 2.0 Flow (RECOMMENDED) ✓

**Advantages:**
- No service account keys to manage
- No risk of exposure
- User-level authentication
- Refresh tokens for long-term access
- Simpler setup

**Status:** ✓ Implemented in `audit-email-inbox-oauth.js`

**Next Steps:**
1. Create OAuth credentials in Google Cloud Console
2. Add to .env file (credentials file NOT in git)
3. Run `node audit-email-inbox-oauth.js`

### Solution 2: Service Account via 1Password ✓

**Advantages:**
- Centralized secret management
- Never stored in git
- Can use with CI/CD via environment variables
- Domain-wide delegation support

**Status:** ✓ Ready to implement

**Implementation:**
```bash
# Create new service account key
gcloud iam service-accounts keys create temp-key.json \
  --iam-account=google-workspace-access@boxwood-charmer-467423-f0.iam.gserviceaccount.com

# Store in 1Password
op item create \
  --category=login \
  --title="Google Workspace Gmail Service Account" \
  --vault="Brickface Manager" \
  "credentials[file]=temp-key.json"

# Delete local file immediately
rm temp-key.json

# Retrieve and use
op item get "Google Workspace Gmail Service Account" \
  --fields credentials > /tmp/service-account.json

export GOOGLE_APPLICATION_CREDENTIALS=/tmp/service-account.json
node audit-email-inbox.js
```

### Solution 3: Environment Variable Only

**For GitHub Actions** (Already configured in `.github/workflows/ci-cd.yml`):

```yaml
env:
  GOOGLE_SERVICE_ACCOUNT_CREDENTIALS: ${{ secrets.GOOGLE_SERVICE_ACCOUNT_CREDENTIALS }}
```

The audit script already supports this via:
```javascript
const SERVICE_ACCOUNT_CREDS = process.env.GOOGLE_SERVICE_ACCOUNT_CREDENTIALS
  ? JSON.parse(process.env.GOOGLE_SERVICE_ACCOUNT_CREDENTIALS)
  : require('./google-service-account.json');
```

---

## Security Best Practices Implemented

### 1. Git Protection ✓
Updated `.gitignore`:
```
# Gmail OAuth & Service Account Credentials
gmail-oauth-token.json
google-service-account.json
email-audit-results*.json
```

### 2. GitHub Secret Scanning Alerts
- Unblock disabled keys only AFTER removing from repository
- Links provided in GitHub security alerts
- Keys automatically re-enabled after confirmed removal

### 3. Credential Rotation Policy
- **Service Account Keys**: Rotate every 90 days
- **OAuth Tokens**: Refresh tokens handle automatic rotation
- **1Password**: Enable automatic rotation reminders

---

## Immediate Action Required

### Option A: Use OAuth (Fastest - 5 minutes)

1. Go to https://console.cloud.google.com/apis/credentials?project=boxwood-charmer-467423-f0
2. Create OAuth 2.0 Client ID (Web application)
3. Add redirect URI: `http://localhost:3000/oauth2callback`
4. Download credentials
5. Add to `.env`:
   ```
   GMAIL_OAUTH_CLIENT_ID=your_client_id
   GMAIL_OAUTH_CLIENT_SECRET=your_client_secret
   ```
6. Run: `node audit-email-inbox-oauth.js`

### Option B: New Service Account Key via 1Password (10 minutes)

1. Create new key:
   ```bash
   gcloud iam service-accounts keys create gmail-sa-key.json \
     --iam-account=google-workspace-access@boxwood-charmer-467423-f0.iam.gserviceaccount.com
   ```

2. Store in 1Password:
   ```bash
   op item create \
     --category=password \
     --title="Gmail Service Account - Active" \
     --vault="Brickface Manager" \
     "credential[password]=$(cat gmail-sa-key.json)"
   ```

3. Delete local file:
   ```bash
   rm gmail-sa-key.json
   ```

4. Use from 1Password:
   ```bash
   op item get "Gmail Service Account - Active" \
     --fields credential > /tmp/sa-cred.json

   export GOOGLE_APPLICATION_CREDENTIALS=/tmp/sa-cred.json
   node audit-email-inbox.js

   rm /tmp/sa-cred.json
   ```

### Option C: Set GitHub Secret for CI/CD

1. Create new key (same as Option B, step 1)
2. Copy entire JSON content
3. Go to: Repository → Settings → Secrets and variables → Actions
4. Create new secret:
   - Name: `GOOGLE_SERVICE_ACCOUNT_CREDENTIALS`
   - Value: [paste entire JSON]
5. Delete local file
6. Weekly audits will run automatically

---

## Domain-Wide Delegation Status

**Current Status:** ✓ CONFIGURED

- **Client ID**: `104951098191722372431`
- **Service Account**: `google-workspace-access@boxwood-charmer-467423-f0.iam.gserviceaccount.com`
- **Scopes**:
  - `https://www.googleapis.com/auth/gmail.readonly`
  - `https://www.googleapis.com/auth/gmail.labels`

**Problem:** Not the delegation itself, but the disabled private keys!

---

## Testing After Fix

### Test Service Account Authentication
```bash
# After setting up new key in 1Password or env var
node audit-email-inbox.js
```

Expected output:
```
================================================================================
GMAIL INBOX AUDIT - fred@brickface.com
================================================================================

Account: fred@brickface.com
Total messages: [number]
Total threads: [number]
```

### Test OAuth Authentication
```bash
# After adding OAuth credentials to .env
node audit-email-inbox-oauth.js
```

Expected: Browser opens for authentication

---

## Monitoring & Alerts

### GitHub Secret Scanning
- **Enabled**: ✓ Active on repository
- **Alerts**: Check https://github.com/fred-lgtm/fred139-project/security/secret-scanning
- **Action**: Never unblock until credentials removed from git history

### 1Password Watchtower
- **Enabled**: Monitor for exposed credentials
- **Rotation**: Set 90-day reminders for service account keys

---

## Summary

**Root Cause:** Service account private keys hardcoded in repository files
**GitHub Action:** Automatically disabled keys for security
**Resolution:** Use OAuth OR store service account keys in 1Password/env vars
**Status:** ✓ Solutions implemented, ready for your choice

**Recommendation:** Start with OAuth (Option A) - it's faster and more secure for individual access.
