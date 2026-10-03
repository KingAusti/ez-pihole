#!/bin/bash

# Pi-hole Easy Launcher
# This is the main entry point for first-time users
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

# Function to check if this is first time setup
is_first_time() {
    [ ! -f ".env" ] || [ ! -d "etc-pihole" ]
}

# Function to check if Pi-hole is already running
is_pihole_running() {
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    elif docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        return 1
    fi
    
    $COMPOSE_CMD ps | grep -q "Up" 2>/dev/null
}

# Function to get Pi-hole IP
get_pihole_ip() {
    if [ -f ".env" ]; then
        grep "SERVER_IP=" .env | cut -d'=' -f2
    else
        echo "unknown"
    fi
}

# Main launcher logic
main() {
    clear
    print_header "🚀 Pi-hole for Mac mini"
    print_header "======================="
    echo ""
    
    # Check if this is first time setup
    if is_first_time; then
        print_info "Welcome to Pi-hole! This appears to be your first time setting up Pi-hole."
        echo ""
        print_info "Pi-hole will block ads and trackers across your entire network."
        print_info "The setup wizard will guide you through the process."
        echo ""
        
        read -p "Would you like to run the setup wizard now? (Y/n): " run_setup
        
        if [[ $run_setup =~ ^[Nn]$ ]]; then
            print_info "Setup cancelled. Run './first-time-setup.sh' when you're ready."
            exit 0
        fi
        
        print_step "Starting first-time setup wizard..."
        echo ""
        ./first-time-setup.sh
        return
    fi
    
    # Check if Pi-hole is running
    if is_pihole_running; then
        # shellcheck disable=SC2155  # declare-and-assign kept; splitting would change behaviour under set -e
        local ip=$(get_pihole_ip)
        print_status "Pi-hole is already running!"
        echo ""
        print_info "Pi-hole is active and ready to use."
        print_info "Admin Interface: http://$ip/admin"
        echo ""
        print_info "What would you like to do?"
        echo ""
        echo "1) 🌐 Open Pi-hole admin interface"
        echo "2) 📊 View Pi-hole status"
        echo "3) 🔧 Manage Pi-hole (advanced options)"
        echo "4) 🌐 Configure network settings"
        echo "5) ❌ Stop Pi-hole"
        echo "0) 🚪 Exit"
        echo ""
        
        read -p "Enter your choice (0-5): " choice
        
        case $choice in
            1)
                # Get HTTP port from .env file
                # shellcheck disable=SC2155  # declare-and-assign kept; splitting would change behaviour under set -e
                local http_port=$(grep "HTTP_PORT=" .env 2>/dev/null | cut -d'=' -f2)
                if [ -n "$http_port" ] && [ "$http_port" != "80" ]; then
                    open "http://$ip:$http_port/admin"
                else
                    open "http://$ip/admin"
                fi
                print_status "Opening Pi-hole admin interface..."
                ;;
            2)
                ./status.sh
                ;;
            3)
                ./pihole-manager.sh
                ;;
            4)
                ./network-setup.sh
                ;;
            5)
                print_info "Stopping Pi-hole..."
                if command -v docker-compose &> /dev/null; then
                    docker-compose down
                else
                    docker compose down
                fi
                print_status "Pi-hole stopped"
                ;;
            0)
                print_info "Goodbye! 👋"
                exit 0
                ;;
            *)
                print_error "Invalid choice"
                ;;
        esac
    else
        print_info "Pi-hole is not currently running."
        echo ""
        print_info "What would you like to do?"
        echo ""
        echo "1) 🚀 Start Pi-hole"
        echo "2) 🔧 Run setup wizard (reconfigure)"
        echo "3) 📊 Check system status"
        echo "0) 🚪 Exit"
        echo ""
        
        read -p "Enter your choice (0-3): " choice
        
        case $choice in
            1)
                print_step "Starting Pi-hole..."
                if command -v docker-compose &> /dev/null; then
                    docker-compose up -d
                else
                    docker compose up -d
                fi
                
                sleep 3
                
                if is_pihole_running; then
                    # shellcheck disable=SC2155  # declare-and-assign kept; splitting would change behaviour under set -e
                    local ip=$(get_pihole_ip)
                    # shellcheck disable=SC2155  # declare-and-assign kept; splitting would change behaviour under set -e
                    local http_port=$(grep "HTTP_PORT=" .env 2>/dev/null | cut -d'=' -f2)
                    print_status "Pi-hole started successfully!"
                    
                    if [ -n "$http_port" ] && [ "$http_port" != "80" ]; then
                        print_info "Admin Interface: http://$ip:$http_port/admin"
                    else
                        print_info "Admin Interface: http://$ip/admin"
                    fi
                    
                    read -p "Would you like to open the admin interface now? (Y/n): " open_admin
                    if [[ ! $open_admin =~ ^[Nn]$ ]]; then
                        if [ -n "$http_port" ] && [ "$http_port" != "80" ]; then
                            open "http://$ip:$http_port/admin"
                        else
                            open "http://$ip/admin"
                        fi
                    fi
                else
                    print_error "Failed to start Pi-hole"
                    print_info "This might be due to port conflicts."
                    echo ""
                    print_info "Would you like to try resolving port conflicts automatically?"
                    read -p "Run port conflict resolution? (Y/n): " resolve_ports
                    
                    if [[ ! $resolve_ports =~ ^[Nn]$ ]]; then
                        if [ -f "./resolve-ports.sh" ]; then
                            print_step "Running port conflict resolution..."
                            ./resolve-ports.sh
                            echo ""
                            print_info "Now trying to start Pi-hole again..."
                            if command -v docker-compose &> /dev/null; then
                                docker-compose up -d
                            else
                                docker compose up -d
                            fi
                            sleep 3
                            
                            if is_pihole_running; then
                                # shellcheck disable=SC2155  # declare-and-assign kept; splitting would change behaviour under set -e
                                local ip=$(get_pihole_ip)
                                # shellcheck disable=SC2155  # declare-and-assign kept; splitting would change behaviour under set -e
                                local http_port=$(grep "HTTP_PORT=" .env 2>/dev/null | cut -d'=' -f2)
                                print_status "Pi-hole started successfully after port resolution!"
                                if [ -n "$http_port" ] && [ "$http_port" != "80" ]; then
                                    print_info "Admin Interface: http://$ip:$http_port/admin"
                                else
                                    print_info "Admin Interface: http://$ip/admin"
                                fi
                            else
                                print_error "Still failed to start Pi-hole"
                                print_info "Check the logs with: docker-compose logs pihole"
                            fi
                        else
                            print_error "Port resolution script not found"
                            print_info "Check the logs with: docker-compose logs pihole"
                        fi
                    else
                        print_info "Check the logs with: docker-compose logs pihole"
                    fi
                fi
                ;;
            2)
                ./first-time-setup.sh
                ;;
            3)
                ./status.sh
                ;;
            0)
                print_info "Goodbye! 👋"
                exit 0
                ;;
            *)
                print_error "Invalid choice"
                ;;
        esac
    fi
}

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    print_error "Please run this script from the pihole-docker directory"
    exit 1
fi

# Run main function
main
