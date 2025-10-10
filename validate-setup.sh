#!/bin/bash

# Pi-hole Setup Validation Script
# This script validates the setup without requiring Docker to be running

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

clear
print_header "🧪 Pi-hole Setup Validation"
print_header "============================"
echo ""

# Test 1: Check if .env file exists and is valid
print_step "Test 1: Checking .env file..."
if [ -f ".env" ]; then
    print_status ".env file exists"
    
    # Check for required variables
    if grep -q "SERVER_IP=" .env; then
        print_status "SERVER_IP is configured"
    else
        print_error "SERVER_IP is missing from .env"
    fi
    
    if grep -q "PIHOLE_PASSWORD=" .env; then
        print_status "PIHOLE_PASSWORD is configured"
    else
        print_error "PIHOLE_PASSWORD is missing from .env"
    fi
    
    if grep -q "DNS_PORT=" .env; then
        print_status "Port configuration is present"
    else
        print_warning "Port configuration is missing (will use defaults)"
    fi
else
    print_error ".env file is missing"
fi

echo ""

# Test 2: Check Docker Compose configuration
print_step "Test 2: Checking Docker Compose configuration..."
if [ -f "docker-compose.yml" ]; then
    print_status "docker-compose.yml exists"
    
    # Check for valid port mappings
    if grep -q '"53:53/tcp"' docker-compose.yml; then
        print_status "DNS port mapping is correct"
    else
        print_error "DNS port mapping is incorrect"
    fi
    
    if grep -q '"80:80/tcp"' docker-compose.yml; then
        print_status "HTTP port mapping is correct"
    else
        print_error "HTTP port mapping is incorrect"
    fi
    
    if grep -q '"443:443/tcp"' docker-compose.yml; then
        print_status "HTTPS port mapping is correct"
    else
        print_error "HTTPS port mapping is incorrect"
    fi
    
    # Check for valid VIRTUAL_PORT
    if grep -q "VIRTUAL_PORT: 80" docker-compose.yml; then
        print_status "VIRTUAL_PORT is correctly set"
    else
        print_error "VIRTUAL_PORT is incorrect"
    fi
else
    print_error "docker-compose.yml is missing"
fi

echo ""

# Test 3: Check required directories
print_step "Test 3: Checking required directories..."
if [ -d "etc-pihole" ]; then
    print_status "etc-pihole directory exists"
else
    print_warning "etc-pihole directory missing (will be created during setup)"
fi

if [ -d "etc-dnsmasq.d" ]; then
    print_status "etc-dnsmasq.d directory exists"
else
    print_warning "etc-dnsmasq.d directory missing (will be created during setup)"
fi

echo ""

# Test 4: Check script permissions
print_step "Test 4: Checking script permissions..."
scripts=("start-pihole.sh" "first-time-setup.sh" "pihole-manager.sh" "status.sh" "resolve-ports.sh" "test.sh")

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            print_status "$script is executable"
        else
            print_warning "$script is not executable (fixing...)"
            chmod +x "$script"
            print_status "$script is now executable"
        fi
    else
        print_error "$script is missing"
    fi
done

echo ""

# Test 5: Check for Docker installation (optional)
print_step "Test 5: Checking Docker installation..."
if command -v docker &> /dev/null; then
    print_status "Docker is installed"
    if docker info &> /dev/null; then
        print_status "Docker is running"
    else
        print_warning "Docker is installed but not running"
        print_info "Start Docker Desktop to use Pi-hole"
    fi
else
    print_warning "Docker is not installed"
    print_info "Install Docker Desktop for Mac to use Pi-hole"
fi

echo ""

# Summary
print_header "📋 Validation Summary"
print_header "===================="
echo ""

if [ -f ".env" ] && [ -f "docker-compose.yml" ]; then
    print_status "✅ Core configuration files are present and valid"
    print_status "✅ Pi-hole application is ready to use"
    echo ""
    print_info "Next steps:"
    echo "1. Install Docker Desktop for Mac (if not already installed)"
    echo "2. Start Docker Desktop"
    echo "3. Run: ./start-pihole.sh"
    echo "4. Follow the setup wizard"
    echo ""
    print_info "The application will automatically:"
    echo "• Detect your Mac's IP address"
    echo "• Resolve any port conflicts"
    echo "• Start Pi-hole in a Docker container"
    echo "• Open the admin interface"
else
    print_error "❌ Configuration issues found"
    print_info "Please fix the issues above before proceeding"
fi

echo ""
print_status "Validation complete! 🎉"
