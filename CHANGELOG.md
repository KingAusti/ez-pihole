# Changelog

All notable changes to the Pi-hole Docker project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- MIT LICENSE file
- GitHub Actions workflow running shellcheck and `docker compose config`

### Changed
- README rewritten; license badge changed from EUPL-1.2 to MIT

### Removed
- GETTING-STARTED.md, which duplicated the README

## [1.0.0] - 2024-12-19

### Added
- 🎉 Initial release of Pi-hole Docker setup for Mac mini
- 🎯 User-friendly setup scripts with guided installation
- 🔧 Automatic port conflict resolution system
- 📊 Advanced management interface with menu options
- 🌐 Network configuration helpers with device-specific instructions
- 📈 Status monitoring and troubleshooting tools
- 🐳 Docker Compose integration optimized for Mac mini
- 🔐 Security best practices and configuration
- 📋 Comprehensive documentation and README
- 🔄 Backup and restore functionality
- 📝 Version management system
- 🏷️ Git tagging support for releases

### Features
- **start-pihole.sh**: Main launcher with automatic setup detection
- **first-time-setup.sh**: Interactive setup wizard with step-by-step guidance
- **pihole-manager.sh**: Advanced management interface with 14 menu options
- **resolve-ports.sh**: Automatic port conflict resolution system
- **network-setup.sh**: Network configuration helper
- **status.sh**: Status dashboard and monitoring tools
- **version.sh**: Version management and changelog system

### Port Conflict Resolution
- Automatic detection of port conflicts on ports 53, 80, and 443
- Smart alternative port selection with common fallbacks
- Automatic Docker Compose configuration updates
- Environment file updates with port information
- Clear user feedback and configuration summaries
- Backup creation before modifying files

### Configuration
- Environment file (.env) with auto-detected settings
- Persistent storage for Pi-hole configuration and logs
- Dark theme enabled by default
- Cloudflare DNS as upstream DNS servers
- Customizable DNS servers and timezone settings

### Documentation
- Comprehensive README with setup instructions
- Troubleshooting guides and common solutions
- Network configuration examples
- Security best practices
- File structure documentation

### Technical Details
- Docker Compose version 3.8
- Pi-hole latest image with persistent volumes
- Network bridge configuration
- Port mapping with conflict resolution
- Restart policy: unless-stopped
- Capability: NET_ADMIN for DNS functionality

---

## Development Notes

### Version Management
- Use `./version.sh update <version>` to update version numbers
- Version format follows semantic versioning (MAJOR.MINOR.PATCH)
- Git tags are automatically created for each version
- All scripts include version information in headers

### Future Enhancements
- [ ] Web-based management interface
- [ ] Automated backup scheduling
- [ ] Health monitoring and alerts
- [ ] Multi-network support
- [ ] Advanced logging and analytics
- [ ] Integration with home automation systems

### Contributing
- Follow semantic versioning for releases
- Update CHANGELOG.md for all changes
- Test all scripts before committing
- Maintain backward compatibility when possible
- Document new features in README.md
