#!/bin/bash

# Version Check Function for Pi-hole Docker
# This script provides version checking functionality for other scripts

# Function to get current version
get_version() {
    if [ -f "VERSION" ]; then
        cat VERSION
    else
        echo "unknown"
    fi
}

# Function to show version banner
show_version_banner() {
    local version=$(get_version)
    echo "Pi-hole Docker v$version - Mac mini Setup"
}

# Function to check if version file exists
check_version_file() {
    if [ ! -f "VERSION" ]; then
        echo "Warning: VERSION file not found"
        return 1
    fi
    return 0
}

# Function to get version from script header
get_script_version() {
    local script="$1"
    if [ -f "$script" ]; then
        grep "# Version:" "$script" | head -1 | sed 's/.*Version: *//' | tr -d ' '
    else
        echo "unknown"
    fi
}

# Main function for direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-show}" in
        "show")
            show_version_banner
            ;;
        "get")
            get_version
            ;;
        "check")
            check_version_file
            ;;
        "script")
            get_script_version "$2"
            ;;
        *)
            echo "Usage: $0 [show|get|check|script <filename>]"
            ;;
    esac
fi
