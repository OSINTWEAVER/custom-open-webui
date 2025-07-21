#!/bin/bash

# External Ollama Connectivity Test Script
# Tests connectivity to external Ollama servers

set -e

echo "🔗 Testing External Ollama Connectivity..."

# Read Ollama URL from environment or use default
OLLAMA_URL="${OLLAMA_BASE_URL:-http://192.168.2.241:11434}"

echo "📍 Testing: $OLLAMA_URL"

# Test basic connectivity
echo "1. Testing basic connectivity..."
if curl -s --connect-timeout 5 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    echo "   ✅ Server is reachable"
else
    echo "   ❌ Cannot reach server"
    echo "   💡 Check: network connectivity, firewall, Ollama service status"
    exit 1
fi

# Test API endpoints
echo "2. Testing API endpoints..."
RESPONSE=$(curl -s "$OLLAMA_URL/api/tags" 2>/dev/null)
if echo "$RESPONSE" | jq . > /dev/null 2>&1; then
    echo "   ✅ API is responding with valid JSON"
else
    echo "   ❌ API response is not valid JSON"
    echo "   Response: $RESPONSE"
    exit 1
fi

# List available models
echo "3. Available models:"
echo "$RESPONSE" | jq -r '.models[]?.name // "No models found"' | while read -r model; do
    if [ "$model" != "No models found" ]; then
        echo "   📦 $model"
    else
        echo "   ⚠️  $model"
    fi
done

# Test specific models needed for OSINT
echo "4. Testing essential OSINT models..."
ESSENTIAL_MODELS=("llama3.2" "nomic-embed-text" "mistral")

for model in "${ESSENTIAL_MODELS[@]}"; do
    if echo "$RESPONSE" | jq -r '.models[]?.name' | grep -q "^$model"; then
        echo "   ✅ $model (available)"
    else
        echo "   ⚠️  $model (not available - consider installing)"
        echo "      Install with: ollama pull $model"
    fi
done

# Test from Docker context (if Docker is available)
echo "5. Testing Docker container connectivity..."
if command -v docker &> /dev/null; then
    if docker run --rm --network host curlimages/curl:latest curl -s --connect-timeout 5 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
        echo "   ✅ Docker containers can reach Ollama server"
    else
        echo "   ⚠️  Docker containers may have connectivity issues"
        echo "   💡 Check: Docker network configuration, host.docker.internal"
    fi
else
    echo "   ⏭️  Docker not available for testing"
fi

# Network diagnostics
echo "6. Network diagnostics..."
HOST=$(echo "$OLLAMA_URL" | sed -n 's|http://\([^:]*\).*|\1|p')
PORT=$(echo "$OLLAMA_URL" | sed -n 's|.*:\([0-9]*\).*|\1|p')

if [ -z "$PORT" ]; then
    PORT=11434
fi

echo "   Host: $HOST"
echo "   Port: $PORT"

# Test ping
if ping -c 1 "$HOST" > /dev/null 2>&1; then
    echo "   ✅ Host is pingable"
else
    echo "   ⚠️  Host is not pingable (may be firewalled)"
fi

# Test port
if command -v nc &> /dev/null; then
    if nc -z "$HOST" "$PORT" 2>/dev/null; then
        echo "   ✅ Port $PORT is open"
    else
        echo "   ❌ Port $PORT is not accessible"
    fi
else
    echo "   ⏭️  netcat not available for port testing"
fi

echo ""
echo "🎉 Connectivity test complete!"
echo ""
echo "📋 Summary:"
echo "   Server: $OLLAMA_URL"
echo "   Status: $(curl -s --connect-timeout 5 "$OLLAMA_URL/api/tags" > /dev/null 2>&1 && echo "✅ Online" || echo "❌ Offline")"
echo "   Models: $(echo "$RESPONSE" | jq -r '.models | length // 0') available"
echo ""
echo "🔧 Next steps:"
echo "   • Update .env file with correct OLLAMA_BASE_URL"
echo "   • Ensure required models are installed on Ollama server"
echo "   • Test with: docker-compose up -d"
