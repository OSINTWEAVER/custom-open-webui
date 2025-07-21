#!/bin/bash

# Project Structure Summary Script
# Shows the current state of the OSINT Open WebUI setup

echo "📋 OSINT Open WebUI Project Structure"
echo "======================================"
echo ""

echo "🗂️  Main Configuration Files:"
echo "   docker-compose.yaml      - Main service configuration (external Ollama)"
echo "   docker-compose.dev.yaml  - Development overrides"
echo "   .env.example             - Environment template with OSINT settings"
echo ""

echo "📜 Setup Scripts (Platform-Specific):"
echo "   setup_mac.sh             - macOS setup (Docker Desktop required)"
echo "   setup_ubuntu.sh          - Ubuntu setup (auto-installs Docker)"
echo "   setup_windows.bat        - Windows setup (Docker Desktop required)"
echo ""

echo "🧪 Testing Scripts:"
echo "   test-ollama.sh           - Test external Ollama connectivity (macOS/Ubuntu)"
echo "   test-ollama.bat          - Test external Ollama connectivity (Windows)"
echo ""

echo "📚 Documentation:"
echo "   README.md                - Main project documentation"
echo "   PLATFORM-SETUP.md       - Platform-specific setup guide"
echo "   OSINT-GUIDE.md          - OSINT investigation workflows"
echo ""

echo "⚙️  Configuration Directories:"
echo "   searxng/                 - SearXNG OSINT-optimized configuration"
echo "   open-webui-litellm-config/ - LiteLLM external Ollama configuration"
echo ""

echo "📦 Data Directories (created on first run):"
echo "   open-webui-data/         - Open WebUI persistent data"
echo ""

echo "🔍 Key Features:"
echo "   ✅ External Ollama support (no local model storage)"
echo "   ✅ Privacy-focused search engines (DuckDuckGo, Startpage)"
echo "   ✅ OSINT-specific engines (Archive.org, Reddit, GitHub)"
echo "   ✅ Document processing via Apache Tika"
echo "   ✅ Zero telemetry and tracking"
echo "   ✅ Cross-platform support (macOS, Windows, Ubuntu)"
echo "   ✅ Automatic updates via setup scripts"
echo ""

echo "🚀 Quick Start:"
echo "   1. Choose your platform setup script:"
echo "      macOS:   ./setup_mac.sh"
echo "      Windows: setup_windows.bat"
echo "      Ubuntu:  ./setup_ubuntu.sh"
echo ""
echo "   2. Configure external Ollama in .env:"
echo "      OLLAMA_BASE_URL=http://192.168.2.241:11434"
echo ""
echo "   3. Test connectivity:"
echo "      ./test-ollama.sh (macOS/Ubuntu)"
echo "      test-ollama.bat (Windows)"
echo ""

echo "🔗 Default Access Points:"
echo "   Open WebUI:  http://localhost:3000"
echo "   SearXNG:     http://localhost:8080"
echo "   LiteLLM:     http://localhost:4000"
echo "   Tika:        http://localhost:9998"
echo ""

echo "📖 For detailed setup instructions, see PLATFORM-SETUP.md"
