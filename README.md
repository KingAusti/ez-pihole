# Pi-hole Docker Setup for Mac mini

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](VERSION)
[![License](https://img.shields.io/badge/license-EUPL--1.2-green.svg)](https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12)

This project provides a complete, user-friendly Docker setup to run Pi-hole on your Mac mini, giving you network-wide ad blocking and DNS filtering capabilities. **Now with automatic port conflict resolution** - Pi-hole will always start, even when default ports are in use!

## 🚀 Super Easy Start (Recommended)

1. **Prerequisites**: Install [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)

2. **Download this project** to your Mac mini

3. **Run the easy launcher**:
   ```bash
   ./start-pihole.sh
   ```

4. **Follow the guided setup** - The script will automatically detect your settings, resolve any port conflicts, and guide you through the process!

5. **Access Pi-hole**: The setup will automatically open the admin interface for you (with the correct port if needed)

## 🎯 Alternative Quick Start

If you prefer the traditional approach:

1. **Run the first-time setup wizard**:
   ```bash
   ./first-time-setup.sh
   ```

2. **Or use the original setup script**:
   ```bash
   ./setup.sh
   ```

## 📋 What's Included

### 🎯 User-Friendly Scripts
- **`start-pihole.sh`** - Main launcher with guided setup and management
- **`first-time-setup.sh`** - Interactive setup wizard with step-by-step guidance
- **`pihole-manager.sh`** - Advanced management interface with menu options
- **`network-setup.sh`** - Network configuration helper with device-specific instructions
- **`status.sh`** - Status dashboard and monitoring tools
- **`resolve-ports.sh`** - Automatic port conflict resolution system
- **`version.sh`** - Version management and changelog system

### ⚙️ Core Components
- **Docker Compose configuration** optimized for Mac mini
- **Environment file** for easy configuration
- **Automated setup script** that detects your IP and starts the container
- **Persistent storage** for Pi-hole configuration and logs
- **Dark theme** enabled by default
- **Cloudflare DNS** as upstream DNS servers
- **Automatic port conflict resolution** - finds alternative ports when needed

## ⚙️ Configuration

### Environment Variables (.env file)

| Variable | Description | Default |
|----------|-------------|---------|
| `SERVER_IP` | Your Mac mini's IP address | Auto-detected |
| `PIHOLE_PASSWORD` | Web interface password | `change-me` |
| `TZ` | Timezone | `America/New_York` |
| `DNS1` | Primary upstream DNS | `1.1.1.1` (Cloudflare) |
| `DNS2` | Secondary upstream DNS | `1.0.0.1` (Cloudflare) |
| `DNS_PORT` | DNS server port | `53` (auto-detected) |
| `HTTP_PORT` | Web interface HTTP port | `80` (auto-detected) |
| `HTTPS_PORT` | Web interface HTTPS port | `443` (auto-detected) |

### Customizing DNS Servers

You can change the upstream DNS servers by editing the `.env` file:

```bash
# Google DNS
DNS1=8.8.8.8
DNS2=8.8.4.4

# OpenDNS
DNS1=208.67.222.222
DNS2=208.67.220.220
```

## 🔧 Usage

### 🎯 Easy Management (Recommended)
```bash
# Main launcher - handles everything automatically
./start-pihole.sh

# Advanced management with menu options
./pihole-manager.sh

# Network configuration helper
./network-setup.sh

# Quick status check
./status.sh

# Resolve port conflicts automatically
./resolve-ports.sh

# Show version information
./version.sh show
```

### 🔧 Manual Commands
```bash
# Starting Pi-hole
docker-compose up -d
# or
docker compose up -d

# Stopping Pi-hole
docker-compose down
# or
docker compose down

# Viewing Logs
docker-compose logs -f pihole
# or
docker compose logs -f pihole

# Updating Pi-hole
docker-compose pull && docker-compose up -d
# or
docker compose pull && docker compose up -d
```

## 🔧 Port Conflict Resolution

This project includes an **automatic port conflict resolution system** that ensures Pi-hole can always start, even when the default ports are in use.

### How It Works
- **Automatic Detection**: Checks if ports 53, 80, and 443 are available
- **Smart Alternatives**: Finds alternative ports when conflicts exist:
  - DNS alternatives: 5353, 8053, 9053, or any available port
  - HTTP alternatives: 8080, 9080, 8000, 9000, or any available port
  - HTTPS alternatives: 8443, 9443, 8001, 9001, or any available port
- **Configuration Updates**: Automatically updates Docker Compose and environment files
- **Clear Feedback**: Shows exactly what ports are being used

### Usage
```bash
# Automatic resolution during setup
./start-pihole.sh
./first-time-setup.sh

# Manual port conflict resolution
./resolve-ports.sh

# View current port configuration
./pihole-manager.sh  # Choose option 13
```

### Example Output
```
🔧 Pi-hole Port Conflict Resolution
====================================

✅ Port 53 (DNS) is available
✅ Port 80 (HTTP) is available
⚠️  Port 443 (HTTPS) is in use by: nginx
🔧 Finding alternative HTTPS port...
✅ Using port 8443 for HTTPS

📋 Port Configuration Summary:
   🔍 DNS Server:     Port 53 (TCP/UDP)
   🌐 Web Interface:  Port 80 (HTTP)
   🔒 Secure Web:     Port 8443 (HTTPS)

🌐 Admin Interface: http://192.168.1.10:80/admin
🔒 Secure Interface: https://192.168.1.10:8443/admin
```

## 🌐 Network Configuration

### Option 1: Configure Individual Devices
Set the DNS server on each device to your Mac mini's IP address (and port if not standard).

### Option 2: Configure Router (Recommended)
Set your router's DNS server to your Mac mini's IP address (and port if not standard). This will automatically apply Pi-hole to all devices on your network.

### Finding Your Mac mini's IP Address
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

### Custom Port Configuration
If Pi-hole is using non-standard ports, you'll need to specify them when configuring DNS:
- **Standard ports**: Use just the IP address (e.g., `192.168.1.10`)
- **Custom ports**: Include the port (e.g., `192.168.1.10:5353`)

## 🔐 Security

- **Change the default password** in the `.env` file
- **Use HTTPS** by accessing `https://YOUR_MAC_IP/admin` (if configured)
- **Keep Pi-hole updated** regularly

## 📊 Accessing Pi-hole

- **Web Interface**: `http://YOUR_MAC_IP:HTTP_PORT/admin` (e.g., `http://192.168.1.10:8080/admin`)
- **Secure Interface**: `https://YOUR_MAC_IP:HTTPS_PORT/admin` (e.g., `https://192.168.1.10:8443/admin`)
- **Local Domain**: `http://pihole.local/admin` (add to `/etc/hosts` if desired)
- **Default Password**: `change-me` (change this!)

> **Note**: If using standard ports (80/443), you can omit the port number from the URL.

## 🛠️ Troubleshooting

### Container Won't Start
1. **Use automatic port resolution** (Recommended):
   ```bash
   ./resolve-ports.sh
   ```

2. **Or manually check port conflicts**:
   ```bash
   lsof -i :53
   lsof -i :80
   lsof -i :443
   ```

3. **Stop conflicting services** or let the system find alternative ports automatically

### DNS Not Working
1. Verify your Mac mini's IP address in the `.env` file
2. Check that devices are using the correct DNS server (including port if not standard)
3. Restart the Pi-hole container:
   ```bash
   docker-compose restart
   ```

### Can't Access Web Interface
1. Check if the container is running:
   ```bash
   docker-compose ps
   ```
2. Verify the IP address and port in the `.env` file
3. Check current port configuration:
   ```bash
   ./pihole-manager.sh  # Choose option 13
   ```
4. Check firewall settings on your Mac

## 📁 File Structure

```
pihole-docker/
├── start-pihole.sh          # 🎯 Main launcher (start here!)
├── first-time-setup.sh      # 🧙‍♂️ Interactive setup wizard
├── pihole-manager.sh        # 🔧 Advanced management interface
├── network-setup.sh         # 🌐 Network configuration helper
├── status.sh               # 📊 Status dashboard
├── resolve-ports.sh        # 🔧 Automatic port conflict resolution
├── version.sh              # 📋 Version management and changelog
├── version-check.sh        # 📋 Version checking utilities
├── setup.sh                # ⚙️ Original automated setup script
├── test.sh                 # 🧪 Test script
├── docker-compose.yml      # Docker Compose configuration
├── .env                    # Environment variables
├── VERSION                 # Version file
├── CHANGELOG.md            # Changelog and release notes
├── .gitignore             # Git ignore file
├── README.md              # This file
├── etc-pihole/            # Pi-hole configuration (created automatically)
└── etc-dnsmasq.d/         # DNS configuration (created automatically)
```

## 🔄 Backup and Restore

### Backup Pi-hole Configuration
```bash
# Copy the configuration directories
cp -r etc-pihole/ backup-etc-pihole/
cp -r etc-dnsmasq.d/ backup-etc-dnsmasq.d/
```

### Restore Pi-hole Configuration
```bash
# Restore from backup
cp -r backup-etc-pihole/ etc-pihole/
cp -r backup-etc-dnsmasq.d/ etc-dnsmasq.d/
docker-compose up -d
```

## 📈 Monitoring

- **Query Log**: Available in the Pi-hole web interface
- **Statistics**: Real-time stats in the admin panel
- **Block Lists**: Manage and update block lists through the web interface

## 📋 Version Management

This project includes a comprehensive version management system to track development and releases.

### Current Version
- **Version**: 1.0.0
- **Release Date**: 2024-12-19
- **Features**: Initial release with port conflict resolution

### Version Commands
```bash
# Show current version information
./version.sh show

# Show changelog and recent changes
./version.sh changelog

# Update to new version (for developers)
./version.sh update 1.0.1

# Show help
./version.sh help
```

### Version Information in Scripts
All scripts include version information in their headers and can be accessed through the Pi-hole Manager (Option 14).

### Changelog
See [CHANGELOG.md](CHANGELOG.md) for detailed release notes and development history.

## 🆘 Support

- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [Pi-hole GitHub](https://github.com/pi-hole/pi-hole)
- [Docker Documentation](https://docs.docker.com/)

## 📝 License

This project is provided as-is for educational and personal use. Pi-hole itself is licensed under the EUPL-1.2.
