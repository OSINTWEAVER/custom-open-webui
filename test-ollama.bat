@echo off
REM External Ollama Connectivity Test Script for Windows
REM Tests connectivity to external Ollama servers

setlocal enabledelayedexpansion

echo 🔗 Testing External Ollama Connectivity...

REM Read Ollama URL from environment or use default
set OLLAMA_URL=http://192.168.2.241:11434
if exist .env (
    for /f "tokens=2 delims==" %%a in ('findstr "OLLAMA_BASE_URL" .env 2^>nul') do set OLLAMA_URL=%%a
)

echo 📍 Testing: !OLLAMA_URL!

REM Test basic connectivity
echo 1. Testing basic connectivity...
curl -s --connect-timeout 5 "!OLLAMA_URL!/api/tags" >nul 2>&1
if %errorlevel% equ 0 (
    echo    ✅ Server is reachable
) else (
    echo    ❌ Cannot reach server
    echo    💡 Check: network connectivity, firewall, Ollama service status
    pause
    exit /b 1
)

REM Test API endpoints
echo 2. Testing API endpoints...
curl -s "!OLLAMA_URL!/api/tags" > temp_response.json 2>nul
if %errorlevel% equ 0 (
    echo    ✅ API is responding
    type temp_response.json | findstr "models" >nul
    if !errorlevel! equ 0 (
        echo    ✅ Valid JSON response received
    ) else (
        echo    ⚠️  Response may not be valid JSON
    )
) else (
    echo    ❌ API is not responding
    del temp_response.json 2>nul
    pause
    exit /b 1
)

REM List available models (basic parsing without jq)
echo 3. Available models:
findstr /C:"\"name\":" temp_response.json >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2 delims=:" %%a in ('findstr /C:"\"name\":" temp_response.json') do (
        set model=%%a
        set model=!model:"=!
        set model=!model:,=!
        set model=!model: =!
        echo    📦 !model!
    )
) else (
    echo    ⚠️  No models found or unable to parse response
)

REM Test essential OSINT models
echo 4. Testing essential OSINT models...
set ESSENTIAL_MODELS=llama3.2 nomic-embed-text mistral

for %%m in (%ESSENTIAL_MODELS%) do (
    findstr /C:"%%m" temp_response.json >nul 2>&1
    if !errorlevel! equ 0 (
        echo    ✅ %%m ^(available^)
    ) else (
        echo    ⚠️  %%m ^(not available - consider installing^)
        echo       Install with: ollama pull %%m
    )
)

REM Test from Docker context (if available)
echo 5. Testing Docker container connectivity...
docker --version >nul 2>&1
if %errorlevel% equ 0 (
    docker run --rm curlimages/curl:latest curl -s --connect-timeout 5 "!OLLAMA_URL!/api/tags" >nul 2>&1
    if !errorlevel! equ 0 (
        echo    ✅ Docker containers can reach Ollama server
    ) else (
        echo    ⚠️  Docker containers may have connectivity issues
        echo    💡 Check: Docker network configuration
    )
) else (
    echo    ⏭️  Docker not available for testing
)

REM Network diagnostics
echo 6. Network diagnostics...
for /f "tokens=3 delims=/" %%a in ("!OLLAMA_URL!") do set HOST_PORT=%%a
for /f "tokens=1 delims=:" %%a in ("!HOST_PORT!") do set HOST=%%a
for /f "tokens=2 delims=:" %%a in ("!HOST_PORT!") do set PORT=%%a

if "!PORT!"=="" set PORT=11434

echo    Host: !HOST!
echo    Port: !PORT!

REM Test ping
ping -n 1 !HOST! >nul 2>&1
if %errorlevel% equ 0 (
    echo    ✅ Host is pingable
) else (
    echo    ⚠️  Host is not pingable ^(may be firewalled^)
)

REM Test port (using telnet if available)
echo quit | telnet !HOST! !PORT! >nul 2>&1
if %errorlevel% equ 0 (
    echo    ✅ Port !PORT! is open
) else (
    echo    ⚠️  Port !PORT! may not be accessible
)

REM Cleanup
del temp_response.json 2>nul

echo.
echo 🎉 Connectivity test complete!
echo.
echo 📋 Summary:
echo    Server: !OLLAMA_URL!

curl -s --connect-timeout 5 "!OLLAMA_URL!/api/tags" >nul 2>&1
if %errorlevel% equ 0 (
    echo    Status: ✅ Online
) else (
    echo    Status: ❌ Offline
)

echo.
echo 🔧 Next steps:
echo    • Update .env file with correct OLLAMA_BASE_URL
echo    • Ensure required models are installed on Ollama server
echo    • Test with: docker compose up -d

pause
