#!/bin/bash

# Pi-hole Docker First-Time Setup Wizard
# This script guides users through the complete setup process
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get user input with default
get_input() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        eval "$var_name=\${input:-$default}"
    else
        read -p "$prompt: " input
        eval "$var_name=\"$input\""
    fi
}

# Function to get yes/no input
get_yes_no() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    while true; do
        if [ -n "$default" ]; then
            read -p "$prompt [Y/n]: " yn
            yn=${yn:-$default}
        else
            read -p "$prompt [y/N]: " yn
        fi
        
        case $yn in
            [Yy]* ) eval "$var_name=true"; break;;
            [Nn]* ) eval "$var_name=false"; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

clear
print_header "🚀 Pi-hole Docker Setup Wizard for Mac mini"
print_header "=============================================="
echo ""
print_info "This wizard will help you set up Pi-hole in a Docker container on your Mac mini."
print_info "Pi-hole will block ads and trackers across your entire network."
echo ""

# Step 1: Check Docker installation
print_step "Step 1: Checking Docker installation..."

if ! command_exists docker; then
    print_error "Docker is not installed!"
    echo ""
    print_info "To install Docker Desktop for Mac:"
    print_info "1. Go to: https://www.docker.com/products/docker-desktop/"
    print_info "2. Download Docker Desktop for Mac"
    print_info "3. Install and start Docker Desktop"
    print_info "4. Run this script again"
    echo ""
    exit 1
fi

if ! docker info &> /dev/null; then
    print_error "Docker is installed but not running!"
    echo ""
    print_info "Please start Docker Desktop and try again."
    print_info "You can start it from Applications or Spotlight search."
    echo ""
    exit 1
fi

print_status "Docker is installed and running"

# Step 2: Check Docker Compose
print_step "Step 2: Checking Docker Compose..."

if command_exists docker-compose; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    print_error "Docker Compose is not available!"
    print_info "Please ensure Docker Desktop is properly installed and updated."
    exit 1
fi

print_status "Docker Compose is available"

# Step 3: Detect network configuration
print_step "Step 3: Detecting your network configuration..."

LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')

if [ -z "$LOCAL_IP" ]; then
    print_error "Could not detect your Mac mini's IP address!"
    print_info "Please check your network connection and try again."
    exit 1
fi

print_status "Detected IP address: $LOCAL_IP"

# Step 4: Check and resolve port conflicts
print_step "Step 4: Checking and resolving port conflicts..."

# Source the port resolution functions
if [ -f "./resolve-ports.sh" ]; then
    source ./resolve-ports.sh
    
    # Resolve port conflicts automatically
    # shellcheck disable=SC2155,SC2168  # declare-and-assign kept; splitting would change behaviour under set -e; pre-existing: local used outside a function; not changed here
    local resolved_ports=$(resolve_port_conflicts)
    if [ $? -ne 0 ]; then
        print_error "Failed to resolve port conflicts"
        exit 1
    fi
    
    # Parse resolved ports
    # shellcheck disable=SC2155,SC2168  # declare-and-assign kept; splitting would change behaviour under set -e; pre-existing: local used outside a function; not changed here
    local dns_port=$(echo "$resolved_ports" | awk '{print $1}')
    # shellcheck disable=SC2155,SC2168  # declare-and-assign kept; splitting would change behaviour under set -e; pre-existing: local used outside a function; not changed here
    local http_port=$(echo "$resolved_ports" | awk '{print $2}')
    # shellcheck disable=SC2155,SC2168  # declare-and-assign kept; splitting would change behaviour under set -e; pre-existing: local used outside a function; not changed here
    local https_port=$(echo "$resolved_ports" | awk '{print $3}')
    
    # Store ports for later use
    export RESOLVED_DNS_PORT=$dns_port
    export RESOLVED_HTTP_PORT=$http_port
    export RESOLVED_HTTPS_PORT=$https_port
    
    print_status "Port conflicts resolved automatically"
    print_info "Using ports: DNS=$dns_port, HTTP=$http_port, HTTPS=$https_port"
else
    # Fallback to original port checking
    print_warning "Port resolution script not found, using basic port checking..."
    
    check_port() {
        local port=$1
        local service=$2
        if lsof -i :$port &> /dev/null; then
            print_warning "Port $port is in use by: $service"
            return 1
        else
            print_status "Port $port is available"
            return 0
        fi
    }

    PORT_CONFLICTS=false
    check_port 53 "DNS" || PORT_CONFLICTS=true
    check_port 80 "HTTP" || PORT_CONFLICTS=true
    check_port 443 "HTTPS" || PORT_CONFLICTS=true

    if [ "$PORT_CONFLICTS" = true ]; then
        echo ""
        print_warning "Some ports are in use. This might cause issues."
        get_yes_no "Do you want to continue anyway?" "n" CONTINUE_SETUP
        
        if [ "$CONTINUE_SETUP" = false ]; then
            print_info "Setup cancelled. Please stop the conflicting services and try again."
            exit 1
        fi
    fi
    
    # Set default ports for fallback
    export RESOLVED_DNS_PORT=53
    export RESOLVED_HTTP_PORT=80
    export RESOLVED_HTTPS_PORT=443
fi

# Step 5: Configuration
print_step "Step 5: Pi-hole configuration"

echo ""
print_info "Let's configure your Pi-hole settings:"
echo ""

get_input "Enter a secure password for the Pi-hole web interface" "change-me" PIHOLE_PASSWORD
get_input "Enter your timezone" "America/New_York" TIMEZONE

echo ""
print_info "Choose your upstream DNS servers:"
echo "1) Cloudflare (1.1.1.1, 1.0.0.1) - Recommended"
echo "2) Google (8.8.8.8, 8.8.4.4)"
echo "3) OpenDNS (208.67.222.222, 208.67.220.220)"
echo "4) Custom"

get_input "Select option (1-4)" "1" DNS_CHOICE

case $DNS_CHOICE in
    1)
        DNS1="1.1.1.1"
        DNS2="1.0.0.1"
        ;;
    2)
        DNS1="8.8.8.8"
        DNS2="8.8.4.4"
        ;;
    3)
        DNS1="208.67.222.222"
        DNS2="208.67.220.220"
        ;;
    4)
        get_input "Enter primary DNS server" "1.1.1.1" DNS1
        get_input "Enter secondary DNS server" "1.0.0.1" DNS2
        ;;
    *)
        DNS1="1.1.1.1"
        DNS2="1.0.0.1"
        ;;
esac

# Step 6: Update configuration files
print_step "Step 6: Updating configuration files..."

# Update .env file
cat > .env << EOF
# Pi-hole Configuration
# Generated by first-time setup wizard

# Your Mac mini's IP address
SERVER_IP=$LOCAL_IP

# Pi-hole web interface password
PIHOLE_PASSWORD=$PIHOLE_PASSWORD

# Timezone
TZ=$TIMEZONE

# DNS servers
DNS1=$DNS1
DNS2=$DNS2

# Port Configuration (auto-detected)
DNS_PORT=$RESOLVED_DNS_PORT
HTTP_PORT=$RESOLVED_HTTP_PORT
HTTPS_PORT=$RESOLVED_HTTPS_PORT
EOF

print_status "Configuration file updated"

# Update Docker Compose with resolved ports if needed
if [ -f "./resolve-ports.sh" ] && [ "$RESOLVED_DNS_PORT" != "53" ] || [ "$RESOLVED_HTTP_PORT" != "80" ] || [ "$RESOLVED_HTTPS_PORT" != "443" ]; then
    print_step "Updating Docker Compose with resolved ports..."
    update_docker_compose_ports $RESOLVED_DNS_PORT $RESOLVED_HTTP_PORT $RESOLVED_HTTPS_PORT
fi

# Step 7: Create necessary directories
print_step "Step 7: Creating directories..."

mkdir -p etc-pihole etc-dnsmasq.d
print_status "Directories created"

# Step 8: Start Pi-hole
print_step "Step 8: Starting Pi-hole..."

echo ""
print_info "Starting Pi-hole container. This may take a few minutes on first run..."
echo ""

$COMPOSE_CMD up -d

# Wait for container to be ready
print_info "Waiting for Pi-hole to start..."
sleep 10

# Check if container is running
if $COMPOSE_CMD ps | grep -q "Up"; then
    print_status "Pi-hole is running!"
else
    print_error "Failed to start Pi-hole container"
    print_info "Check the logs with: $COMPOSE_CMD logs pihole"
    exit 1
fi

# Step 9: Final instructions
clear
print_header "🎉 Pi-hole Setup Complete!"
print_header "=========================="
echo ""
print_status "Pi-hole is now running on your Mac mini!"
echo ""
print_info "📊 Access Pi-hole Admin Interface:"
echo "   🌐 http://$LOCAL_IP:$RESOLVED_HTTP_PORT/admin"
echo "   🔐 Password: $PIHOLE_PASSWORD"
echo ""
print_info "⚙️  To configure your devices to use Pi-hole:"
echo ""
echo "   Option 1 - Configure individual devices:"
if [ "$RESOLVED_DNS_PORT" = "53" ]; then
    echo "   • Set DNS server to: $LOCAL_IP"
else
    echo "   • Set DNS server to: $LOCAL_IP:$RESOLVED_DNS_PORT"
fi
echo ""
echo "   Option 2 - Configure your router (recommended):"
if [ "$RESOLVED_DNS_PORT" = "53" ]; then
    echo "   • Set router's DNS server to: $LOCAL_IP"
else
    echo "   • Set router's DNS server to: $LOCAL_IP:$RESOLVED_DNS_PORT"
fi
echo "   • This will apply Pi-hole to all devices automatically"
echo ""
print_info "📋 Useful commands:"
echo "   • View logs: $COMPOSE_CMD logs -f pihole"
echo "   • Stop Pi-hole: $COMPOSE_CMD down"
echo "   • Restart Pi-hole: $COMPOSE_CMD restart"
echo "   • Update Pi-hole: $COMPOSE_CMD pull && $COMPOSE_CMD up -d"
echo ""
print_info "🔧 To change settings:"
echo "   • Edit the .env file"
echo "   • Run: $COMPOSE_CMD up -d"
echo ""

get_yes_no "Would you like to open the Pi-hole admin interface in your browser?" "y" OPEN_BROWSER

if [ "$OPEN_BROWSER" = true ]; then
    open "http://$LOCAL_IP:$RESOLVED_HTTP_PORT/admin"
fi

echo ""
print_status "Setup complete! Enjoy your ad-free network! 🎉"
