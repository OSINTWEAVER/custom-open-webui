#!/bin/bash

# Configuration Template Processor
# This script processes template files and substitutes environment variables

set -e

# Function to process a template file
process_template() {
    local template_file="$1"
    local output_file="$2"
    
    if [ ! -f "$template_file" ]; then
        echo "⚠️  Template file $template_file not found"
        return 1
    fi
    
    echo "📝 Processing template: $template_file -> $output_file"
    
    # Create output directory if it doesn't exist
    mkdir -p "$(dirname "$output_file")"
    
    # Process template with environment variable substitution
    envsubst < "$template_file" > "$output_file"
    
    echo "✅ Generated: $output_file"
}

# Function to generate a random key
generate_key() {
    local length="${1:-32}"
    if command -v openssl &> /dev/null; then
        openssl rand -hex "$length"
    elif command -v head &> /dev/null && [ -f /dev/urandom ]; then
        head -c "$length" /dev/urandom | xxd -p | tr -d '\n'
    else
        # Fallback for systems without openssl or /dev/urandom
        date +%s | sha256sum | base64 | head -c "$length" ; echo
    fi
}

# Function to setup environment variables for templates
setup_env_vars() {
    # Load existing .env if available
    if [ -f .env ]; then
        set -a  # automatically export all variables
        source .env
        set +a
    fi
    
    # Set defaults for template processing
    export OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-http://host.docker.internal:11434}"
    export LITELLM_MASTER_KEY="${LITELLM_MASTER_KEY:-sk-$(generate_key 16)}"
    export SEARXNG_SECRET_KEY="${SEARXNG_SECRET_KEY:-osint-searxng-$(generate_key 16)}"
    export OPENAI_API_KEY="${OPENAI_API_KEY:-}"
    export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"
    export GOOGLE_API_KEY="${GOOGLE_API_KEY:-}"
}

# Main function
main() {
    echo "🔧 Processing configuration templates..."
    
    # Setup environment variables
    setup_env_vars
    
    # Process LiteLLM config template
    if [ -f "open-webui-litellm-config/config.yaml.template" ]; then
        process_template "open-webui-litellm-config/config.yaml.template" "open-webui-litellm-config/config.yaml"
    fi
    
    # Process SearXNG settings template
    if [ -f "searxng/settings.yml.template" ]; then
        process_template "searxng/settings.yml.template" "searxng/settings.yml"
    fi
    
    echo "✅ Template processing completed"
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
