@echo off
REM Open WebUI OSINT Setup Script for Windows
REM This script helps initialize and update your OSINT-focused Open WebUI environment

setlocal enabledelayedexpansion

echo 🪟 Setting up Open WebUI for OSINT Investigations on Windows...

REM Check prerequisites
echo 🔍 Checking prerequisites...

REM Check if Docker is installed and running
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker is not installed
    echo 📥 Please install Docker Desktop for Windows from: https://www.docker.com/products/docker-desktop
    echo    After installation, start Docker Desktop and try again
    pause
    exit /b 1
)

docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker is not running
    echo 🚀 Please start Docker Desktop and try again
    pause
    exit /b 1
)

echo ✅ Docker is installed and running

REM Check if Docker Compose is available
docker compose version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker Compose is not available
    echo 📥 Please update Docker Desktop to get Docker Compose v2
    pause
    exit /b 1
)

echo ✅ Docker Compose is available

REM Check for curl (should be available in Windows 10/11)
curl --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ curl is not available
    echo 📥 Please install curl or update Windows 10/11
    pause
    exit /b 1
)

echo ✅ curl is available

REM Function to update/pull images
echo 📥 Pulling latest Docker images...
docker compose pull
if %errorlevel% neq 0 (
    echo ❌ Failed to pull images
    pause
    exit /b 1
)
echo ✅ Latest images pulled successfully

REM Check if this is an update or fresh install
set UPDATE_MODE=false
if exist .env if exist open-webui-data (
    echo 🔄 Existing installation detected - performing update...
    
    REM Stop services
    echo ⏹️  Stopping services...
    docker compose down
    
    REM Backup existing data
    for /f "tokens=1-6 delims=:/. " %%a in ("%date% %time%") do set BACKUP_DIR=backup_%%c%%a%%b_%%d%%e%%f
    set BACKUP_DIR=!BACKUP_DIR: =!
    echo 💾 Creating backup: !BACKUP_DIR!
    mkdir "!BACKUP_DIR!" 2>nul
    xcopy /E /I open-webui-data "!BACKUP_DIR!\open-webui-data" >nul 2>&1
    xcopy /E /I open-webui-litellm-config "!BACKUP_DIR!\open-webui-litellm-config" >nul 2>&1
    copy .env "!BACKUP_DIR!\" >nul 2>&1
    echo ✅ Backup created successfully
    
    set UPDATE_MODE=true
) else (
    echo 🆕 Fresh installation detected...
)

REM Check external Ollama connectivity
set OLLAMA_URL=http://192.168.2.241:11434
if exist .env (
    for /f "tokens=2 delims==" %%a in ('findstr "OLLAMA_BASE_URL" .env 2^>nul') do set OLLAMA_URL=%%a
)

echo 🔗 Checking external Ollama server at !OLLAMA_URL!...

curl -s --connect-timeout 5 "!OLLAMA_URL!/api/tags" >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  Warning: Cannot reach external Ollama server at !OLLAMA_URL!
    echo    Please ensure:
    echo    - Ollama is running on the target machine
    echo    - The IP address is correct in your .env file
    echo    - Network connectivity is available
    echo    - Firewall allows connections on port 11434
    echo.
    echo    To test manually: curl !OLLAMA_URL!/api/tags
    echo.
    set /p CONTINUE="Continue anyway? (y/N): "
    if /i not "!CONTINUE!"=="y" exit /b 1
) else (
    echo ✅ External Ollama server is accessible
)

REM Create .env file if it doesn't exist
if not exist .env (
    echo 📝 Creating .env file from template...
    copy .env.example .env >nul
    
    REM Generate random secret keys (Windows method)
    for /f "delims=" %%a in ('powershell -command "[System.Web.Security.Membership]::GeneratePassword(64,0)"') do set WEBUI_SECRET=%%a
    for /f "delims=" %%a in ('powershell -command "[System.Web.Security.Membership]::GeneratePassword(32,0)"') do set LITELLM_MASTER=sk-%%a
    for /f "delims=" %%a in ('powershell -command "[System.Web.Security.Membership]::GeneratePassword(32,0)"') do set LITELLM_SALT=sk-%%a
    
    REM Update .env with generated keys (Windows batch method)
    powershell -command "(Get-Content .env) -replace 'your-secret-key-here-change-me', '!WEBUI_SECRET!' | Set-Content .env"
    powershell -command "(Get-Content .env) -replace 'your-litellm-master-key-here', '!LITELLM_MASTER!' | Set-Content .env"
    powershell -command "(Get-Content .env) -replace 'your-litellm-salt-key-here', '!LITELLM_SALT!' | Set-Content .env"
    
    echo ✅ Generated secure keys in .env file
) else if "!UPDATE_MODE!"=="false" (
    echo ℹ️  .env file already exists
)

REM Create necessary directories
echo 📁 Creating data directories...
mkdir open-webui-data 2>nul
mkdir open-webui-litellm-config 2>nul
mkdir searxng 2>nul

REM Process configuration templates
echo 🔧 Processing configuration templates...
call process-templates.bat

REM Start services
echo 🐳 Starting Docker services...
docker compose up -d
if %errorlevel% neq 0 (
    echo ❌ Failed to start services
    pause
    exit /b 1
)

REM Wait for services to start
echo ⏳ Waiting for services to initialize...
timeout /t 15 /nobreak >nul

REM Check if services are running
echo 🔍 Checking service status...
docker compose ps

REM Test SearXNG OSINT configuration
echo 🔍 Testing SearXNG OSINT search engines...
set SEARXNG_READY=false
for /l %%i in (1,1,12) do (
    curl -s http://localhost:8080/search?q=test^&format=json >nul 2>&1
    if !errorlevel! equ 0 (
        set SEARXNG_READY=true
        goto searxng_ready
    )
    echo Waiting for SearXNG to be ready... (%%i/12)
    timeout /t 5 /nobreak >nul
)

:searxng_ready
if "!SEARXNG_READY!"=="true" (
    echo ✅ SearXNG is ready with OSINT-optimized engines
) else (
    echo ⚠️  SearXNG may not be ready yet, check logs: docker compose logs open-webui-searxng
)

REM Verify external Ollama connectivity from container
echo 🔗 Testing Ollama connectivity from containers...
docker compose exec -T open-webui-litellm curl -s --connect-timeout 5 "!OLLAMA_URL!/api/tags" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Containers can reach external Ollama server
) else (
    echo ⚠️  Warning: Containers cannot reach external Ollama server
    echo    This might be due to network configuration
)

echo.
if "!UPDATE_MODE!"=="true" (
    echo 🎉 Update complete!
    echo 📦 Backup saved in: !BACKUP_DIR!
) else (
    echo 🎉 OSINT Setup complete!
)

echo.
echo 📋 Services available:
echo    • Open WebUI (OSINT): http://localhost:3000
echo    • SearXNG (Privacy): http://localhost:8080
echo    • LiteLLM Proxy: http://localhost:4000
echo    • Tika Server: http://localhost:9998
echo    • External Ollama: !OLLAMA_URL!
echo.
echo 🔍 OSINT Features enabled:
echo    • Privacy-focused search engines (DuckDuckGo, Startpage)
echo    • Archive.org and Wayback Machine integration
echo    • Academic sources (arXiv, CrossRef)
echo    • Social media search (Reddit)
echo    • Code repositories (GitHub, GitLab)
echo    • Multimedia search (YouTube, Vimeo)
echo    • No tracking engines (Google, Bing disabled)
echo.
echo 🔧 Next steps:
echo    1. Visit http://localhost:3000 to access Open WebUI
echo    2. Create your OSINT analyst account
echo    3. Verify Ollama models are available
echo    4. Test RAG functionality with archive sources
echo    5. Configure additional API keys in .env if needed
echo.
echo 📖 Troubleshooting:
echo    • Check external Ollama: test-ollama.bat
echo    • View logs: docker compose logs -f
echo    • Stop services: docker compose down
echo    • Update: Run this script again

pause
