@echo off
REM Configuration Template Processor for Windows
REM This script processes template files and substitutes environment variables

setlocal enabledelayedexpansion

echo 🔧 Processing configuration templates...

REM Function to generate random key
set "chars=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
set "key="
for /l %%i in (1,1,32) do (
    set /a "rand=!random! %% 62"
    for %%j in (!rand!) do set "key=!key!!chars:~%%j,1!"
)

REM Load .env file if it exists
if exist .env (
    echo 📖 Loading existing .env file...
    for /f "usebackq tokens=1,2 delims==" %%a in (".env") do (
        if not "%%a"=="" if not "%%a:~0,1%"=="#" (
            set "%%a=%%b"
        )
    )
)

REM Set default values
if not defined OLLAMA_BASE_URL set "OLLAMA_BASE_URL=http://host.docker.internal:11434"
if not defined LITELLM_MASTER_KEY set "LITELLM_MASTER_KEY=sk-!key!"
if not defined SEARXNG_SECRET_KEY set "SEARXNG_SECRET_KEY=osint-searxng-!key!"

REM Process LiteLLM config template
if exist "open-webui-litellm-config\config.yaml.template" (
    echo 📝 Processing LiteLLM config template...
    
    REM Create config directory if it doesn't exist
    if not exist "open-webui-litellm-config" mkdir "open-webui-litellm-config"
    
    REM Simple variable substitution using PowerShell
    powershell -command "& {$content = Get-Content 'open-webui-litellm-config\config.yaml.template' -Raw; $content = $content -replace '\${OLLAMA_BASE_URL}', '%OLLAMA_BASE_URL%'; $content = $content -replace '\${LITELLM_MASTER_KEY}', '%LITELLM_MASTER_KEY%'; $content = $content -replace '\${OPENAI_API_KEY}', '%OPENAI_API_KEY%'; $content = $content -replace '\${ANTHROPIC_API_KEY}', '%ANTHROPIC_API_KEY%'; Set-Content 'open-webui-litellm-config\config.yaml' -Value $content -NoNewline}"
    
    echo ✅ Generated: open-webui-litellm-config\config.yaml
)

REM Process SearXNG settings template
if exist "searxng\settings.yml.template" (
    echo 📝 Processing SearXNG settings template...
    
    REM Create searxng directory if it doesn't exist
    if not exist "searxng" mkdir "searxng"
    
    REM Simple variable substitution using PowerShell
    powershell -command "& {$content = Get-Content 'searxng\settings.yml.template' -Raw; $content = $content -replace '\${SEARXNG_SECRET_KEY}', '%SEARXNG_SECRET_KEY%'; Set-Content 'searxng\settings.yml' -Value $content -NoNewline}"
    
    echo ✅ Generated: searxng\settings.yml
)

echo ✅ Template processing completed
