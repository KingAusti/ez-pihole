#!/bin/bash

# Version Management Script for Pi-hole Docker
# This script handles version information and updates

# set -e  # Disabled to handle git commands gracefully

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_header() {
    echo -e "${PURPLE}$1${NC}"
}

print_step() {
    echo -e "${CYAN}🔧 $1${NC}"
}

# Function to get current version
get_version() {
    if [ -f "VERSION" ]; then
        cat VERSION
    else
        echo "unknown"
    fi
}

# Function to show version information
show_version() {
    # shellcheck disable=SC2155  # declare-and-assign kept; splitting would change behaviour under set -e
    local version=$(get_version)
    local git_hash=""
    local git_branch=""
    
    # Get git information if available
    if command -v git &> /dev/null && [ -d ".git" ]; then
        git_hash=$(git rev-parse --short HEAD 2>/dev/null || echo "")
        git_branch=$(git branch --show-current 2>/dev/null || echo "")
    fi
    
    clear
    print_header "📋 Pi-hole Docker Version Information"
    print_header "====================================="
    echo ""
    print_info "Project Version: $version"
    
    if [ -n "$git_hash" ]; then
        print_info "Git Commit: $git_hash"
    fi
    
    if [ -n "$git_branch" ]; then
        print_info "Git Branch: $git_branch"
    fi
    
    echo ""
    print_info "Features in this version:"
    echo "   🎯 User-friendly setup scripts"
    echo "   🔧 Automatic port conflict resolution"
    echo "   📊 Advanced management interface"
    echo "   🌐 Network configuration helpers"
    echo "   📈 Status monitoring and troubleshooting"
    echo "   🐳 Docker Compose integration"
    echo "   🔐 Security best practices"
    echo ""
    
    print_info "Script versions:"
    if [ -f "start-pihole.sh" ]; then
        echo "   🚀 start-pihole.sh: $version"
    fi
    if [ -f "first-time-setup.sh" ]; then
        echo "   🧙‍♂️ first-time-setup.sh: $version"
    fi
    if [ -f "pihole-manager.sh" ]; then
        echo "   🔧 pihole-manager.sh: $version"
    fi
    if [ -f "resolve-ports.sh" ]; then
        echo "   🔧 resolve-ports.sh: $version"
    fi
    if [ -f "network-setup.sh" ]; then
        echo "   🌐 network-setup.sh: $version"
    fi
    if [ -f "status.sh" ]; then
        echo "   📊 status.sh: $version"
    fi
    
    echo ""
    read -p "Press Enter to return to main menu..."
}

# Function to update version
update_version() {
    local new_version="$1"
    
    if [ -z "$new_version" ]; then
        print_error "Please provide a version number (e.g., 1.0.1)"
        return 1
    fi
    
    # Validate version format (basic check)
    if [[ ! $new_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_error "Invalid version format. Use semantic versioning (e.g., 1.0.1)"
        return 1
    fi
    
    # shellcheck disable=SC2155  # declare-and-assign kept; splitting would change behaviour under set -e
    local current_version=$(get_version)
    
    print_step "Updating version from $current_version to $new_version"
    
    # Update VERSION file
    echo "$new_version" > VERSION
    print_status "VERSION file updated"
    
    # Update version in scripts (if they have version comments)
    local scripts=("start-pihole.sh" "first-time-setup.sh" "pihole-manager.sh" "resolve-ports.sh" "network-setup.sh" "status.sh")
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            # Update version comment if it exists
            if grep -q "# Version:" "$script"; then
                sed -i.bak "s/# Version:.*/# Version: $new_version/" "$script"
                rm -f "$script.bak"
                print_status "Updated version in $script"
            fi
        fi
    done
    
    # Create git tag if in git repository
    if command -v git &> /dev/null && [ -d ".git" ]; then
        print_info "Creating git tag v$new_version"
        if git tag -a "v$new_version" -m "Version $new_version" 2>/dev/null; then
            print_status "Git tag created: v$new_version"
        else
            print_warning "Could not create git tag (may already exist)"
        fi
    fi
    
    print_status "Version updated to $new_version"
}

# Function to show changelog
show_changelog() {
    clear
    print_header "📝 Changelog"
    print_header "============"
    echo ""
    
    print_info "Version 1.0.0 (Current)"
    echo "   🎉 Initial release"
    echo "   🎯 User-friendly setup scripts"
    echo "   🔧 Automatic port conflict resolution"
    echo "   📊 Advanced management interface"
    echo "   🌐 Network configuration helpers"
    echo "   📈 Status monitoring and troubleshooting"
    echo "   🐳 Docker Compose integration"
    echo "   🔐 Security best practices"
    echo "   📋 Comprehensive documentation"
    echo ""
    
    if command -v git &> /dev/null && [ -d ".git" ]; then
        print_info "Recent commits:"
        git log --oneline -10 2>/dev/null | head -10 || echo "   No git history available"
    fi
    
    echo ""
    read -p "Press Enter to return to main menu..."
}

# Function to show help
show_help() {
    echo "Pi-hole Docker Version Management"
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  show                    Show current version information"
    echo "  update <version>        Update to new version (e.g., 1.0.1)"
    echo "  changelog               Show changelog and recent changes"
    echo "  help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 show                 # Show current version"
    echo "  $0 update 1.0.1         # Update to version 1.0.1"
    echo "  $0 changelog            # Show changelog"
}

# Main function
main() {
    local command="$1"
    local argument="$2"
    
    case "$command" in
        "show"|"")
            show_version
            ;;
        "update")
            update_version "$argument"
            ;;
        "changelog")
            show_changelog
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    main "$@"
fi
