#!/bin/bash

# Open WebUI OSINT Setup Script for macOS
# This script helps initialize and update your OSINT-focused Open WebUI environment

set -e

echo "🍎 Setting up Open WebUI for OSINT Investigations on macOS..."

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    echo "📥 Please install Docker Desktop for Mac from: https://www.docker.com/products/docker-desktop"
    echo "   After installation, start Docker Desktop and try again"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Docker is not running"
    echo "🚀 Please start Docker Desktop and try again"
    exit 1
fi

echo "✅ Docker is installed and running"

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not available"
    echo "📥 Please update Docker Desktop to get Docker Compose v2"
    exit 1
fi

echo "✅ Docker Compose is available"

# Check for required tools
if ! command -v curl &> /dev/null; then
    echo "❌ curl is not installed"
    echo "📥 Install with: brew install curl"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "⚠️  jq is not installed (optional but recommended)"
    echo "📥 Install with: brew install jq"
fi

# Function to update/pull images
update_images() {
    echo "📥 Pulling latest Docker images..."
    docker compose pull
    echo "✅ Latest images pulled successfully"
}

# Check if this is an update or fresh install
if [ -f .env ] && [ -d open-webui-data ]; then
    echo "🔄 Existing installation detected - performing update..."
    
    # Stop services
    echo "⏹️  Stopping services..."
    docker compose down
    
    # Update images
    update_images
    
    # Backup existing data
    BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
    echo "💾 Creating backup: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    cp -r open-webui-data "$BACKUP_DIR/" 2>/dev/null || true
    cp -r open-webui-litellm-config "$BACKUP_DIR/" 2>/dev/null || true
    cp .env "$BACKUP_DIR/" 2>/dev/null || true
    echo "✅ Backup created successfully"
    
    UPDATE_MODE=true
else
    echo "🆕 Fresh installation detected..."
    UPDATE_MODE=false
    
    # Pull images for fresh install
    update_images
fi

# Check external Ollama connectivity
OLLAMA_URL="${OLLAMA_BASE_URL:-http://192.168.2.241:11434}"
if [ -f .env ]; then
    OLLAMA_URL=$(grep "OLLAMA_BASE_URL" .env 2>/dev/null | cut -d'=' -f2 || echo "$OLLAMA_URL")
fi

echo "🔗 Checking external Ollama server at $OLLAMA_URL..."

if curl -s --connect-timeout 5 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    echo "✅ External Ollama server is accessible"
else
    echo "⚠️  Warning: Cannot reach external Ollama server at $OLLAMA_URL"
    echo "   Please ensure:"
    echo "   - Ollama is running on the target machine"
    echo "   - The IP address is correct in your .env file"
    echo "   - Network connectivity is available"
    echo "   - Firewall allows connections on port 11434"
    echo ""
    echo "   To test manually: curl $OLLAMA_URL/api/tags"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    
    # Generate random secret keys using macOS-compatible commands
    WEBUI_SECRET=$(openssl rand -hex 32)
    LITELLM_MASTER=$(openssl rand -hex 16)
    LITELLM_SALT=$(openssl rand -hex 16)
    
    # Update .env with generated keys (macOS sed syntax)
    sed -i '' "s/your-secret-key-here-change-me/$WEBUI_SECRET/" .env
    sed -i '' "s/your-litellm-master-key-here/sk-$LITELLM_MASTER/" .env
    sed -i '' "s/your-litellm-salt-key-here/sk-$LITELLM_SALT/" .env
    
    echo "✅ Generated secure keys in .env file"
elif [ "$UPDATE_MODE" = false ]; then
    echo "ℹ️  .env file already exists"
fi

# Create necessary directories
echo "📁 Creating data directories..."
mkdir -p open-webui-data
mkdir -p open-webui-litellm-config
mkdir -p searxng

# Set proper permissions (macOS)
echo "🔐 Setting permissions..."
chmod 755 open-webui-data open-webui-litellm-config searxng

# Process configuration templates
echo "🔧 Processing configuration templates..."
chmod +x process-templates.sh
./process-templates.sh

# Build custom OpenAPI tools
echo "🔨 Building OSINT tools and MCP proxy..."
docker compose build open-webui-osint-tools open-webui-mcp-proxy

# Start services
echo "🐳 Starting Docker services..."
docker compose up -d

# Wait for services to start
echo "⏳ Waiting for services to initialize..."
sleep 30

# Test OpenAPI tools
echo "🔍 Testing OpenAPI tools..."
if [ -f "./test-openapi-tools.sh" ]; then
    chmod +x test-openapi-tools.sh
    ./test-openapi-tools.sh
else
    echo "⚠️  OpenAPI smoke test not found, skipping tool tests"
fi

# Check if services are running
echo "🔍 Checking service status..."
docker compose ps

# Test SearXNG OSINT configuration
echo "🔍 Testing SearXNG OSINT search engines..."
SEARXNG_READY=false
for i in {1..12}; do
    if curl -s http://localhost:8080/search?q=test\&format=json > /dev/null 2>&1; then
        SEARXNG_READY=true
        break
    fi
    echo "Waiting for SearXNG to be ready... ($i/12)"
    sleep 5
done

if [ "$SEARXNG_READY" = true ]; then
    echo "✅ SearXNG is ready with OSINT-optimized engines"
else
    echo "⚠️  SearXNG may not be ready yet, check logs: docker compose logs open-webui-searxng"
fi

# Verify external Ollama connectivity from container
echo "🔗 Testing Ollama connectivity from containers..."
if docker compose exec -T open-webui-litellm curl -s --connect-timeout 5 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    echo "✅ Containers can reach external Ollama server"
else
    echo "⚠️  Warning: Containers cannot reach external Ollama server"
    echo "   This might be due to network configuration"
fi

# Check for available Ollama models
echo "🤖 Checking available Ollama models..."
if command -v jq &> /dev/null; then
    MODELS=$(curl -s "$OLLAMA_URL/api/tags" 2>/dev/null | jq -r '.models[]?.name' 2>/dev/null || echo "")
    if [ -n "$MODELS" ]; then
        echo "📦 Available models:"
        echo "$MODELS" | while read -r model; do
            echo "   • $model"
        done
    else
        echo "⚠️  No models found or cannot connect to Ollama"
    fi
else
    echo "ℹ️  Install jq to see available models: brew install jq"
fi

echo ""
if [ "$UPDATE_MODE" = true ]; then
    echo "🎉 Update complete!"
    echo "📦 Backup saved in: $BACKUP_DIR"
else
    echo "🎉 OSINT Setup complete!"
fi

echo ""
echo "📋 Services available:"
echo "   • Open WebUI (OSINT): http://localhost:3000"
echo "   • SearXNG (Privacy): http://localhost:8080"
echo "   • LiteLLM Proxy: http://localhost:4000"
echo "   • Tika Server: http://localhost:9998"
echo "   • OSINT Tools API: http://localhost:8001/docs"
echo "   • MCP Proxy API: http://localhost:8002/docs"
echo "   • External Ollama: $OLLAMA_URL"
echo ""
echo "🔍 OSINT Features enabled:"
echo "   • Privacy-focused search engines (DuckDuckGo, Startpage)"
echo "   • Archive.org and Wayback Machine integration"
echo "   • Academic sources (arXiv, CrossRef)"
echo "   • Social media search (Reddit)"
echo "   • Code repositories (GitHub, GitLab)"
echo "   • Multimedia search (YouTube, Vimeo)"
echo "   • No tracking engines (Google, Bing disabled)"
echo ""
echo "🔧 Next steps:"
echo "   1. Visit http://localhost:3000 to access Open WebUI"
echo "   2. Create your OSINT analyst account"
echo "   3. Set up recommended models: ./setup-models.sh"
echo "   4. Test RAG functionality with archive sources"
echo "   5. Configure additional API keys in .env if needed"
echo ""
echo "📖 Troubleshooting:"
echo "   • Setup models: ./setup-models.sh"
echo "   • Check external Ollama: ./test-ollama.sh"
echo "   • View logs: docker compose logs -f"
echo "   • Stop services: docker compose down"
echo "   • Update: Run this script again"
