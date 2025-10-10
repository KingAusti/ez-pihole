# 🚀 Getting Started with Pi-hole on Mac mini

Welcome! This guide will get you up and running with Pi-hole in just a few minutes.

## 📋 Prerequisites

1. **Mac mini** (any model)
2. **Docker Desktop for Mac** - [Download here](https://www.docker.com/products/docker-desktop/)
3. **Internet connection**

## ⚡ Super Quick Start (2 minutes)

1. **Install Docker Desktop** if you haven't already
2. **Open Terminal** and navigate to this folder:
   ```bash
   cd /path/to/pihole-docker
   ```
3. **Run the easy launcher**:
   ```bash
   ./start-pihole.sh
   ```
4. **Follow the prompts** - The script will guide you through everything!

That's it! 🎉

## 🎯 What Each Script Does

### `start-pihole.sh` - Main Launcher ⭐
- **Start here!** This is your main entry point
- Automatically detects if you need setup or just want to manage Pi-hole
- Provides simple menu options for common tasks
- Perfect for first-time users

### `first-time-setup.sh` - Setup Wizard 🧙‍♂️
- Interactive step-by-step setup process
- Automatically detects your Mac's IP address
- Lets you choose DNS servers and password
- Checks for port conflicts
- Opens the admin interface when done

### `pihole-manager.sh` - Advanced Management 🔧
- Full-featured management interface
- Start/stop/restart Pi-hole
- View logs and statistics
- Update Pi-hole
- Edit configuration
- Troubleshooting tools

### `network-setup.sh` - Network Helper 🌐
- Helps configure your network to use Pi-hole
- Device-specific instructions (macOS, iOS, Android, etc.)
- Router configuration guidance
- Network testing tools

### `status.sh` - Status Dashboard 📊
- Quick overview of Pi-hole status
- Real-time statistics
- Live monitoring mode
- Health checks

## 🔧 Common Tasks

### First Time Setup
```bash
./start-pihole.sh
# Choose "Run setup wizard" when prompted
```

### Daily Use
```bash
./start-pihole.sh
# Choose "Open admin interface" or "View status"
```

### Troubleshooting
```bash
./pihole-manager.sh
# Choose "Troubleshooting" from the menu
```

### Network Configuration
```bash
./network-setup.sh
# Follow the guided network setup
```

## 🌐 After Setup

Once Pi-hole is running, you'll need to configure your devices to use it:

### Option 1: Configure Your Router (Recommended)
- Set your router's DNS server to your Mac mini's IP address
- This automatically applies Pi-hole to all devices on your network

### Option 2: Configure Individual Devices
- Set each device's DNS server to your Mac mini's IP address
- Use the network setup helper for device-specific instructions

## 🆘 Need Help?

1. **Check the status**: `./status.sh`
2. **View logs**: `./pihole-manager.sh` → "View logs"
3. **Run diagnostics**: `./pihole-manager.sh` → "Troubleshooting"
4. **Read the full README**: `README.md`

## 🎉 You're All Set!

Once configured, Pi-hole will:
- ✅ Block ads across your entire network
- ✅ Block trackers and malware
- ✅ Speed up your browsing
- ✅ Provide detailed statistics
- ✅ Work on all your devices

Enjoy your ad-free network! 🎊
