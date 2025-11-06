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
- ✅ **Sets up automatic background save service**
- ✅ **Configures VS Code auto-save integration**
- ✅ Verifies everything is working

### 3. Daily Workflow - Fully Automated

**🔄 NEW: Zero-Click Workflow (RECOMMENDED)**
- **Office PC:** Work normally, changes save automatically every 5 minutes
- **Home PC:** Work normally, changes save automatically every 5 minutes  
- **No manual commands needed!** Everything syncs in the background

**📝 Original Manual Workflow (Still Available)**

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

### 7. Auto-Save Service (NEW!)

After setup, you'll have automatic background saving:
- 🔄 **Auto-Save Service** - Saves changes every 5 minutes automatically
- 🎯 **VS Code Integration** - Tasks for managing auto-save
- 📊 **Status Monitoring** - Check auto-save status anytime

**Auto-Save Controls:**
```powershell
# Check if auto-save is running
Test-Path "auto-save.pid"

# View auto-save status
Get-Content auto-save-status.json | ConvertFrom-Json

# Stop auto-save (if needed)
.\stop-auto-save.ps1

# Start auto-save manually
.\auto-save-service.ps1
```

**Via VS Code:**
- `Ctrl+Shift+P` → "Tasks: Run Task" → "Auto-Save Status"
- `Ctrl+Shift+P` → "Tasks: Run Task" → "Stop Auto-Save"
- `Ctrl+Shift+P` → "Tasks: Run Task" → "Start Auto-Save"

### 8. Desktop Shortcuts Created

### 8. Desktop Shortcuts Created

After setup, you'll have these shortcuts on your desktop:
- 🚀 **Brickface Start Work (Home)** - Double-click to start working
- 💾 **Brickface End Work (Home)** - Double-click to save & sync
- 🔄 **Auto-Save Status** - Check background save service
- 🛑 **Stop Auto-Save** - Stop background saving (if needed)

### 9. Verification Commands

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

# NEW: Check auto-save status
Test-Path "auto-save.pid"
Get-Content auto-save-status.json | ConvertFrom-Json
```

### 10. Success Indicators

✅ **Setup is successful when:**
- Git repository cloned and configured
- VS Code workspace opens correctly
- `.env` file exists with your credentials
- Desktop shortcuts work
- Start/end scripts run without errors
- **Auto-save service is running (auto-save.pid exists)**
- **Auto-save status shows "is_running": true**
- You can see all your Office PC files and folders

### 11. Support

**If you need help:**
1. Check the log file created during setup
2. Review the setup status: `home-pc-setup-status.json`
3. Run the verification commands above
4. Try the manual sync commands if automatic sync fails
5. **NEW: Check auto-save logs:** `auto-save-YYYY-MM-DD.log`
6. **NEW: Review auto-save guide:** `AUTO-SAVE-IMPLEMENTATION-GUIDE.md`

**Remember:** This gives you seamless Office ↔ Home PC workflow with **ZERO commands to remember** - changes save automatically in the background!