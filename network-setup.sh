#!/bin/bash

# Pi-hole Network Setup Helper
# This script helps configure your network to use Pi-hole
# Version: 1.0.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_step() {
    echo -e "${CYAN}🔧 $1${NC}"
}

# Function to get Pi-hole IP
get_pihole_ip() {
    if [ -f ".env" ]; then
        grep "SERVER_IP=" .env | cut -d'=' -f2
    else
        echo "unknown"
    fi
}

# Function to check if Pi-hole is running
check_pihole_running() {
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    elif docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        return 1
    fi
    
    $COMPOSE_CMD ps | grep -q "Up"
}

# Function to test DNS resolution
test_dns() {
    local dns_server="$1"
    local test_domain="google.com"
    
    if nslookup $test_domain $dns_server > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to get current DNS servers
get_current_dns() {
    if command -v scutil &> /dev/null; then
        scutil --dns | grep nameserver | head -2 | awk '{print $3}'
    else
        echo "Could not detect current DNS servers"
    fi
}

# Function to show network info
show_network_info() {
    local pihole_ip=$(get_pihole_ip)
    
    clear
    print_header "📊 Network Configuration Information"
    print_header "===================================="
    echo ""
    
    print_info "Pi-hole Information:"
    echo "   IP Address: $pihole_ip"
    echo "   Status: $(if check_pihole_running; then echo "Running"; else echo "Stopped"; fi)"
    echo ""
    
    print_info "Current DNS Configuration:"
    get_current_dns | while read dns; do
        echo "   $dns"
    done
    echo ""
    
    print_info "Network Interfaces:"
    ifconfig | grep -A 1 "inet " | grep -v "127.0.0.1" | while read line; do
        if [[ $line == *"inet "* ]]; then
            echo "   $line"
        fi
    done
    echo ""
}

# Function to configure macOS DNS
configure_macos_dns() {
    local pihole_ip=$(get_pihole_ip)
    
    if [ "$pihole_ip" = "unknown" ]; then
        print_error "Could not determine Pi-hole IP address"
        return 1
    fi
    
    print_step "Configuring macOS DNS settings..."
    echo ""
    print_info "To configure DNS on macOS:"
    echo ""
    echo "1. Open System Preferences"
    echo "2. Go to Network"
    echo "3. Select your active connection (Wi-Fi or Ethernet)"
    echo "4. Click 'Advanced...'"
    echo "5. Go to the 'DNS' tab"
    echo "6. Click the '+' button"
    echo "7. Add: $pihole_ip"
    echo "8. Click 'OK' and 'Apply'"
    echo ""
    print_info "Alternative method using Terminal:"
    echo "sudo networksetup -setdnsservers Wi-Fi $pihole_ip"
    echo "sudo networksetup -setdnsservers Ethernet $pihole_ip"
    echo ""
    
    read -p "Would you like to apply DNS settings automatically? (y/N): " auto_apply
    
    if [[ $auto_apply =~ ^[Yy]$ ]]; then
        print_info "Applying DNS settings..."
        
        # Try to set DNS for Wi-Fi
        if sudo networksetup -setdnsservers Wi-Fi $pihole_ip 2>/dev/null; then
            print_status "Wi-Fi DNS configured"
        else
            print_warning "Could not configure Wi-Fi DNS (may not be available)"
        fi
        
        # Try to set DNS for Ethernet
        if sudo networksetup -setdnsservers Ethernet $pihole_ip 2>/dev/null; then
            print_status "Ethernet DNS configured"
        else
            print_warning "Could not configure Ethernet DNS (may not be available)"
        fi
        
        print_status "DNS configuration complete!"
    fi
}

# Function to test Pi-hole connectivity
test_connectivity() {
    local pihole_ip=$(get_pihole_ip)
    
    if [ "$pihole_ip" = "unknown" ]; then
        print_error "Could not determine Pi-hole IP address"
        return 1
    fi
    
    print_step "Testing Pi-hole connectivity..."
    echo ""
    
    # Test web interface
    print_info "Testing web interface..."
    if curl -s "http://$pihole_ip/admin" > /dev/null; then
        print_status "Web interface is accessible"
    else
        print_warning "Web interface is not accessible"
    fi
    
    # Test DNS resolution
    print_info "Testing DNS resolution..."
    if test_dns "$pihole_ip"; then
        print_status "DNS resolution is working"
    else
        print_warning "DNS resolution is not working"
    fi
    
    # Test if Pi-hole is blocking ads
    print_info "Testing ad blocking..."
    if nslookup "doubleclick.net" "$pihole_ip" 2>&1 | grep -q "0.0.0.0"; then
        print_status "Ad blocking is working"
    else
        print_warning "Ad blocking may not be working properly"
    fi
    
    echo ""
}

# Function to show router configuration help
show_router_help() {
    local pihole_ip=$(get_pihole_ip)
    
    clear
    print_header "🏠 Router Configuration Help"
    print_header "============================"
    echo ""
    print_info "Your Pi-hole IP address: $pihole_ip"
    echo ""
    print_info "Configuring your router to use Pi-hole:"
    echo ""
    echo "1. Open your router's admin interface:"
    echo "   • Usually: http://192.168.1.1 or http://192.168.0.1"
    echo "   • Check your router's label for the correct address"
    echo ""
    echo "2. Log in with your router credentials"
    echo ""
    echo "3. Look for DNS settings in:"
    echo "   • Internet/WAN settings"
    echo "   • DHCP settings"
    echo "   • DNS settings"
    echo ""
    echo "4. Set DNS servers to: $pihole_ip"
    echo ""
    echo "5. Save and restart your router"
    echo ""
    print_info "Common router brands and where to find DNS settings:"
    echo "   • Netgear: Advanced > Setup > WAN Setup"
    echo "   • Linksys: Smart Wi-Fi Tools > Internet Settings"
    echo "   • ASUS: LAN > DHCP Server"
    echo "   • TP-Link: Advanced > Network > DHCP Server"
    echo "   • Apple: Internet > DNS Servers"
    echo ""
    print_info "Benefits of router configuration:"
    echo "   • All devices automatically use Pi-hole"
    echo "   • No need to configure each device individually"
    echo "   • Works with devices that can't change DNS settings"
    echo ""
    read -p "Press Enter to continue..."
}

# Function to show device-specific instructions
show_device_instructions() {
    local pihole_ip=$(get_pihole_ip)
    
    clear
    print_header "📱 Device Configuration Instructions"
    print_header "===================================="
    echo ""
    print_info "Pi-hole IP address: $pihole_ip"
    echo ""
    
    echo "🍎 macOS:"
    echo "   System Preferences > Network > Advanced > DNS"
    echo "   Add: $pihole_ip"
    echo ""
    
    echo "📱 iOS:"
    echo "   Settings > Wi-Fi > (i) next to network > Configure DNS > Manual"
    echo "   Add: $pihole_ip"
    echo ""
    
    echo "🤖 Android:"
    echo "   Settings > Wi-Fi > Long press network > Modify > Advanced > DNS"
    echo "   Add: $pihole_ip"
    echo ""
    
    echo "🪟 Windows:"
    echo "   Control Panel > Network and Internet > Network Connections"
    echo "   Right-click connection > Properties > Internet Protocol Version 4 > Properties"
    echo "   Use the following DNS server addresses: $pihole_ip"
    echo ""
    
    echo "🐧 Linux:"
    echo "   Edit /etc/resolv.conf or use NetworkManager"
    echo "   Add: nameserver $pihole_ip"
    echo ""
    
    echo "📺 Smart TV/Game Console:"
    echo "   Look for Network/DNS settings in device settings"
    echo "   Set DNS to: $pihole_ip"
    echo ""
    
    read -p "Press Enter to continue..."
}

# Function to show main menu
show_menu() {
    local pihole_ip=$(get_pihole_ip)
    
    clear
    print_header "🌐 Pi-hole Network Setup Helper"
    print_header "==============================="
    echo ""
    print_info "Pi-hole IP: $pihole_ip"
    print_info "Status: $(if check_pihole_running; then echo "Running"; else echo "Stopped"; fi)"
    echo ""
    echo "What would you like to do?"
    echo ""
    echo "1) 📊 Show network information"
    echo "2) 🍎 Configure macOS DNS settings"
    echo "3) 🧪 Test Pi-hole connectivity"
    echo "4) 🏠 Router configuration help"
    echo "5) 📱 Device-specific instructions"
    echo "6) 🔍 Check current DNS settings"
    echo "7) 📋 Generate configuration summary"
    echo "0) ❌ Exit"
    echo ""
}

# Function to check current DNS settings
check_dns_settings() {
    print_step "Current DNS Settings"
    echo ""
    
    print_info "System DNS servers:"
    get_current_dns | while read dns; do
        echo "   $dns"
    done
    echo ""
    
    print_info "Testing DNS resolution:"
    if test_dns "$(get_current_dns | head -1)"; then
        print_status "Primary DNS is working"
    else
        print_warning "Primary DNS is not responding"
    fi
    echo ""
}

# Function to generate configuration summary
generate_summary() {
    local pihole_ip=$(get_pihole_ip)
    
    clear
    print_header "📋 Pi-hole Configuration Summary"
    print_header "================================"
    echo ""
    print_info "Pi-hole Details:"
    echo "   IP Address: $pihole_ip"
    echo "   Status: $(if check_pihole_running; then echo "Running"; else echo "Stopped"; fi)"
    echo "   Web Interface: http://$pihole_ip/admin"
    echo ""
    
    print_info "Network Configuration:"
    echo "   To use Pi-hole, set DNS server to: $pihole_ip"
    echo ""
    
    print_info "Current System DNS:"
    get_current_dns | while read dns; do
        echo "   $dns"
    done
    echo ""
    
    print_info "Quick Commands:"
    echo "   Test DNS: nslookup google.com $pihole_ip"
    echo "   Test web: curl http://$pihole_ip/admin"
    echo "   Check status: docker-compose ps"
    echo ""
    
    read -p "Press Enter to continue..."
}

# Main menu loop
while true; do
    show_menu
    read -p "Enter your choice (0-7): " choice
    
    case $choice in
        1) show_network_info ;;
        2) configure_macos_dns ;;
        3) test_connectivity ;;
        4) show_router_help ;;
        5) show_device_instructions ;;
        6) check_dns_settings ;;
        7) generate_summary ;;
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
