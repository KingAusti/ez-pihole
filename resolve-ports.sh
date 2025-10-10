#!/bin/bash

# Port Conflict Resolution for Pi-hole Docker
# This script automatically finds alternative ports when conflicts are detected
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

# Function to check if a port is available
is_port_available() {
    local port=$1
    ! lsof -i :$port &> /dev/null
}

# Function to find next available port starting from a given port
find_available_port() {
    local start_port=$1
    local max_attempts=100
    local port=$start_port
    
    for ((i=0; i<max_attempts; i++)); do
        if is_port_available $port; then
            echo $port
            return 0
        fi
        ((port++))
    done
    
    return 1
}

# Function to check what's using a port
get_port_usage() {
    local port=$1
    local usage=$(lsof -i :$port 2>/dev/null | tail -n +2 | awk '{print $1}' | sort -u | tr '\n' ', ' | sed 's/,$//')
    if [ -n "$usage" ]; then
        echo "$usage"
    else
        echo "unknown process"
    fi
}

# Function to resolve port conflicts (returns clean port list)
resolve_port_conflicts() {
    # Default ports
    local dns_port=53
    local http_port=80
    local https_port=443
    
    # Check and resolve DNS port (53)
    if ! is_port_available $dns_port; then
        # Try common DNS alternative ports
        for alt_port in 5353 8053 9053; do
            if is_port_available $alt_port; then
                dns_port=$alt_port
                break
            fi
        done
        
        # If no common alternatives work, find any available port
        if [ $dns_port -eq 53 ]; then
            dns_port=$(find_available_port 5353)
            if [ $? -ne 0 ]; then
                return 1
            fi
        fi
    fi
    
    # Check and resolve HTTP port (80)
    if ! is_port_available $http_port; then
        # Try common HTTP alternative ports
        for alt_port in 8080 9080 8000 9000; do
            if is_port_available $alt_port; then
                http_port=$alt_port
                break
            fi
        done
        
        # If no common alternatives work, find any available port
        if [ $http_port -eq 80 ]; then
            http_port=$(find_available_port 8080)
            if [ $? -ne 0 ]; then
                return 1
            fi
        fi
    fi
    
    # Check and resolve HTTPS port (443)
    if ! is_port_available $https_port; then
        # Try common HTTPS alternative ports
        for alt_port in 8443 9443 8001 9001; do
            if is_port_available $alt_port; then
                https_port=$alt_port
                break
            fi
        done
        
        # If no common alternatives work, find any available port
        if [ $https_port -eq 443 ]; then
            https_port=$(find_available_port 8443)
            if [ $? -ne 0 ]; then
                return 1
            fi
        fi
    fi
    
    # Store the resolved ports
    echo "$dns_port $http_port $https_port"
    return 0
}

# Function to resolve port conflicts with user feedback
resolve_port_conflicts_with_feedback() {
    print_step "Resolving port conflicts..."
    
    # Default ports
    local dns_port=53
    local http_port=80
    local https_port=443
    
    # Check and resolve DNS port (53)
    if ! is_port_available $dns_port; then
        print_warning "Port 53 (DNS) is in use by: $(get_port_usage 53)"
        print_info "Finding alternative DNS port..."
        
        # Try common DNS alternative ports
        for alt_port in 5353 8053 9053; do
            if is_port_available $alt_port; then
                dns_port=$alt_port
                print_status "Using port $dns_port for DNS"
                break
            fi
        done
        
        # If no common alternatives work, find any available port
        if [ $dns_port -eq 53 ]; then
            dns_port=$(find_available_port 5353)
            if [ $? -eq 0 ]; then
                print_status "Using port $dns_port for DNS"
            else
                print_error "Could not find an available port for DNS"
                return 1
            fi
        fi
    else
        print_status "Port 53 (DNS) is available"
    fi
    
    # Check and resolve HTTP port (80)
    if ! is_port_available $http_port; then
        print_warning "Port 80 (HTTP) is in use by: $(get_port_usage 80)"
        print_info "Finding alternative HTTP port..."
        
        # Try common HTTP alternative ports
        for alt_port in 8080 9080 8000 9000; do
            if is_port_available $alt_port; then
                http_port=$alt_port
                print_status "Using port $http_port for HTTP"
                break
            fi
        done
        
        # If no common alternatives work, find any available port
        if [ $http_port -eq 80 ]; then
            http_port=$(find_available_port 8080)
            if [ $? -eq 0 ]; then
                print_status "Using port $http_port for HTTP"
            else
                print_error "Could not find an available port for HTTP"
                return 1
            fi
        fi
    else
        print_status "Port 80 (HTTP) is available"
    fi
    
    # Check and resolve HTTPS port (443)
    if ! is_port_available $https_port; then
        print_warning "Port 443 (HTTPS) is in use by: $(get_port_usage 443)"
        print_info "Finding alternative HTTPS port..."
        
        # Try common HTTPS alternative ports
        for alt_port in 8443 9443 8001 9001; do
            if is_port_available $alt_port; then
                https_port=$alt_port
                print_status "Using port $https_port for HTTPS"
                break
            fi
        done
        
        # If no common alternatives work, find any available port
        if [ $https_port -eq 443 ]; then
            https_port=$(find_available_port 8443)
            if [ $? -eq 0 ]; then
                print_status "Using port $https_port for HTTPS"
            else
                print_error "Could not find an available port for HTTPS"
                return 1
            fi
        fi
    else
        print_status "Port 443 (HTTPS) is available"
    fi
    
    # Store the resolved ports
    echo "$dns_port $http_port $https_port"
    return 0
}

# Function to update docker-compose.yml with new ports
update_docker_compose_ports() {
    local dns_port=$1
    local http_port=$2
    local https_port=$3
    
    print_step "Updating Docker Compose configuration..."
    
    # Create backup
    cp docker-compose.yml docker-compose.yml.backup
    print_info "Created backup: docker-compose.yml.backup"
    
    # Update the ports section
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    hostname: pihole
    domainname: local
    cap_add:
      - NET_ADMIN
    environment:
      TZ: 'America/New_York'
      WEBPASSWORD: '\${PIHOLE_PASSWORD:-change-me}'
      DNS1: 1.1.1.1
      DNS2: 1.0.0.1
      DNSMASQ_LISTENING: all
      PIHOLE_DNS_: '1.1.1.1;1.0.0.1'
      VIRTUAL_HOST: pihole.local
      VIRTUAL_PORT: $http_port
      ServerIP: \${SERVER_IP:-192.168.1.10}
      WEBTHEME: default-dark
      PIHOLE_INTERFACE: eth0
      FTLCONF_LOCAL_IPV4: \${SERVER_IP:-192.168.1.10}
    volumes:
      - './etc-pihole:/etc/pihole'
      - './etc-dnsmasq.d:/etc/dnsmasq.d'
    ports:
      - "$dns_port:53/tcp"
      - "$dns_port:53/udp"
      - "$http_port:80/tcp"
      - "$https_port:443/tcp"
    restart: unless-stopped
    dns:
      - 127.0.0.1
      - 1.1.1.1
    networks:
      - pihole_net

networks:
  pihole_net:
    driver: bridge
EOF
    
    print_status "Docker Compose configuration updated with new ports"
}

# Function to update .env file with port information
update_env_ports() {
    local dns_port=$1
    local http_port=$2
    local https_port=$3
    
    print_step "Updating environment configuration..."
    
    # Add port information to .env file
    if [ -f ".env" ]; then
        # Remove existing port entries
        grep -v "^DNS_PORT=\|^HTTP_PORT=\|^HTTPS_PORT=" .env > .env.tmp
        mv .env.tmp .env
    fi
    
    # Add new port entries
    cat >> .env << EOF

# Port Configuration (auto-detected)
DNS_PORT=$dns_port
HTTP_PORT=$http_port
HTTPS_PORT=$https_port
EOF
    
    print_status "Environment configuration updated"
}

# Function to show port summary
show_port_summary() {
    local dns_port=$1
    local http_port=$2
    local https_port=$3
    local server_ip=${SERVER_IP:-$(grep "SERVER_IP=" .env 2>/dev/null | cut -d'=' -f2)}
    
    clear
    print_header "🎯 Pi-hole Port Configuration Summary"
    print_header "====================================="
    echo ""
    print_info "Port assignments:"
    echo "   🔍 DNS Server:     Port $dns_port (TCP/UDP)"
    echo "   🌐 Web Interface:  Port $http_port (HTTP)"
    echo "   🔒 Secure Web:     Port $https_port (HTTPS)"
    echo ""
    
    if [ -n "$server_ip" ]; then
        print_info "Access URLs:"
        echo "   🌐 Admin Interface: http://$server_ip:$http_port/admin"
        echo "   🔒 Secure Interface: https://$server_ip:$https_port/admin"
        echo ""
    fi
    
    print_info "Network Configuration:"
    echo "   📱 Set devices to use: $server_ip:$dns_port as DNS server"
    echo "   🏠 Or configure router DNS to: $server_ip:$dns_port"
    echo ""
    
    if [ $dns_port -ne 53 ]; then
        print_warning "Important: DNS port is not standard (53)"
        print_info "You'll need to specify the port when configuring DNS:"
        print_info "   DNS Server: $server_ip:$dns_port"
    fi
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
                echo "   📱 DNS Server: $server_ip:$dns_port"
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

# Main function
main() {
    print_header "🔧 Pi-hole Port Conflict Resolution"
    print_header "===================================="
    echo ""
    
    # Check if we're in the right directory
    if [ ! -f "docker-compose.yml" ]; then
        print_error "Please run this script from the pihole-docker directory"
        exit 1
    fi
    
    # Resolve port conflicts
    local resolved_ports=$(resolve_port_conflicts_with_feedback)
    if [ $? -ne 0 ]; then
        print_error "Failed to resolve port conflicts"
        exit 1
    fi
    
    # Parse resolved ports
    local dns_port=$(echo "$resolved_ports" | awk '{print $1}')
    local http_port=$(echo "$resolved_ports" | awk '{print $2}')
    local https_port=$(echo "$resolved_ports" | awk '{print $3}')
    
    echo ""
    print_info "Resolved ports: DNS=$dns_port, HTTP=$http_port, HTTPS=$https_port"
    
    # Update configuration files
    update_docker_compose_ports $dns_port $http_port $https_port
    update_env_ports $dns_port $http_port $https_port
    
    # Show summary
    show_port_summary $dns_port $http_port $https_port
    
    print_status "Port conflict resolution complete!"
    echo ""
    print_info "You can now start Pi-hole with: docker-compose up -d"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    main "$@"
fi
