# 🏠🔄🏢 Brickface Enterprise - Cross-PC Sync Guide

## Quick Setup Instructions for Home PC

### 1. Copy & Run This Script
Save this to your Home PC and run it in PowerShell (as Administrator):

```powershell
# Download the setup script
curl -o "SETUP-HOME-PC-SYNC.ps1" "https://raw.githubusercontent.com/fred-lgtm/fred139-project/main/SETUP-HOME-PC-SYNC.ps1"

# Or copy the script from your Office PC to USB/OneDrive
# Then run:
.\SETUP-HOME-PC-SYNC.ps1
```

### 2. What the Script Does Automatically
- ✅ Clones your entire workspace from GitHub
- ✅ Sets up Git configuration (fred@brickface.com)
- ✅ Creates `.env` file from template
- ✅ Installs Node.js dependencies
- ✅ Sets up Python environment
- ✅ Creates Home PC workflow scripts
- ✅ Creates desktop shortcuts
- ✅ Verifies everything is working

### 3. Daily Workflow - Office to Home

**On Office PC (End of Day):**
```powershell
.\end-work.ps1
# This automatically saves and pushes everything to GitHub
```

**On Home PC (Start of Evening):**
```powershell
.\start-work-home.ps1
# This automatically pulls latest from GitHub and opens VS Code
```

**On Home PC (End of Evening):**
```powershell
.\end-work-home.ps1
# This automatically saves and pushes back to GitHub
```

**Next Day on Office PC:**
```powershell
.\start-work.ps1
# This automatically pulls your home work and continues seamlessly
```

### 4. After Setup - Important Steps

1. **Edit .env file** with your actual credentials:
   ```
   C:\Users\[YourName]\fred139-project\.env
   ```

2. **Test the sync** by making a small change and running the workflow

3. **Install recommended tools** (if not already installed):
   - VS Code: https://code.visualstudio.com/
   - Node.js: https://nodejs.org/
   - Git: https://git-scm.com/download/win
   - Google Cloud CLI: https://cloud.google.com/sdk/docs/install

### 5. Troubleshooting

**If Git authentication fails:**
```powershell
# Configure Git credentials
git config --global user.email "fred@brickface.com"
git config --global user.name "Fred Ohen"

# Set up GitHub authentication
gh auth login
```

**If workspace doesn't sync:**
```powershell
# Manual sync
cd C:\Users\[YourName]\fred139-project
git pull origin main
git push origin main
```

**If VS Code doesn't open workspace:**
```powershell
# Open manually
code C:\Users\[YourName]\fred139-project\brickface-enterprise.code-workspace
```

### 6. File Locations After Setup

```
🏠 Home PC Structure:
C:\Users\[YourName]\fred139-project\
├── 📁 integrations/          # MCP servers & integrations
├── 📁 scripts/               # Automation scripts  
├── 📁 docs/                  # Documentation
├── 📁 agents/                # AI agents
├── 📁 hubspot/               # HubSpot schemas
├── 📁 n8n-workflows/         # n8n automation
├── 📁 cloud/                 # Infrastructure code
├── 📁 dashboards/            # Analytics dashboards
├── 📁 config/                # Configuration files
├── 🔧 brickface-enterprise.code-workspace  # VS Code workspace
├── ⚙️ .env                   # Your environment variables
├── 🚀 start-work-home.ps1    # Home PC start script
├── 💾 end-work-home.ps1      # Home PC end script
└── 📊 home-pc-setup-status.json  # Setup verification
```

### 7. Desktop Shortcuts Created

After setup, you'll have these shortcuts on your desktop:
- 🚀 **Brickface Start Work (Home)** - Double-click to start working
- 💾 **Brickface End Work (Home)** - Double-click to save & sync

### 8. Verification Commands

**Check if everything is working:**
```powershell
# Navigate to workspace
cd C:\Users\[YourName]\fred139-project

# Check Git status
git status

# Check if all files are there
ls

# Check environment file
cat .env.example
```

### 9. Success Indicators

✅ **Setup is successful when:**
- Git repository cloned and configured
- VS Code workspace opens correctly
- `.env` file exists with your credentials
- Desktop shortcuts work
- Start/end scripts run without errors
- You can see all your Office PC files and folders

### 10. Support

**If you need help:**
1. Check the log file created during setup
2. Review the setup status: `home-pc-setup-status.json`
3. Run the verification commands above
4. Try the manual sync commands if automatic sync fails

**Remember:** This gives you seamless Office ↔ Home PC workflow with zero commands to remember - just double-click the desktop shortcuts!