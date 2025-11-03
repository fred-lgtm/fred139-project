# 🚀 Brickface Enterprise - Quick Setup Guide

## Overview
Complete setup for seamless development between your **Home PC** 🏠 and **Office PC** 🏢 with **ZERO commands to remember**!

## 🎯 One-Time Setup (Each Computer)

### 🏠 Home PC Setup
1. **Download** this repository
2. **Run** `setup-home-pc.ps1` (right-click → Run with PowerShell)
3. **Follow prompts** for authentication
4. **Copy .env credentials** from 1Password

### 🏢 Office PC Setup  
1. **Download** this repository  
2. **Run** `setup-office-pc.ps1` (right-click → Run with PowerShell)
3. **Follow prompts** for authentication
4. **Copy .env credentials** from Home PC (same exact file)

## 🎮 Daily Usage (No Commands!)

### 🌅 Start Your Day
**Home PC:** Double-click `🏠 Start Work (Home)` on desktop  
**Office PC:** Double-click `🏢 Start Work (Office)` on desktop

**What happens automatically:**
- ✅ Pulls latest changes from GitHub
- ✅ Opens VS Code workspace  
- ✅ Starts Claude AI with MCP servers
- ✅ Launches browser with work tabs
- ✅ Shows today's agenda

### 🌆 End Your Day
**Home PC:** Double-click `🌅 End Work (Home)` on desktop  
**Office PC:** Double-click `🌆 End Work (Office)` on desktop

**What happens automatically:**
- ✅ Saves all work and commits changes
- ✅ Pushes to GitHub for sync
- ✅ Generates work summary
- ✅ Backs up to Google Cloud
- ✅ Closes applications cleanly

## 🔄 Seamless Computer Switching

```
🏠 Home PC                🏢 Office PC
    ↓                         ↓
Click "End Work"         Click "Start Work"
    ↓                         ↓
Auto-commit & push  →  Auto-pull & sync
    ↓                         ↓
Work saved to cloud     Continue exactly where you left off
```

**No git commands, no manual syncing, no lost work!**

## 🛠️ What's Installed

### Development Tools
- **Git** - Version control
- **VS Code** - IDE with all extensions
- **Node.js** - JavaScript runtime
- **Python** - AI and automation
- **GitHub CLI** - GitHub integration
- **Google Cloud CLI** - GCP integration

### AI & Integration
- **Claude AI** - MCP servers for:
  - 🏢 HubSpot CRM
  - 📋 ClickUp project management  
  - 📞 Dialpad communications
  - 💰 Ramp financial tools
  - 📧 Google Workspace
  - 🗃️ PostgreSQL database
  - 🔍 Brave search

### Automation
- **Daily workflows** - Start/end work automation
- **Auto-sync** - GitHub push/pull
- **Cloud backup** - Google Cloud storage
- **Environment consistency** - Same .env on both PCs

## 🔐 Security & Credentials

### Required API Keys (.env file)
```bash
# AI Services
ANTHROPIC_API_KEY=your_claude_key_here
OPENAI_API_KEY=your_openai_key_here

# Business Integrations
HUBSPOT_ACCESS_TOKEN=your_hubspot_token_here
CLICKUP_API_TOKEN=your_clickup_token_here  
DIALPAD_API_KEY=your_dialpad_key_here
RAMP_API_TOKEN=your_ramp_token_here

# Development
GITHUB_PERSONAL_ACCESS_TOKEN=your_github_token_here
GOOGLE_CLOUD_PROJECT_ID=boxwood-charmer-467423-f0

# Database
POSTGRES_CONNECTION_STRING=your_postgres_connection_here
```

### 🔒 Security Best Practices
- ✅ .env files are git-ignored
- ✅ Same credentials on both computers
- ✅ Store master copy in 1Password
- ✅ Never commit secrets to git

## 📁 Project Structure

```
brickface-enterprise/
├── 🏢 Brickface Enterprise/     # Main application
├── 🔗 Integrations/             # HubSpot, ClickUp, Dialpad
├── 🤖 AI Agents/                # Claude MCP servers  
├── ☁️ Cloud Infrastructure/     # Google Cloud configs
├── 📊 Analytics/                # Data and reporting
├── 🧪 Testing/                  # Test suites
├── 📖 Documentation/            # Project docs
├── 🎨 Assets/                   # Images, icons, media
├── 🔧 Tools/                    # Utilities and scripts
└── 🗃️ Data/                     # Local data files
```

## 🆘 Troubleshooting

### Common Issues
**Q: "Command not found" errors**  
**A:** Re-run setup script or restart terminal

**Q: Authentication failed**  
**A:** Run `gh auth login` and `gcloud auth login`

**Q: .env file missing values**  
**A:** Copy credentials from 1Password to .env file

**Q: VS Code extensions not working**  
**A:** Restart VS Code, extensions install automatically

### Get Help
- 💬 **Ask Claude AI** in VS Code (built-in chat)
- 📖 **Check docs/** folder for detailed guides
- 🔍 **Search GitHub issues** for known problems

## 🎉 That's It!

Your complete professional development environment is ready.

**Home PC** ↔ **Office PC** sync with zero manual work.

Just click the desktop shortcuts and focus on building amazing things! 🚀