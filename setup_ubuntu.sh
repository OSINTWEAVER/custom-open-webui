#!/bin/bash

# Open WebUI OSINT Setup Script for Ubuntu
# This script helps initialize and update your OSINT-focused Open WebUI environment
# Includes Docker installation if needed

set -e

echo "🐧 Setting up Open WebUI for OSINT Investigations on Ubuntu..."

# Optional argument: custom Ollama URL (e.g., ./setup_ubuntu.sh http://127.0.0.1:11434)
CUSTOM_OLLAMA="${1:-}"
OVERRIDE_OLLAMA=false
if [[ -n "$CUSTOM_OLLAMA" ]]; then
    OVERRIDE_OLLAMA=true
fi

# Function to install Docker on Ubuntu
install_docker() {
    echo "📥 Installing Docker on Ubuntu..."
    
    # Update package index
    sudo apt-get update
    
    # Install prerequisites
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Set up the repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index again
    sudo apt-get update
    
    # Install Docker Engine, containerd, and Docker Compose
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    echo "✅ Docker installed successfully"
    echo "⚠️  You may need to log out and back in for group changes to take effect"
    echo "   Or run: newgrp docker"
}

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    read -p "Would you like to install Docker automatically? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_docker
        # Test if docker works without sudo
        if ! docker info &> /dev/null; then
            echo "🔄 Applying group changes..."
            newgrp docker <<EOF
echo "✅ Docker group applied"
EOF
        fi
    else
        echo "📥 Please install Docker manually and try again"
        echo "   Visit: https://docs.docker.com/engine/install/ubuntu/"
        exit 1
    fi
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running or requires sudo"
    echo "🚀 Trying to start Docker service..."
    sudo systemctl start docker
    
    # Check if user is in docker group
    if ! groups $USER | grep -q '\bdocker\b'; then
        echo "⚠️  User is not in docker group"
        sudo usermod -aG docker $USER
        echo "🔄 Please log out and back in, or run: newgrp docker"
        echo "   Then run this script again"
        exit 1
    fi
    
    # Try again
    if ! docker info &> /dev/null; then
        echo "❌ Docker still not accessible"
        echo "   Try: sudo systemctl start docker"
        echo "   Or: newgrp docker"
        exit 1
    fi
fi

echo "✅ Docker is installed and running"

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not available"
    echo "📥 Installing Docker Compose plugin..."
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
fi

echo "✅ Docker Compose is available"

# Validate compose file early
echo "🧪 Validating docker-compose.yaml ..."
if ! docker compose -f "$(pwd)/docker-compose.yaml" config >/dev/null 2>&1; then
    echo "❌ docker-compose.yaml validation failed. Please fix YAML or paths."
    docker compose -f "$(pwd)/docker-compose.yaml" config || true
    exit 1
fi
echo "✅ Compose file is valid"

# Install required tools if not present
echo "🔧 Checking required tools..."

if ! command -v curl &> /dev/null; then
    echo "📥 Installing curl..."
    sudo apt-get update
    sudo apt-get install -y curl
fi

if ! command -v jq &> /dev/null; then
    echo "📥 Installing jq..."
    sudo apt-get update
    sudo apt-get install -y jq
fi

if ! command -v openssl &> /dev/null; then
    echo "📥 Installing openssl..."
    sudo apt-get update
    sudo apt-get install -y openssl
fi

echo "✅ All required tools are installed"

UPDATE_MODE=false
CONTAINER_COUNT=$(docker compose ps -q | wc -l | tr -d ' ')
if [[ -f .env || -d open-webui-data || "$CONTAINER_COUNT" != "0" ]]; then
    UPDATE_MODE=true
fi

if [[ "$UPDATE_MODE" == true ]]; then
    echo "🔄 Existing installation detected - updating..."
    echo "⏹️  Bringing down running services..."
    docker compose down --remove-orphans
  
    # Backup existing data after stop
    BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
    echo "💾 Creating backup: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    [[ -d open-webui-data ]] && cp -r open-webui-data "$BACKUP_DIR/" 2>/dev/null || true
    [[ -d open-webui-litellm-config ]] && cp -r open-webui-litellm-config "$BACKUP_DIR/" 2>/dev/null || true
    [[ -f .env ]] && cp .env "$BACKUP_DIR/" 2>/dev/null || true
    echo "✅ Backup created successfully"
else
    echo "🆕 Fresh installation detected..."
fi

echo "📥 Pulling latest Docker images..."
docker compose pull
echo "✅ Latest images pulled successfully"

echo "🛠️  Rebuilding local services with no cache..."
docker compose build --pull --no-cache
echo "✅ Images pulled and services built"

# Check external Ollama connectivity
# Resolve OLLAMA URL priority: CLI arg > .env > default
OLLAMA_URL="http://host.docker.internal:11434"
if [[ "$OVERRIDE_OLLAMA" == true ]]; then
    OLLAMA_URL="$CUSTOM_OLLAMA"
elif [[ -f .env ]]; then
    OLLAMA_URL=$(grep -E "^OLLAMA_BASE_URL=" .env 2>/dev/null | tail -n1 | cut -d'=' -f2- || echo "$OLLAMA_URL")
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
if [[ ! -f .env ]]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env

    # Generate random secret keys
    WEBUI_SECRET=$(openssl rand -hex 32)
    LITELLM_MASTER="sk-$(openssl rand -hex 24)"
    LITELLM_API="sk-$(openssl rand -hex 20)"
    SEARXNG_SECRET=$(openssl rand -hex 32)

    # Idempotently set key lines in .env (remove any duplicates, then append)
    sed -i '/^WEBUI_SECRET_KEY=/d' .env && echo "WEBUI_SECRET_KEY=$WEBUI_SECRET" >> .env
    sed -i '/^LITELLM_MASTER_KEY=/d' .env && echo "LITELLM_MASTER_KEY=$LITELLM_MASTER" >> .env
    sed -i '/^LITELLM_API_KEY=/d' .env && echo "LITELLM_API_KEY=$LITELLM_API" >> .env
    sed -i '/^SEARXNG_SECRET_KEY=/d' .env && echo "SEARXNG_SECRET_KEY=$SEARXNG_SECRET" >> .env
    sed -i '/^OLLAMA_BASE_URL=/d' .env && echo "OLLAMA_BASE_URL=$OLLAMA_URL" >> .env

    echo "✅ Generated secure keys in .env file"
elif [[ "$UPDATE_MODE" == false ]]; then
    echo "ℹ️  .env file already exists"
fi

# If user passed a custom Ollama URL and .env exists, persist the override
if [[ "$OVERRIDE_OLLAMA" == true && -f .env ]]; then
    echo "📝 Applying custom OLLAMA_BASE_URL to .env: $CUSTOM_OLLAMA"
    sed -i '/^OLLAMA_BASE_URL=/d' .env && echo "OLLAMA_BASE_URL=$OLLAMA_URL" >> .env
fi

# Create necessary directories
echo "📁 Creating data directories..."
mkdir -p open-webui-data
mkdir -p open-webui-litellm-config
mkdir -p searxng

# Set proper permissions
echo "🔐 Setting permissions..."
chmod 755 open-webui-data open-webui-litellm-config searxng
# Ensure Docker can write to these directories
sudo chown -R $USER:$USER open-webui-data open-webui-litellm-config searxng

# Configure UFW firewall if active
if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
    echo "🔥 Configuring UFW firewall..."
    sudo ufw allow 3000/tcp comment "Open WebUI"
    sudo ufw allow 8080/tcp comment "SearXNG"
    sudo ufw allow 4000/tcp comment "LiteLLM"
    sudo ufw allow 9998/tcp comment "Tika"
    echo "✅ Firewall rules added"
fi

# Process configuration templates
echo "🔧 Processing configuration templates..."
chmod +x process-templates.sh
./process-templates.sh

// Start services
echo "� Starting Docker services..."
docker compose up -d --force-recreate --remove-orphans

# Wait for services to start
echo "⏳ Waiting for services to initialize..."
sleep 5

# Wait for Tika readiness
echo "🔍 Waiting for Tika to be ready..."
TIKA_READY=false
for i in {1..12}; do
    if curl -fsS http://127.0.0.1:9998/version >/dev/null 2>&1; then
        TIKA_READY=true
        break
    fi
    echo "Waiting for Tika to be ready... ($i/12)"
    sleep 3
done

if [[ "$TIKA_READY" == true ]]; then
    echo "✅ Tika is ready (OCR and deep extraction)"
else
    echo "⚠️  Tika may not be ready yet, check logs: docker compose logs open-webui-tika"
fi

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
    if curl -fsS "http://localhost:8080/search?q=test&format=json" >/dev/null 2>&1; then
        SEARXNG_READY=true
        break
    fi
    echo "Waiting for SearXNG to be ready... ($i/12)"
    sleep 3
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
MODELS=$(curl -s "$OLLAMA_URL/api/tags" 2>/dev/null | jq -r '.models[]?.name' 2>/dev/null || echo "")
if [ -n "$MODELS" ]; then
    echo "📦 Available models:"
    echo "$MODELS" | while read -r model; do
        echo "   • $model"
    done
else
    echo "⚠️  No models found or cannot connect to Ollama"
fi

# System optimization suggestions
echo "🚀 System optimization suggestions:"
if [ -f /proc/meminfo ]; then
    TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')
    if [ $TOTAL_MEM -lt 8192 ]; then
        echo "   ⚠️  Warning: Less than 8GB RAM detected ($TOTAL_MEM MB)"
        echo "      Consider upgrading for better performance"
    else
        echo "   ✅ Sufficient RAM detected ($TOTAL_MEM MB)"
    fi
fi

# Check disk space
DISK_SPACE=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
if [ $DISK_SPACE -lt 20 ]; then
    echo "   ⚠️  Warning: Less than 20GB free disk space"
    echo "      Consider freeing up space for model storage"
else
    echo "   ✅ Sufficient disk space available (${DISK_SPACE}GB)"
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
echo "   • LiteLLM Proxy: http://localhost:4010"
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
echo "   3. Verify Ollama models are available"
echo "   4. Test RAG functionality with archive sources"
echo "   5. Configure additional API keys in .env if needed"
echo ""
echo "📖 Troubleshooting:"
echo "   • Check external Ollama: ./test-ollama.sh"
echo "   • View logs: docker compose logs -f"
echo "   • Stop services: docker compose down"
echo "   • Update: Run this script again"
echo "   • Restart Docker: sudo systemctl restart docker"
