#!/bin/bash

# Pi-hole Docker Setup Script for Mac mini
# This script helps you set up Pi-hole in a Docker container

set -e

echo "🚀 Pi-hole Docker Setup for Mac mini"
echo "====================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker Desktop for Mac first."
    echo "   Download from: https://www.docker.com/products/docker-desktop/"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not available. Please ensure Docker Desktop is properly installed."
    exit 1
fi

echo "✅ Docker is installed"

# Get the user's IP address
echo "🔍 Detecting your Mac mini's IP address..."
LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')

if [ -z "$LOCAL_IP" ]; then
    echo "❌ Could not detect your IP address. Please set SERVER_IP manually in .env file."
    exit 1
fi

echo "📍 Detected IP address: $LOCAL_IP"

# Update .env file with detected IP
if [ -f ".env" ]; then
    sed -i.bak "s/SERVER_IP=.*/SERVER_IP=$LOCAL_IP/" .env
    echo "✅ Updated .env file with your IP address"
elif [ -f ".env.example" ]; then
    cp .env.example .env
    sed -i.bak "s/SERVER_IP=.*/SERVER_IP=$LOCAL_IP/" .env
    echo "✅ Created .env from .env.example with your IP address"
    echo "   Edit .env to change the password (PIHOLE_PASSWORD) and other settings."
else
    echo "❌ .env file not found and .env.example is missing. Please ensure one exists."
    exit 1
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p etc-pihole etc-dnsmasq.d
echo "✅ Directories created"

# Set up Docker Compose command
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

echo "🐳 Starting Pi-hole container..."
$COMPOSE_CMD up -d

echo ""
echo "🎉 Pi-hole is now running!"
echo ""
echo "📊 Access Pi-hole Admin Interface:"
echo "   http://$LOCAL_IP/admin"
echo "   http://pihole.local/admin (if you add pihole.local to /etc/hosts)"
echo ""
echo "🔐 Default password: change-me"
echo "   (Change this in the .env file and restart the container)"
echo ""
echo "⚙️  To configure your devices to use Pi-hole:"
echo "   1. Set DNS server to: $LOCAL_IP"
echo "   2. Or configure your router to use $LOCAL_IP as DNS server"
echo ""
echo "📋 Useful commands:"
echo "   View logs: $COMPOSE_CMD logs -f pihole"
echo "   Stop: $COMPOSE_CMD down"
echo "   Restart: $COMPOSE_CMD restart"
echo "   Update: $COMPOSE_CMD pull && $COMPOSE_CMD up -d"
echo ""
echo "🔧 To change settings, edit the .env file and run: $COMPOSE_CMD up -d"
