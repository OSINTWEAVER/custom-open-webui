#!/bin/bash

# OSINT Open WebUI Platform Status
# Quick health check and status overview

echo "🔍 OSINT Open WebUI Platform Status"
echo "=================================="
echo ""

# Check if .env exists
if [ -f .env ]; then
    echo "✅ Environment file: .env exists"
    
    # Load environment variables
    source .env
    
    # Check key configurations
    echo "🔧 Configuration:"
    echo "   • Ollama URL: ${OLLAMA_BASE_URL:-http://host.docker.internal:11434}"
    echo "   • LiteLLM Key: ${LITELLM_MASTER_KEY:+[SET]}${LITELLM_MASTER_KEY:-[NOT SET]}"
    echo "   • SearXNG Key: ${SEARXNG_SECRET_KEY:+[SET]}${SEARXNG_SECRET_KEY:-[NOT SET]}"
    echo ""
else
    echo "❌ Environment file: .env missing (copy from .env.example)"
    echo ""
fi

# Check Docker status
if command -v docker >/dev/null 2>&1; then
    echo "✅ Docker: Available"
    
    if docker compose version >/dev/null 2>&1; then
        echo "✅ Docker Compose: Available"
    elif docker-compose --version >/dev/null 2>&1; then
        echo "✅ Docker Compose: Available (legacy)"
    else
        echo "❌ Docker Compose: Not found"
    fi
else
    echo "❌ Docker: Not found"
fi

echo ""

# Check running services
echo "🐳 Service Status:"
if docker compose ps >/dev/null 2>&1; then
    docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
else
    echo "   No services running or docker-compose not available"
fi

echo ""

# Check external Ollama connectivity
echo "🤖 External Ollama Status:"
OLLAMA_URL="${OLLAMA_BASE_URL:-http://host.docker.internal:11434}"
if command -v curl >/dev/null 2>&1; then
    if curl -s "${OLLAMA_URL}/api/tags" >/dev/null 2>&1; then
        echo "✅ Ollama server: Accessible at $OLLAMA_URL"
        
        # Check for recommended models
        echo "📦 Model Status:"
        MODELS=$(curl -s "${OLLAMA_URL}/api/tags" 2>/dev/null || echo '{"models":[]}')
        
        if echo "$MODELS" | grep -q "gemma3:12b-it-q8_0"; then
            echo "   ✅ Gemma 3 12B (Primary): Available"
        else
            echo "   ❌ Gemma 3 12B (Primary): Not found - run ./setup-models.sh"
        fi
        
        if echo "$MODELS" | grep -q "snowflake-arctic-embed2"; then
            echo "   ✅ Arctic Embeddings: Available"
        else
            echo "   ❌ Arctic Embeddings: Not found - run ./setup-models.sh"
        fi
        
        # Get total model count
        MODEL_COUNT=$(echo "$MODELS" | grep -o '"name"' | wc -l 2>/dev/null || echo "0")
        echo "   � Total models: $MODEL_COUNT"
    else
        echo "❌ Ollama server: Cannot connect to $OLLAMA_URL"
        echo "   • Check if Ollama is running"
        echo "   • Verify OLLAMA_BASE_URL in .env"
        echo "   • Test with: curl ${OLLAMA_URL}/api/tags"
    fi
else
    echo "⚠️  curl not available - cannot test Ollama connectivity"
fi

echo ""

# Service URLs
echo "🌐 Access URLs:"
echo "   • Open WebUI (OSINT): http://localhost:3000"
echo "   • SearXNG (Search): http://localhost:8080"
echo "   • LiteLLM Proxy: http://localhost:4000"
echo "   • Tika Server: http://localhost:9998"
echo ""

# Check templates
echo "📋 Template Status:"
if [ -f "process-templates.sh" ]; then
    echo "✅ Template processor: Available"
    
    if [ -f "open-webui-litellm-config/config.yaml" ]; then
        echo "✅ LiteLLM config: Generated"
    else
        echo "⚠️  LiteLLM config: Not generated (run ./process-templates.sh)"
    fi
    
    if [ -f "searxng/settings.yml" ]; then
        echo "✅ SearXNG config: Generated"
    else
        echo "⚠️  SearXNG config: Not generated (run ./process-templates.sh)"
    fi
else
    echo "❌ Template processor: Missing"
fi

echo ""

# Quick commands
echo "🔧 Quick Commands:"
echo "   • Setup models: ./setup-models.sh"
echo "   • Start services: docker compose up -d"
echo "   • Stop services: docker compose down"
echo "   • View logs: docker compose logs -f"
echo "   • Process templates: ./process-templates.sh"
echo "   • Test Ollama: ./test-ollama.sh"
echo ""

echo "📖 Documentation: See README.md for complete setup guide"
