#!/bin/bash

# OSINT Model Setup Script
# Downloads and configures the recommended models for OSINT operations

echo "🚀 Setting up OSINT-optimized models..."
echo "======================================="

# Check if we have access to external Ollama
OLLAMA_URL="${OLLAMA_BASE_URL:-http://host.docker.internal:11434}"
if [ -f .env ]; then
    source .env
    OLLAMA_URL="${OLLAMA_BASE_URL:-$OLLAMA_URL}"
fi

echo "🔗 Using Ollama server: $OLLAMA_URL"

# Function to check if Ollama is accessible
check_ollama() {
    if command -v curl >/dev/null 2>&1; then
        if curl -s "${OLLAMA_URL}/api/tags" >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# Function to pull model via external Ollama
pull_model() {
    local model_name="$1"
    local display_name="$2"
    
    echo ""
    echo "📦 Pulling $display_name..."
    echo "   Model: $model_name"
    
    if command -v curl >/dev/null 2>&1; then
        # Use Ollama API to pull model
        curl -X POST "${OLLAMA_URL}/api/pull" \
             -H "Content-Type: application/json" \
             -d "{\"name\": \"$model_name\"}" \
             --no-progress-meter
        
        if [ $? -eq 0 ]; then
            echo "✅ Successfully pulled $display_name"
        else
            echo "❌ Failed to pull $display_name"
            return 1
        fi
    else
        echo "❌ curl not available - cannot pull models automatically"
        echo "   Please run manually: ollama pull $model_name"
        return 1
    fi
}

# Check Ollama connectivity
if ! check_ollama; then
    echo "❌ Cannot connect to Ollama server at $OLLAMA_URL"
    echo ""
    echo "🔧 Troubleshooting steps:"
    echo "   1. Ensure Ollama is running on the target server"
    echo "   2. Check network connectivity to $OLLAMA_URL"
    echo "   3. Verify OLLAMA_BASE_URL in .env file"
    echo "   4. Test manually: curl ${OLLAMA_URL}/api/tags"
    echo ""
    exit 1
fi

echo "✅ Ollama server is accessible"
echo ""

# Pull the primary OSINT model
echo "🧠 Setting up primary OSINT model..."
pull_model "gemma3:12b-it-qat" \
           "Gemma 3 12B Instruct (qat)"

# Pull the embeddings model
echo ""
echo "🔍 Setting up embeddings model for RAG..."
pull_model "snowflake-arctic-embed2" \
           "Snowflake Arctic Embed 2"

echo ""
echo "🎉 Model setup complete!"
echo ""

# List available models
echo "📋 Available models:"
if command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    curl -s "${OLLAMA_URL}/api/tags" | jq -r '.models[] | "   • \(.name) (\(.size/1000000000 | round)GB)"'
elif command -v curl >/dev/null 2>&1; then
    echo "   (Install jq for detailed model listing: brew install jq)"
    curl -s "${OLLAMA_URL}/api/tags" | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | sed 's/^/   • /'
else
    echo "   (curl not available - cannot list models)"
fi

echo ""
echo "🔧 Configuration Summary:"
echo "   • Primary Model: gemma3-12b-it-qat"
echo "   • Embeddings: snowflake-arctic-embed2"
echo "   • Server: $OLLAMA_URL"
echo ""
echo "📖 Next Steps:"
echo "   1. Start the OSINT platform: docker compose up -d"
echo "   2. Access Open WebUI: http://localhost:3000"
echo "   3. Select 'gemma3-12b-it-qat' as your default model"
echo "   4. Test RAG functionality with OSINT sources"
