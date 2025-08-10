@echo off
REM Open WebUI OSINT Setup Script for Windows
REM This script helps initialize and update your OSINT-focused Open WebUI environment

setlocal enabledelayedexpansion

echo [SETUP] Setting up Open WebUI for OSINT Investigations on Windows...

REM Check prerequisites
echo [CHECK] Checking prerequisites...

REM Check if Docker is installed and running
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not installed
    echo [ACTION] Please install Docker Desktop for Windows from: https://www.docker.com/products/docker-desktop
    echo         After installation, start Docker Desktop and try again
    pause
    exit /b 1
)

docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not running
    echo [ACTION] Please start Docker Desktop and try again
    pause
    exit /b 1
)

echo [OK] Docker is installed and running

REM Check if Docker Compose is available
docker compose version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker Compose is not available
    echo [ACTION] Please update Docker Desktop to get Docker Compose v2
    pause
    exit /b 1
)

echo [OK] Docker Compose is available

REM Check for curl (should be available in Windows 10/11)
curl --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] curl is not available
    echo [ACTION] Please install curl or update Windows 10/11
    pause
    exit /b 1
)

echo [OK] curl is available

REM Optional argument: custom Ollama URL (e.g., .\setup_windows.bat http://127.0.0.1:11434)
set "CUSTOM_OLLAMA=%~1"
set OVERRIDE_OLLAMA=false
if not "%CUSTOM_OLLAMA%"=="" (
    set OVERRIDE_OLLAMA=true
)

REM Validate compose file early
echo [STEP] Validating docker-compose.yaml ...
docker compose -f "%cd%\docker-compose.yaml" config >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] docker-compose.yaml validation failed. Please fix YAML or paths.
    docker compose -f "%cd%\docker-compose.yaml" config
    pause
    exit /b 1
)
echo [OK] Compose file is valid

REM Determine update mode and stop existing stack if present
set UPDATE_MODE=false
set CONTAINER_COUNT=0
for /f "tokens=*" %%c in ('docker compose ps -q ^| find /c /v ""') do set CONTAINER_COUNT=%%c
if exist .env set UPDATE_MODE=true
if exist open-webui-data set UPDATE_MODE=true
if not "%CONTAINER_COUNT%"=="0" set UPDATE_MODE=true

if "%UPDATE_MODE%"=="true" (
    echo [UPDATE] Existing installation detected - updating...
    echo [DOWN] Bringing down running services...
    docker compose down --remove-orphans
    
    REM Backup existing data after stop
    for /f "tokens=1-6 delims=:/. " %%a in ("%date% %time%") do set BACKUP_DIR=backup_%%c%%a%%b_%%d%%e%%f
    set BACKUP_DIR=!BACKUP_DIR: =!
    echo [BACKUP] Creating backup: !BACKUP_DIR!
    mkdir "!BACKUP_DIR!" 2>nul
    if exist open-webui-data xcopy /E /I open-webui-data "!BACKUP_DIR!\open-webui-data" >nul 2>&1
    if exist open-webui-litellm-config xcopy /E /I open-webui-litellm-config "!BACKUP_DIR!\open-webui-litellm-config" >nul 2>&1
    if exist .env copy .env "!BACKUP_DIR!\" >nul 2>&1
    echo [OK] Backup created successfully
) else (
    echo [NEW] Fresh installation detected...
)

echo [PULL] Pulling latest images...
docker compose pull
if %errorlevel% neq 0 (
    echo [ERROR] Failed to pull images
    pause
    exit /b 1
)

echo [BUILD] Rebuilding local services with no cache...
docker compose build --pull --no-cache
if %errorlevel% neq 0 (
    echo [ERROR] Failed to build services
    pause
    exit /b 1
)
echo [OK] Images pulled and services built

REM Check external Ollama connectivity
REM Resolve OLLAMA URL priority: CLI arg > .env > default
set OLLAMA_URL=http://host.docker.internal:11434
if "%OVERRIDE_OLLAMA%"=="true" (
    set OLLAMA_URL=%CUSTOM_OLLAMA%
) else (
    if exist .env (
        for /f "delims=" %%a in ('powershell -NoProfile -Command "(Get-Content -Raw .env) -split '\n' | Where-Object { $_ -match '^OLLAMA_BASE_URL=' } | Select-Object -Last 1"') do (
            for /f "tokens=2 delims==" %%b in ("%%a") do set OLLAMA_URL=%%b
        )
    )
)

echo [CHECK] Checking external Ollama server at !OLLAMA_URL! ...

curl -s --connect-timeout 5 "!OLLAMA_URL!/api/tags" >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARN] Cannot reach external Ollama server at !OLLAMA_URL!
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
    echo [OK] External Ollama server is accessible
)

REM Create .env file if it doesn't exist
if not exist .env (
    echo [ENV] Creating .env file from template...
    copy .env.example .env >nul

    REM Generate secure keys
    for /f "delims=" %%a in ('powershell -NoProfile -Command "[System.Web.Security.Membership]::GeneratePassword(64,0)"') do set WEBUI_SECRET=%%a
    for /f "delims=" %%a in ('powershell -NoProfile -Command "[System.Web.Security.Membership]::GeneratePassword(48,0)"') do set LITELLM_MASTER=sk-%%a
    for /f "delims=" %%a in ('powershell -NoProfile -Command "[System.Web.Security.Membership]::GeneratePassword(40,0)"') do set LITELLM_API=sk-%%a
    for /f "delims=" %%a in ('powershell -NoProfile -Command "[System.Web.Security.Membership]::GeneratePassword(64,0)"') do set SEARXNG_SECRET=%%a

    REM Idempotently set key lines in .env (remove any duplicates, then append)
    powershell -NoProfile -Command "$c=Get-Content .env; $c=$c | Where-Object { $_ -notmatch '^WEBUI_SECRET_KEY=' }; $c + 'WEBUI_SECRET_KEY=!WEBUI_SECRET!' | Set-Content .env"
    powershell -NoProfile -Command "$c=Get-Content .env; $c=$c | Where-Object { $_ -notmatch '^LITELLM_MASTER_KEY=' }; $c + 'LITELLM_MASTER_KEY=!LITELLM_MASTER!' | Set-Content .env"
    powershell -NoProfile -Command "$c=Get-Content .env; $c=$c | Where-Object { $_ -notmatch '^LITELLM_API_KEY=' }; $c + 'LITELLM_API_KEY=!LITELLM_API!' | Set-Content .env"
    powershell -NoProfile -Command "$c=Get-Content .env; $c=$c | Where-Object { $_ -notmatch '^SEARXNG_SECRET_KEY=' }; $c + 'SEARXNG_SECRET_KEY=!SEARXNG_SECRET!' | Set-Content .env"

    REM Ensure OLLAMA_BASE_URL is set (use override if provided)
    powershell -NoProfile -Command "$c=Get-Content .env; $c=$c | Where-Object { $_ -notmatch '^OLLAMA_BASE_URL=' }; $c + 'OLLAMA_BASE_URL=!OLLAMA_URL!' | Set-Content .env"

    echo [OK] Generated secure keys in .env file
) else if "!UPDATE_MODE!"=="false" (
    echo [INFO] .env file already exists
)

REM If user passed a custom Ollama URL and .env exists, persist the override
if "%OVERRIDE_OLLAMA%"=="true" if exist .env (
    echo [ENV] Applying custom OLLAMA_BASE_URL to .env: %CUSTOM_OLLAMA%
    powershell -NoProfile -Command "$c=Get-Content .env; $c=$c | Where-Object { $_ -notmatch '^OLLAMA_BASE_URL=' }; $c + 'OLLAMA_BASE_URL=!OLLAMA_URL!' | Set-Content .env"
)

REM Create necessary directories
echo [FS] Creating data directories...
mkdir open-webui-data 2>nul
mkdir open-webui-litellm-config 2>nul
mkdir searxng 2>nul

REM Process configuration templates
echo [TEMPLATES] Processing configuration templates...
call process-templates.bat

REM Start services
echo [UP] Starting Docker services...
docker compose up -d --force-recreate --remove-orphans
if %errorlevel% neq 0 (
    echo [ERROR] Failed to start services
    pause
    exit /b 1
)

REM Wait for services to start
echo [WAIT] Waiting for services to initialize...
timeout /t 5 /nobreak >nul

REM Wait for Tika /version
set TIKA_READY=false
for /l %%i in (1,1,12) do (
    curl -fsS http://127.0.0.1:9998/version >nul 2>&1
    if !errorlevel! equ 0 (
        set TIKA_READY=true
        goto tika_ready
    )
    echo Waiting for Tika to be ready... (%%i/12)
    timeout /t 3 /nobreak >nul
)

:tika_ready
if "!TIKA_READY!"=="true" (
    echo [OK] Tika is ready (OCR and deep extraction)
) else (
    echo [WARN] Tika may not be ready yet, check logs: docker compose logs open-webui-tika
)

REM Check if services are running
echo [STATUS] Checking service status...
docker compose ps

REM Test SearXNG OSINT configuration
echo [TEST] Testing SearXNG OSINT search engines...
set SEARXNG_READY=false
for /l %%i in (1,1,12) do (
    curl -fsS http://127.0.0.1:8080/search?q=test^&format=json >nul 2>&1
    if !errorlevel! equ 0 (
        set SEARXNG_READY=true
        goto searxng_ready
    )
    echo Waiting for SearXNG to be ready... (%%i/12)
    timeout /t 3 /nobreak >nul
)

:searxng_ready
if "!SEARXNG_READY!"=="true" (
    echo [OK] SearXNG is ready with OSINT-optimized engines
) else (
    echo [WARN] SearXNG may not be ready yet, check logs: docker compose logs open-webui-searxng
)

REM Verify external Ollama connectivity from container
echo [TEST] Testing Ollama connectivity from containers...
docker compose exec -T open-webui-litellm curl -s --connect-timeout 5 "!OLLAMA_URL!/api/tags" >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Containers can reach external Ollama server
) else (
    echo [WARN] Containers cannot reach external Ollama server
    echo       This might be due to network configuration
)

echo.
if "!UPDATE_MODE!"=="true" (
    echo [DONE] Update complete!
    echo [BACKUP] Backup saved in: !BACKUP_DIR!
) else (
    echo [DONE] OSINT Setup complete!
)

echo.
echo [INFO] Services available:
echo    - Open WebUI (OSINT): http://localhost:3000
echo    - SearXNG (Privacy): http://localhost:8080
echo    - LiteLLM Proxy: http://localhost:4010
echo    - Tika Server: http://localhost:9998
echo    - External Ollama: !OLLAMA_URL!
echo.
echo [INFO] OSINT Features enabled:
echo    - Privacy-focused search engines (DuckDuckGo, Startpage)
echo    - Archive.org and Wayback Machine integration
echo    - Academic sources (arXiv, CrossRef)
echo    - Social media search (Reddit)
echo    - Code repositories (GitHub, GitLab)
echo    - Multimedia search (YouTube, Vimeo)
echo    - No tracking engines (Google, Bing disabled)
echo.
echo [NEXT] Next steps:
echo    1. Visit http://localhost:3000 to access Open WebUI
echo    2. Create your OSINT analyst account
echo    3. Verify Ollama models are available
echo    4. Test RAG functionality with archive sources
echo    5. Configure additional API keys in .env if needed
echo.
echo [HELP] Troubleshooting:
echo    - Check external Ollama: test-ollama.bat
echo    - View logs: docker compose logs -f
echo    - Stop services: docker compose down
echo    - Update: Run this script again

pause
