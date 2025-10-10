#!/bin/bash

# Pi-hole Docker Test Script
# This script tests the Pi-hole Docker setup

set -e

echo "🧪 Testing Pi-hole Docker Setup"
echo "==============================="

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

echo "✅ Docker is running"

# Check if the container can be created (dry run)
echo "🔍 Testing Docker Compose configuration..."
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

$COMPOSE_CMD config > /dev/null
echo "✅ Docker Compose configuration is valid"

# Check if required ports are available
echo "🔍 Checking port availability..."

check_port() {
    local port=$1
    if lsof -i :$port &> /dev/null; then
        echo "⚠️  Port $port is in use. You may need to stop the service using it."
        return 1
    else
        echo "✅ Port $port is available"
        return 0
    fi
}

check_port 53
check_port 80
check_port 443

echo ""
echo "🎉 All tests passed! Your Pi-hole Docker setup is ready."
echo ""
echo "To start Pi-hole, run:"
echo "  ./setup.sh"
echo ""
echo "Or manually:"
echo "  $COMPOSE_CMD up -d"
