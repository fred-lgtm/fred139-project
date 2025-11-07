# HubSpot Authentication Instructions

## Status: Browser Windows Opened

I've opened two HubSpot authentication pages in your browser:
1. **Personal Access Keys**: https://app.hubspot.com/l/settings/access-keys
2. **Private Apps**: https://app.hubspot.com/l/settings/90131096188/private-apps

## HubSpot CLI Initialization

The HubSpot CLI (`hs init`) is waiting for your input with two options:

### Option 1: Personal Access Key (Recommended for CLI)
1. Go to the **Personal Access Keys** browser tab
2. Click "Create personal access key"
3. Name it: "Brickface CLI - Fred's Workstation"
4. Copy the generated key
5. Return to the terminal and select "Open HubSpot to copy your personal access key"
6. Paste the key when prompted

### Option 2: Use Existing Private App Token
If you prefer to use the existing private app token:
1. Select "Enter existing personal access key" in the CLI prompt
2. Paste: `pat-na1-f7742f9c-b5fb-49f2-8bf7-745ac72c8fe2`

**Note**: The existing private app token appears to be invalid or expired. Personal Access Key is the recommended approach.

## Next Steps After Authentication

Once authenticated, I'll:
1. ✓ Verify HubSpot CLI is working
2. ✓ Test API connection
3. ✓ Configure MCP server with valid credentials
4. ✓ Import the 8 deals ($231,844 pipeline)
5. ✓ Create "Distribute deals" task

## Currently Running

The `hs init` command is running in the background (ID: 771b92) and waiting for your input.

**Please complete the authentication in your browser, then let me know when ready to continue.**
