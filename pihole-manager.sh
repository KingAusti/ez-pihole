#!/bin/bash

# Pi-hole Manager - Easy Pi-hole Management Script
# This script provides a simple menu to manage your Pi-hole Docker container
# Version: 1.0.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
# shellcheck disable=SC2034  # colour constant kept for parity with other scripts
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Set up Docker Compose command
if command_exists docker-compose; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    print_error "Docker Compose is not available!"
    exit 1
fi

# Function to get Pi-hole status
get_pihole_status() {
    if $COMPOSE_CMD ps | grep -q "Up"; then
        echo "running"
    else
        echo "stopped"
    fi
}

# Function to get Pi-hole IP
get_pihole_ip() {
    if [ -f ".env" ]; then
        grep "SERVER_IP=" .env | cut -d'=' -f2
    else
        echo "unknown"
    fi
}

# Function to show main menu
show_menu() {
    local status=$(get_pihole_status)
    local ip=$(get_pihole_ip)
    
    clear
    print_header "🔧 Pi-hole Manager"
    print_header "=================="
    echo ""
    print_info "Status: $status"
    print_info "IP Address: $ip"
    echo ""
    echo "What would you like to do?"
    echo ""
    echo "1) 🚀 Start Pi-hole"
    echo "2) ⏹️  Stop Pi-hole"
    echo "3) 🔄 Restart Pi-hole"
    echo "4) 📊 View Pi-hole logs"
    echo "5) 🌐 Open Pi-hole admin interface"
    echo "6) 📈 Show Pi-hole statistics"
    echo "7) 🔧 Update Pi-hole"
    echo "8) ⚙️  Edit configuration"
    echo "9) 🧪 Test Pi-hole"
    echo "10) 📋 Show network configuration help"
    echo "11) 🆘 Troubleshooting"
    echo "12) 🔧 Resolve port conflicts"
    echo "13) 📋 Show current port configuration"
    echo "14) 📋 Show version information"
    echo "0) ❌ Exit"
    echo ""
}

# Function to start Pi-hole
start_pihole() {
    print_info "Starting Pi-hole..."
    $COMPOSE_CMD up -d
    sleep 3
    
    if $COMPOSE_CMD ps | grep -q "Up"; then
        print_status "Pi-hole started successfully!"
        local ip=$(get_pihole_ip)
        print_info "Access at: http://$ip/admin"
    else
        print_error "Failed to start Pi-hole"
        print_info "Check logs with: $COMPOSE_CMD logs pihole"
    fi
}

# Function to stop Pi-hole
stop_pihole() {
    print_info "Stopping Pi-hole..."
    $COMPOSE_CMD down
    print_status "Pi-hole stopped"
}

# Function to restart Pi-hole
restart_pihole() {
    print_info "Restarting Pi-hole..."
    $COMPOSE_CMD restart
    sleep 3
    
    if $COMPOSE_CMD ps | grep -q "Up"; then
        print_status "Pi-hole restarted successfully!"
    else
        print_error "Failed to restart Pi-hole"
    fi
}

# Function to show logs
show_logs() {
    print_info "Showing Pi-hole logs (Press Ctrl+C to exit)..."
    echo ""
    $COMPOSE_CMD logs -f pihole
}

# Function to open admin interface
open_admin() {
    local ip=$(get_pihole_ip)
    if [ "$ip" != "unknown" ]; then
        # Get HTTP port from .env file
        local http_port=$(grep "HTTP_PORT=" .env 2>/dev/null | cut -d'=' -f2)
        if [ -n "$http_port" ] && [ "$http_port" != "80" ]; then
            print_info "Opening Pi-hole admin interface..."
            open "http://$ip:$http_port/admin"
        else
            print_info "Opening Pi-hole admin interface..."
            open "http://$ip/admin"
        fi
    else
        print_error "Could not determine Pi-hole IP address"
    fi
}

# Function to show statistics
show_stats() {
    local ip=$(get_pihole_ip)
    if [ "$ip" != "unknown" ]; then
        print_info "Pi-hole Statistics:"
        echo ""
        print_info "Admin Interface: http://$ip/admin"
        print_info "Status: $(get_pihole_status)"
        echo ""
        
        # Try to get some basic stats from the container
        if $COMPOSE_CMD ps | grep -q "Up"; then
            print_info "Container is running and healthy"
        else
            print_warning "Container is not running"
        fi
    else
        print_error "Could not determine Pi-hole IP address"
    fi
}

# Function to update Pi-hole
update_pihole() {
    print_info "Updating Pi-hole..."
    print_info "Pulling latest image..."
    $COMPOSE_CMD pull
    print_info "Restarting with new image..."
    $COMPOSE_CMD up -d
    print_status "Pi-hole updated successfully!"
}

# Function to edit configuration
edit_config() {
    if [ -f ".env" ]; then
        print_info "Opening configuration file for editing..."
        if command_exists code; then
            code .env
        elif command_exists nano; then
            nano .env
        elif command_exists vim; then
            vim .env
        else
            open -e .env
        fi
        echo ""
        print_info "After editing, restart Pi-hole to apply changes:"
        print_info "$COMPOSE_CMD up -d"
    else
        print_error "Configuration file (.env) not found"
        print_info "Create it with: cp .env.example .env"
    fi
}

# Function to test Pi-hole
test_pihole() {
    local ip=$(get_pihole_ip)
    if [ "$ip" != "unknown" ]; then
        print_info "Testing Pi-hole..."
        echo ""
        
        # Test if Pi-hole is responding
        if curl -s "http://$ip/admin" > /dev/null; then
            print_status "Pi-hole web interface is accessible"
        else
            print_warning "Pi-hole web interface is not accessible"
        fi
        
        # Test DNS resolution
        if nslookup google.com $ip > /dev/null 2>&1; then
            print_status "Pi-hole DNS is working"
        else
            print_warning "Pi-hole DNS is not responding"
        fi
    else
        print_error "Could not determine Pi-hole IP address"
    fi
}

# Function to show network configuration help
show_network_help() {
    local ip=$(get_pihole_ip)
    
    clear
    print_header "📋 Network Configuration Help"
    print_header "============================="
    echo ""
    print_info "Your Pi-hole IP address: $ip"
    echo ""
    print_info "To use Pi-hole on your network:"
    echo ""
    echo "🔧 Option 1: Configure Individual Devices"
    echo "   Set DNS server to: $ip"
    echo "   • macOS: System Preferences > Network > Advanced > DNS"
    echo "   • iOS: Settings > Wi-Fi > (i) > Configure DNS > Manual"
    echo "   • Android: Settings > Wi-Fi > Long press network > Modify > Advanced > DNS"
    echo ""
    echo "🏠 Option 2: Configure Router (Recommended)"
    echo "   Set router's DNS server to: $ip"
    echo "   This applies Pi-hole to all devices automatically"
    echo "   Check your router's admin interface for DNS settings"
    echo ""
    print_info "Test your setup:"
    echo "   Visit: http://$ip/admin"
    echo "   Check the Query Log to see if devices are using Pi-hole"
    echo ""
    read -p "Press Enter to return to main menu..."
}

# Function to show troubleshooting
show_troubleshooting() {
    clear
    print_header "🆘 Troubleshooting"
    print_header "=================="
    echo ""
    print_info "Common issues and solutions:"
    echo ""
    echo "❌ Pi-hole won't start:"
    echo "   • Check if Docker is running"
    echo "   • Check port conflicts: lsof -i :53, lsof -i :80"
    echo "   • View logs: $COMPOSE_CMD logs pihole"
    echo "   • Use port conflict resolution: Option 12"
    echo ""
    echo "❌ Can't access web interface:"
    echo "   • Check if container is running: $COMPOSE_CMD ps"
    echo "   • Verify IP address in .env file"
    echo "   • Check current port configuration: Option 13"
    echo "   • Try: http://localhost/admin"
    echo ""
    echo "❌ DNS not working:"
    echo "   • Verify devices are using correct DNS server"
    echo "   • Check Pi-hole logs for errors"
    echo "   • Restart Pi-hole: $COMPOSE_CMD restart"
    echo ""
    echo "❌ Ads still showing:"
    echo "   • Check if devices are using Pi-hole DNS"
    echo "   • Verify block lists are enabled"
    echo "   • Clear browser cache"
    echo ""
    print_info "Useful commands:"
    echo "   • View logs: $COMPOSE_CMD logs -f pihole"
    echo "   • Check status: $COMPOSE_CMD ps"
    echo "   • Restart: $COMPOSE_CMD restart"
    echo ""
    read -p "Press Enter to return to main menu..."
}

# Function to show current port configuration
show_port_config() {
    clear
    print_header "📋 Current Port Configuration"
    print_header "============================="
    echo ""
    
    if [ -f ".env" ]; then
        local dns_port=$(grep "DNS_PORT=" .env 2>/dev/null | cut -d'=' -f2)
        local http_port=$(grep "HTTP_PORT=" .env 2>/dev/null | cut -d'=' -f2)
        local https_port=$(grep "HTTPS_PORT=" .env 2>/dev/null | cut -d'=' -f2)
        local server_ip=$(grep "SERVER_IP=" .env 2>/dev/null | cut -d'=' -f2)
        
        if [ -n "$dns_port" ]; then
            print_info "Current port assignments:"
            echo "   🔍 DNS Server:     Port $dns_port"
            echo "   🌐 Web Interface:  Port $http_port"
            echo "   🔒 Secure Web:     Port $https_port"
            echo ""
            
            if [ -n "$server_ip" ]; then
                print_info "Access URLs:"
                echo "   🌐 Admin: http://$server_ip:$http_port/admin"
                echo "   🔒 Secure: https://$server_ip:$https_port/admin"
                echo ""
                print_info "Network Configuration:"
                if [ "$dns_port" = "53" ]; then
                    echo "   📱 DNS Server: $server_ip"
                else
                    echo "   📱 DNS Server: $server_ip:$dns_port"
                fi
            fi
        else
            print_info "Using default ports (53, 80, 443)"
            if [ -n "$server_ip" ]; then
                echo "   🌐 Admin: http://$server_ip/admin"
                echo "   🔒 Secure: https://$server_ip/admin"
                echo "   📱 DNS Server: $server_ip"
            fi
        fi
    else
        print_warning "No .env file found - using default ports"
    fi
    
    echo ""
    read -p "Press Enter to return to main menu..."
}

# Main menu loop
while true; do
    show_menu
    read -p "Enter your choice (0-14): " choice
    
    case $choice in
        1) start_pihole ;;
        2) stop_pihole ;;
        3) restart_pihole ;;
        4) show_logs ;;
        5) open_admin ;;
        6) show_stats ;;
        7) update_pihole ;;
        8) edit_config ;;
        9) test_pihole ;;
        10) show_network_help ;;
        11) show_troubleshooting ;;
        12) 
            if [ -f "./resolve-ports.sh" ]; then
                ./resolve-ports.sh
            else
                print_error "Port resolution script not found"
            fi
            ;;
        13) show_port_config ;;
        14) 
            if [ -f "./version.sh" ]; then
                ./version.sh show
            else
                print_error "Version script not found"
            fi
            ;;
        0) 
            print_info "Goodbye! 👋"
            exit 0
            ;;
        *)
            print_error "Invalid choice. Please try again."
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done
