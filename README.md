# Open WebUI with OSINT Configuration

This is a pre-configured installation of Open WebUI optimized for OSINT workflows. It provides a privacy-focused AI chat interface with specialized search engines, document processing, and investigation tools - no tracking, no data collection.

## 🤔 What's This Setup?

This is Open WebUI configured specifically for investigators, researchers, and anyone who needs AI assistance for open source intelligence work without leaving digital footprints.

**What makes this different:**

- Connects to your existing Ollama server (no need to duplicate models)
- Only uses privacy-focused search engines (DuckDuckGo, Startpage, Archive.org)  
- Built-in document processing that actually works
- Zero telemetry or tracking nonsense
- Works on Mac, Windows, and Linux

## 🦙 Don't Have Ollama Yet?

**You need Ollama running somewhere** - either on the same machine or a different one on your network. Here's how to get it set up properly:

### Install Ollama (Recommended Method)

**macOS & Linux:**
```bash
# Download and install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama server (accessible from other machines)
OLLAMA_HOST=0.0.0.0 ollama serve
```

**Windows:**
```cmd
# Download from https://ollama.ai/download/windows
# Install the .exe file
# Then start Ollama in a terminal:
set OLLAMA_HOST=0.0.0.0
ollama serve
```

### Pull Your Models

Once Ollama is running, get the models this setup expects:

```bash
# Main chat model (default)
ollama pull gemma3:12b-it-qat

# Embedding model for document search
ollama pull snowflake-arctic-embed2:latest

# Optional: Some other good OSINT models
ollama pull llama3.2:latest
ollama pull qwen2.5:14b
```

### Important: Network Access

**The key is `OLLAMA_HOST=0.0.0.0`** - this lets Docker containers and other machines access your Ollama server. Without this, the containers can't reach Ollama and nothing will work.

### Update Your Configuration

Edit the `.env` file to point to your Ollama server:

```bash
# If Ollama is on the same machine:
OLLAMA_BASE_URL=http://host.docker.internal:11434

# If Ollama is on a different machine:
OLLAMA_BASE_URL=http://192.168.1.100:11434
```

## ⚡ Quick Start

**TL;DR:** Run the setup script for your platform, wait a few minutes, then do the one-time config in the web interface.

### 🍎 macOS Setup

**What you need:**
- Docker Desktop for Mac ([download here](https://www.docker.com/products/docker-desktop))
- At least 8GB RAM
- About 20GB free space  
- An Ollama server running somewhere (could be the same Mac)

**Installation:**

```bash
# Get the code
git clone https://github.com/OSINTWEAVER/custom-open-webui.git
cd custom-open-webui

# Run the setup (handles everything)
chmod +x setup_mac.sh
./setup_mac.sh
```

The script will:
- Check if Docker is actually running
- Pull all the container images
- Generate secure keys for you
- Set up all the configs
- Start everything up

**macOS-specific notes:**
- Uses Docker Desktop's built-in networking
- Automatically handles file permissions
- Works with both Intel and Apple Silicon
- If you have Ollama running locally, it'll find it automatically

**Common macOS issues:**
- **"Permission denied"**: Make sure you ran `chmod +x setup_mac.sh` first
- **Docker not found**: Install Docker Desktop and make sure it's actually running
- **Port already in use**: Something else is using port 3000 or 8080 - check what's running

### 🐧 Ubuntu/Debian Setup

**What you need:**
- Ubuntu 20.04+ or Debian 11+
- At least 8GB RAM
- About 20GB free space
- External Ollama server configured

**Installation:**

```bash
# Get the code
git clone https://github.com/OSINTWEAVER/custom-open-webui.git
cd custom-open-webui

# Run the setup
chmod +x setup_ubuntu.sh
./setup_ubuntu.sh
```

The script will:
- Install Docker and Docker Compose if needed
- Configure the Docker daemon
- Set up proper firewall rules
- Generate environment configs
- Start all services

**Ubuntu-specific features:**
- Automatic Docker installation and configuration
- UFW firewall integration
- Systemd service management
- Native performance (no VM overhead)

### 🪟 Windows Setup

**Prerequisites:**
- **Docker Desktop for Windows** (required) - [Download here](https://www.docker.com/products/docker-desktop)
- **WSL2** enabled (Docker Desktop will help you set this up)
- At least 8GB RAM
- About 20GB free space

**WSL2 Setup (If Not Already Enabled):**

If you don't have WSL2 set up yet, run these commands in PowerShell as Administrator:

```powershell
# Enable WSL and Virtual Machine Platform features
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Restart required after enabling features
Restart-Computer

# After restart, set WSL 2 as default version
wsl --set-default-version 2

# Install Ubuntu (or your preferred distribution)
wsl --install -d Ubuntu

# Update WSL kernel if needed
wsl --update
```

**Installation:**

```cmd
# Download or clone the repository
git clone https://github.com/OSINTWEAVER/custom-open-webui.git
cd custom-open-webui

# Run the setup script
setup_windows.bat
```

**Windows-specific notes:**
- Requires WSL2 backend for Docker Desktop
- PowerShell execution policy may need adjustment
- File paths use Windows conventions
- Network isolation works through Docker Desktop's VM

**Common Windows issues:**
- **WSL2 not enabled**: Follow Docker Desktop's setup wizard
- **Execution policy**: Run PowerShell as admin and use `Set-ExecutionPolicy RemoteSigned`
- **Hyper-V conflicts**: Disable other virtualization software
- **Firewall blocking**: Allow Docker Desktop through Windows Defender

**Then visit <http://localhost:3000> and follow the "Configuration Steps" section below.**

## 🔧 Configuration Steps (Required)

After the containers are running, you need to configure several settings in the web interface. These can't be automated - it's just how Open WebUI works.

### 1. Configure Web Search

1. Go to **Settings** > **Admin Settings** > **Web Search**
2. Click the **Web Search** toggle (should turn blue/green)  
3. Change **Web Search Engine** dropdown to **searxng**
4. The URL should already be filled in correctly
5. Click **Trust proxy environment** (important for Docker networking)
6. Hit **Save**

### 2. Configure Document Processing  

1. Still in **Settings** > **Admin Settings**, go to **Documents**
2. Change **Content Extraction Engine** dropdown to **Tika**
3. The URL should already be there: `http://open-webui-tika:9998`
4. Click **Save**

### 3. Configure OpenAPI Tools (NEW!)

To enable the OSINT investigation tools:

1. Go to **Admin Panel** > **Tools** > **Functions**
2. Click **+ Import Function**
3. Select **Import from OpenAPI URL**
4. Enter **Base URL**: `http://open-webui-osint-tools:8001`
5. Enter **OpenAPI Path**: `openapi.json`
6. Click **Import** - this adds all 9 OSINT tools
7. Verify tools are imported: Domain WHOIS, DNS Lookup, URL Analysis, Hash Tools, IP Analysis, Social Media Check, Wayback Machine

### 4. Import MCP Time Tools

To enable Model Context Protocol time utilities:

1. Go to **Admin Panel** > **Tools** > **Functions**  
2. Click **+ Import Function**
3. Select **Import from OpenAPI URL**
4. Enter **Base URL**: `http://open-webui-mcp-proxy:8002/time`
5. Enter **OpenAPI Path**: `openapi.json`
6. Click **Import** - this adds time tools (get_current_time, convert_time)
7. Verify MCP tools appear in your function list

**Note**: Each MCP server gets its own route. Additional MCP servers can be added by configuring them in the MCP proxy and importing from their respective routes.

### 5. Enable Tools in Conversations

For each new conversation where you want to use tools:

1. Start a new chat
2. Click the **Tools** toggle (usually in the bottom toolbar)
3. Select which tools to enable for that conversation
4. Now you can ask questions like:

**OSINT Tools:**
   - "Check the WHOIS for example.com"
   - "Analyze this URL for suspicious patterns"
   - "Calculate SHA256 hash of this text"
   - "Check if username exists on social platforms"

**MCP Tools:**
   - "What's the current time in UTC?"
   - "What time is it in New York?"
   - "Convert 3 PM EST to Pacific time"

**That's it!** Now you have Open WebUI configured with privacy-focused search, document processing, and specialized investigation tools.

## 🏗️ What's Included

This configuration includes services specifically chosen for OSINT work:

### Core Services

- **Open WebUI** (Port 3000): Main chat interface with privacy-focused configuration
- **SearXNG** (Port 8080): Meta-search engine hitting multiple sources without tracking
- **LiteLLM Proxy** (Port 4000): Connects to your Ollama server and handles different model types  
- **Apache Tika** (Port 9998): Extracts text from various document formats
- **OSINT Tools API** (Port 8001): Custom investigation tools via OpenAPI
- **MCP Proxy** (Port 8002): Model Context Protocol tools via OpenAPI proxy
- **Redis**: Caching for performance optimization
- **Your Ollama Server**: Where your models live (external connection)

### 🔧 Built-in Investigation Tools

Pre-configured OpenAPI tool servers for investigation workflows:

**OSINT Tools Server (Port 8001):**

- **Domain Analysis**: WHOIS lookups, DNS record retrieval (A, AAAA, MX, NS, TXT, CNAME)
- **URL Analysis**: Structure parsing, risk assessment, suspicious pattern detection  
- **Cryptographic Tools**: Hash calculation (MD5, SHA1, SHA256, SHA512), Base64 encoding/decoding
- **IP Analysis**: Private/public classification, reverse DNS lookup, geolocation
- **Social Media Intelligence**: Username availability checking across 8+ platforms
- **Archive Investigation**: Wayback Machine availability checking, historical snapshots

**MCP Proxy Server (Port 8002):**

- **Time Tools**: Current time, timezone conversions, date calculations
- **File System Tools**: Safe file operations (when configured)
- **Git Tools**: Repository analysis and investigation  
- **Extensible**: Add any MCP-compatible tool server via environment variables

**Manual Configuration Required:**

After platform startup, you MUST import these tools manually:

1. **OSINT Tools**: 
   - **Base URL**: `http://open-webui-osint-tools:8001`
   - **OpenAPI Path**: `openapi.json`
2. **MCP Tools (Time)**: 
   - **Base URL**: `http://open-webui-mcp-proxy:8002/time`
   - **OpenAPI Path**: `openapi.json`

**Tool Access:**

- **Interactive Documentation**: <http://localhost:8001/docs> and <http://localhost:8002/docs>
- **In Chat**: Enable "Tools" toggle and ask natural language questions
- **Direct API**: Full OpenAPI 3.0 specification available for external integrations

**Example Usage:**
```
"Check the WHOIS information for suspicious-domain.com"
"Analyze this URL for security risks: https://bit.ly/xyz123"  
"Calculate SHA256 hash of this file content"
"Check if username 'target_person' exists on social platforms"
"Find archived versions of compromised-site.com"
```

### Privacy-Focused Search Engines

**Enabled for investigations:**

- DuckDuckGo & Startpage (privacy-focused general search)
- Archive.org & Wayback Machine (historical data for investigations)  
- arXiv, CrossRef (academic papers and research)
- Reddit (social intelligence)
- GitHub & GitLab (code repositories, technical intelligence)
- YouTube & Vimeo (multimedia intelligence)

**Deliberately disabled for privacy:**

- Google, Bing, Yahoo, Yandex, Baidu (tracking engines)

## 🛠 Quick Start

### Prerequisites

- **macOS**: Docker Desktop for Mac (required)
- **Windows**: Docker Desktop for Windows (required)  
- **Ubuntu**: Docker will be installed automatically if not present
- 8GB+ RAM recommended
- 20GB+ free disk space
- External Ollama server running (local or network)

### Setup

**Choose your platform:**

1. **macOS Setup**
   ```bash
   git clone <your-repo>
   cd custom-open-webui
   ./setup_mac.sh
   ```

2. **Windows Setup** 
   ```cmd
   git clone <your-repo>
   cd custom-open-webui
   setup_windows.bat
   ```

3. **Ubuntu Setup** (includes Docker auto-install)
   ```bash
   git clone <your-repo>
   cd custom-open-webui
   ./setup_ubuntu.sh
   ```

### Manual Setup (all platforms)
   ```bash
   # Copy environment template
   cp .env.example .env
   # Edit .env with your Ollama server details
   
   # Pull latest images and start services
   docker compose pull
   docker compose up -d
   ```

### Access Points

- **Open WebUI**: <http://localhost:3000>
- **SearXNG**: <http://localhost:8080>  
- **LiteLLM**: <http://localhost:4000>
- **Tika Server**: <http://localhost:9998>
- **External Ollama**: (configured in .env file)

### Recommended Models

Setup the optimized OSINT models:

```bash
./setup-models.sh
```

**Primary Models:**
- **Chat**: `gemma3:12b-it-qat`
- **Embeddings**: `snowflake-arctic-embed2:latest`

These models are specifically chosen for:
- High-quality analysis and reasoning for OSINT work
- Good balance of performance and resource usage
- Superior RAG performance with Arctic embeddings

**Recommended Settings:**
- **Max Tokens**: 16000
- **Temperature**: 0.5

## ⚙️ Configuration

### Environment Variables (.env)
```bash
# Security Keys
WEBUI_SECRET_KEY=your-secret-key
LITELLM_MASTER_KEY=sk-your-master-key

# Search Configuration  
SEARXNG_HOSTNAME=localhost
SEARXNG_UWSGI_WORKERS=4

# Optional External APIs
OPENAI_API_KEY=your-key
ANTHROPIC_API_KEY=your-key
```

### Adding External AI Models

Edit `open-webui-litellm-config/config.yaml`:
```yaml
model_list:
  - model_name: gpt-4
    litellm_params:
      model: gpt-4
      api_key: ${OPENAI_API_KEY}
```

### Custom Ollama Models
```bash
# List available models
docker exec open-webui-ollama ollama list

# Pull new models
docker exec open-webui-ollama ollama pull mistral
docker exec open-webui-ollama ollama pull codellama
```

## 🔧 Management

### Service Control
```bash
# Start services
docker-compose up -d

# Stop services  
docker-compose down

# View logs
docker-compose logs -f

# Restart specific service
docker-compose restart open-webui
```

### Data Backup
```bash
# Backup user data
tar -czf backup.tar.gz open-webui-data/ open-webui-ollama-data/

# Restore
tar -xzf backup.tar.gz
```

### Updates
```bash
# Pull latest images
docker-compose pull

# Restart with new images
docker-compose up -d
```

## 🎯 RAG Configuration

The setup comes pre-configured for optimal RAG performance:

- **Web Search**: SearXNG integration for real-time information
- **Document Processing**: Tika server for PDF, DOCX, etc.
- **Embeddings**: nomic-embed-text model for vector search
- **Hybrid Search**: Combined semantic and keyword search
- **Caching**: Redis for performance optimization

### RAG Settings
- Search results: 10 per query
- Concurrent requests: 10
- Chunk size: 1600 tokens
- Chunk overlap: 100 tokens
- Top-K results: 5

## 🔒 Security Features

- **No Telemetry**: Complete privacy protection
- **Container Security**: Minimal privileges, capability dropping
- **Local Processing**: All AI inference happens locally
- **Secure Defaults**: Authentication enabled, secure session handling
- **Network Isolation**: Services only accessible locally

## 📊 Performance Tuning

### Resource Allocation
- **Redis**: 100MB tmpfs volume for speed
- **Ollama**: Persistent storage for models
- **Tika**: Optimized JVM settings
- **Logging**: Size-limited JSON logs

### Scaling Up
- Increase Redis memory: Modify `o: size=100m` in docker-compose.yaml
- Add more Ollama workers: Set `OLLAMA_NUM_PARALLEL`
- Tune SearXNG: Adjust `SEARXNG_UWSGI_WORKERS`

## 🚨 Troubleshooting

### Connection Issues

**"Search isn't working!"**

**Did you forget the configuration steps?** Go back to the "Configuration Steps" section and make sure you:

1. Enabled web search and set it to searxng  
2. Clicked "Trust proxy environment" 
3. Set document extraction to Tika

**"It says my models aren't found!"**

Your Ollama server probably isn't reachable. Check:

```bash
# Test if your Ollama server is responding
curl http://192.168.2.241:11434/api/tags

# Or whatever IP you're using
curl http://YOUR_OLLAMA_IP:11434/api/tags
```

If that doesn't work, your containers definitely can't reach it either.

**"External Ollama unreachable"**

Check these common issues:
- IP address is correct in your `.env` file
- Ollama is running with `OLLAMA_HOST=0.0.0.0` for network access
- Firewall isn't blocking port 11434
- Network connectivity between host and Ollama server

### Performance Issues

**"Out of memory!"**

Your Docker is probably limited to 2GB or something. Give it at least 8GB if you can.

**Resource allocation by platform:**

- **macOS**: Increase Docker Desktop memory allocation
- **Windows**: Configure WSL2 memory limits in `.wslconfig`
- **Ubuntu**: Add more system RAM or configure swap

### General Docker Issues

**"Everything looks broken!"**

Classic Docker shenanigans. Try the nuclear option:

```bash
# Stop everything
docker compose down

# Check what's actually running
docker compose ps

# Start it back up
docker compose up -d

# Look at the logs if something's still broken
docker compose logs -f
```

**"OpenAPI tools aren't working!"**

The OSINT tools and MCP proxy require manual configuration after the containers start. Here's how to troubleshoot:

**Test the services first:**

```bash
# Run the comprehensive smoke test
./test-openapi-tools.sh

# Or test manually
curl http://localhost:8001/health
curl http://localhost:8001/docs
curl http://localhost:8002/docs
```

**If services aren't responding:**

```bash
# Check container status
docker compose ps

# Look at specific logs
docker compose logs open-webui-osint-tools
docker compose logs open-webui-mcp-proxy

# Restart specific services
docker compose restart open-webui-osint-tools open-webui-mcp-proxy
```

**Common OSINT Tools Issues:**

1. **"Functions not imported"**: You must manually import them:
   - Go to Admin Panel > Tools > Functions
   - Click "+ Import Function" > "Import from OpenAPI URL"
   - **Base URL**: `http://open-webui-osint-tools:8001`
   - **OpenAPI Path**: `openapi.json`
   - Should import 9 tools: Domain WHOIS, DNS Lookup, URL Analysis, etc.

2. **"Tools not available in chat"**: Enable them per conversation:
   - Start new chat
   - Toggle "Tools" in the chat interface
   - Select which tools to enable

3. **"Network errors"**: Container networking issue:
   - Use internal Base URL: `http://open-webui-osint-tools:8001`
   - NOT external URL: `http://localhost:8001`
   - OpenAPI Path should be: `openapi.json`

4. **"Import fails"**: Check OpenAPI spec validity:
   ```bash
   curl http://localhost:8001/openapi.json | jq .
   ```

**Common MCP Proxy Issues:**

1. **"MCP server not starting"**: Check entrypoint configuration:
   ```bash
   docker compose logs open-webui-mcp-proxy | grep "MCP_SERVER_CMD"
   ```

2. **"No MCP tools available"**: Check individual tool routes:
   ```bash
   # View available MCP servers/routes
   curl -s http://localhost:8002/ | grep -i "server"
   
   # Check time tools specifically
   curl -s http://localhost:8002/time/openapi.json | jq '.paths | keys'
   
   # Should show: ["/convert_time", "/get_current_time"]
   ```

3. **"Tools timeout"**: MCP proxy communication issue:
   ```bash
   # Test MCP proxy health  
   curl http://localhost:8002/time/docs
   
   # Test actual time tools (note: POST with JSON body required)
   curl -X POST "http://localhost:8002/time/get_current_time" \
     -H "Content-Type: application/json" \
     -d '{"timezone": "UTC"}'
   ```

4. **"Wrong endpoint calls"**: MCP endpoints use individual routes:
   - **Correct**: Import from `http://open-webui-mcp-proxy:8002/time` for time tools
   - **Incorrect**: Import from `http://open-webui-mcp-proxy:8002` (root level doesn't contain tools)
   - Each MCP server gets its own route: `/time`, `/git`, `/memory`, etc.

**Manual Tool Testing:**

```bash
# Test OSINT tools directly
curl -X GET "http://localhost:8001/tools/domain/whois?domain=example.com"
curl -X GET "http://localhost:8001/tools/url/analyze?url=https://suspicious-site.com"
curl -X GET "http://localhost:8001/tools/crypto/hash?text=test"

# Test MCP proxy (note: uses individual routes and POST with JSON body)
curl -X POST "http://localhost:8002/time/get_current_time" \
  -H "Content-Type: application/json" \
  -d '{"timezone": "UTC"}'

curl -X POST "http://localhost:8002/time/convert_time" \
  -H "Content-Type: application/json" \
  -d '{"time": "15:00", "source_timezone": "UTC", "target_timezone": "America/New_York"}'
```

**Complete Tool Reset:**

```bash
# Remove and re-import all functions
# 1. In Open WebUI, go to Admin Panel > Tools > Functions
# 2. Delete existing OSINT/MCP functions
# 3. Re-import from OpenAPI URLs
# 4. Restart containers if needed:
docker compose restart open-webui-osint-tools open-webui-mcp-proxy
```

**"Port conflicts!"**

Someone else is using your ports. Edit `docker-compose.yaml` and change:

- `3000:8080` to `3001:8080` (or whatever)
- `4010:4000` to `4011:4000`
- `8001:8001` to `8011:8001` (OSINT tools)
- `8002:8002` to `8012:8002` (MCP proxy)
- etc.

### Platform-Specific Issues

**macOS:**
- **"Permission denied"**: Make sure you ran `chmod +x setup_mac.sh` first
- **Docker not found**: Install Docker Desktop and make sure it's actually running
- File sharing optimization may need to be enabled in Docker Desktop

**Windows:**
- **WSL2 not enabled**: Follow Docker Desktop's setup wizard
- **Execution policy**: Run PowerShell as admin and use `Set-ExecutionPolicy RemoteSigned`
- **Hyper-V conflicts**: Disable other virtualization software

**Ubuntu:**
- **Docker daemon not running**: `sudo systemctl start docker`
- **Permission denied**: Add your user to docker group: `sudo usermod -aG docker $USER`
- **Firewall blocking**: The setup script configures UFW automatically

## 📚 Additional Documentation

- **[OSINT Guide](OSINT-GUIDE.md)** - Complete OSINT investigation workflows and best practices
- **[OpenAPI Tools Documentation](http://localhost:8001/docs)** - Interactive OSINT tools API (after startup)
- **[MCP Proxy Documentation](http://localhost:8002/docs)** - Model Context Protocol tools (after startup)

## 🔗 Quick Reference

### Essential URLs (after platform startup)
- **Open WebUI**: <http://localhost:3000> (main interface)
- **OSINT Tools API**: <http://localhost:8001/docs> (interactive documentation)
- **MCP Proxy API**: <http://localhost:8002/docs> (extensible tools)
- **SearXNG Search**: <http://localhost:8080> (privacy search engine)

### Manual Configuration Checklist
After running setup script, configure these in Open WebUI:

1. ✅ **Web Search**: Enable SearXNG in Admin Settings > Web Search
2. ✅ **Document Processing**: Set Tika in Admin Settings > Documents  
3. ✅ **Investigation Tools**: Import from Base URL `http://open-webui-osint-tools:8001` with path `openapi.json`
4. ✅ **MCP Time Tools**: Import from Base URL `http://open-webui-mcp-proxy:8002/time` with path `openapi.json`
5. ✅ **Enable Tools**: Toggle "Tools" in each conversation where needed

### Test Commands
```bash
# Verify all services
docker compose ps

# Test OSINT tools
./test-openapi-tools.sh

# Manual API tests
curl http://localhost:8001/health
curl http://localhost:8002/health
```

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

**Author**: rick@osintweaver  
**Provided without warranty by OSINTWEAVER**

## 📄 License

This configuration is provided as-is for educational and personal use.
