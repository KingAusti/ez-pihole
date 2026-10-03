#!/bin/bash

# Pi-hole Status Dashboard
# This script shows a quick overview of Pi-hole status and statistics
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

print_metric() {
    echo -e "${CYAN}$1${NC}"
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

# Function to get Pi-hole IP
get_pihole_ip() {
    if [ -f ".env" ]; then
        grep "SERVER_IP=" .env | cut -d'=' -f2
    else
        echo "unknown"
    fi
}

# Function to check if Pi-hole is running
is_pihole_running() {
    $COMPOSE_CMD ps | grep -q "Up"
}

# Function to get container status
get_container_status() {
    if is_pihole_running; then
        echo "Running"
    else
        echo "Stopped"
    fi
}

# Function to get container uptime
get_uptime() {
    if is_pihole_running; then
        $COMPOSE_CMD ps --format "table {{.Status}}" | grep -v "STATUS" | head -1
    else
        echo "N/A"
    fi
}

# Function to test web interface
test_web_interface() {
    local ip="$1"
    if curl -s --max-time 5 "http://$ip/admin" > /dev/null; then
        echo "Accessible"
    else
        echo "Not accessible"
    fi
}

# Function to test DNS resolution
test_dns_resolution() {
    local ip="$1"
    if nslookup google.com "$ip" > /dev/null 2>&1; then
        echo "Working"
    else
        echo "Not working"
    fi
}

# Function to get Pi-hole version
get_pihole_version() {
    if is_pihole_running; then
        docker exec pihole pihole version 2>/dev/null | head -1 | awk '{print $2}' || echo "Unknown"
    else
        echo "N/A"
    fi
}

# Function to get basic statistics
get_basic_stats() {
    local ip="$1"
    
    if is_pihole_running; then
        # Try to get stats from Pi-hole API
        # shellcheck disable=SC2155  # declare-and-assign kept; splitting would change behaviour under set -e
        local stats=$(curl -s --max-time 5 "http://$ip/admin/api.php?summary" 2>/dev/null)
        
        if [ -n "$stats" ]; then
            echo "$stats" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(f\"Queries today: {data.get('dns_queries_today', 'N/A')}\")
    print(f\"Ads blocked: {data.get('ads_blocked_today', 'N/A')}\")
    print(f\"Block percentage: {data.get('ads_percentage_today', 'N/A')}%\")
except:
    print('Stats unavailable')
" 2>/dev/null || echo "Stats unavailable"
        else
            echo "Stats unavailable"
        fi
    else
        echo "Container not running"
    fi
}

# Function to show quick actions
show_quick_actions() {
    local ip="$1"
    
    echo ""
    print_header "🚀 Quick Actions"
    print_header "================"
    echo ""
    echo "1) Open admin interface: open http://$ip/admin"
    echo "2) View logs: $COMPOSE_CMD logs -f pihole"
    echo "3) Restart Pi-hole: $COMPOSE_CMD restart"
    echo "4) Stop Pi-hole: $COMPOSE_CMD down"
    echo "5) Start Pi-hole: $COMPOSE_CMD up -d"
    echo ""
}

# Main status display
show_status() {
    # shellcheck disable=SC2155  # declare-and-assign kept; splitting would change behaviour under set -e
    local pihole_ip=$(get_pihole_ip)
    # shellcheck disable=SC2155  # declare-and-assign kept; splitting would change behaviour under set -e
    local container_status=$(get_container_status)
    # shellcheck disable=SC2155  # declare-and-assign kept; splitting would change behaviour under set -e
    local uptime=$(get_uptime)
    # shellcheck disable=SC2155  # declare-and-assign kept; splitting would change behaviour under set -e
    local web_status=$(test_web_interface "$pihole_ip")
    # shellcheck disable=SC2155  # declare-and-assign kept; splitting would change behaviour under set -e
    local dns_status=$(test_dns_resolution "$pihole_ip")
    # shellcheck disable=SC2155  # declare-and-assign kept; splitting would change behaviour under set -e
    local version=$(get_pihole_version)
    
    clear
    print_header "📊 Pi-hole Status Dashboard"
    print_header "==========================="
    echo ""
    
    # Basic Information
    print_info "Basic Information:"
    echo "   IP Address: $pihole_ip"
    echo "   Status: $container_status"
    echo "   Uptime: $uptime"
    echo "   Version: $version"
    echo ""
    
    # Service Status
    print_info "Service Status:"
    if [ "$web_status" = "Accessible" ]; then
        print_status "Web Interface: $web_status"
    else
        print_warning "Web Interface: $web_status"
    fi
    
    if [ "$dns_status" = "Working" ]; then
        print_status "DNS Resolution: $dns_status"
    else
        print_warning "DNS Resolution: $dns_status"
    fi
    echo ""
    
    # Statistics
    print_info "Today's Statistics:"
    get_basic_stats "$pihole_ip" | while read line; do
        echo "   $line"
    done
    echo ""
    
    # Network Information
    print_info "Network Information:"
    echo "   Admin Interface: http://$pihole_ip/admin"
    echo "   DNS Server: $pihole_ip"
    echo ""
    
    # Quick Actions
    show_quick_actions "$pihole_ip"
}

# Function to show continuous monitoring
monitor_mode() {
    # shellcheck disable=SC2155  # declare-and-assign kept; splitting would change behaviour under set -e
    local pihole_ip=$(get_pihole_ip)
    
    print_info "Starting continuous monitoring (Press Ctrl+C to exit)..."
    echo ""
    
    while true; do
        clear
        print_header "📊 Pi-hole Live Monitor"
        print_header "======================="
        echo ""
        
        # shellcheck disable=SC2155  # declare-and-assign kept; splitting would change behaviour under set -e
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        print_info "Last updated: $timestamp"
        echo ""
        
        # Show basic status
        # shellcheck disable=SC2155  # declare-and-assign kept; splitting would change behaviour under set -e
        local container_status=$(get_container_status)
        # shellcheck disable=SC2155  # declare-and-assign kept; splitting would change behaviour under set -e
        local web_status=$(test_web_interface "$pihole_ip")
        # shellcheck disable=SC2155  # declare-and-assign kept; splitting would change behaviour under set -e
        local dns_status=$(test_dns_resolution "$pihole_ip")
        
        echo "Status: $container_status | Web: $web_status | DNS: $dns_status"
        echo ""
        
        # Show recent logs
        print_info "Recent Activity:"
        $COMPOSE_CMD logs --tail=10 pihole 2>/dev/null | tail -5 | while read line; do
            echo "   $line"
        done
        echo ""
        
        sleep 5
    done
}

# Function to show help
show_help() {
    echo "Pi-hole Status Dashboard"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  -m, --monitor    Show continuous monitoring"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Without options, shows current status and exits."
}

# Main script logic
case "${1:-}" in
    -m|--monitor)
        monitor_mode
        ;;
    -h|--help)
        show_help
        ;;
    "")
        show_status
        ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
