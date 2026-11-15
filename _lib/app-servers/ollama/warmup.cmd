@echo off
:: # warmup.cmd
::
:: ## Overview
:: Pre-warms an Ollama model into memory via /api/generate on Windows so the first inference request avoids cold-load latency.
::
:: ## Usage
:: _lib\app-servers\ollama\warmup.cmd [model_tag]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

call :ollama_warmup_model "%~1"
endlocal & (
    set "OLLAMA_KEEP_ALIVE=%OLLAMA_KEEP_ALIVE%"
    set "OLLAMA_NUM_GPU=%OLLAMA_NUM_GPU%"
)
exit /b 0

:: ## ollama_warmup_model
:: Pre-warms the requested model (defaulting to gemma:2b) in Ollama with keep_alive and CPU-safe defaults.
:ollama_warmup_model
set "_LWO_MOD=%~1"
if "!_LWO_MOD!"=="" set "_LWO_MOD=%OLLAMA_DEFAULT_MODEL%"
if "!_LWO_MOD!"=="" set "_LWO_MOD=gemma:2b"
set "_LWO_KA=%OLLAMA_KEEP_ALIVE%"
if "!_LWO_KA!"=="" set "_LWO_KA=30m"
set "OLLAMA_KEEP_ALIVE=!_LWO_KA!"
if "%OLLAMA_NUM_GPU%"=="" set "OLLAMA_NUM_GPU=0"
if "%LIBSCRIPT_DRY_RUN%"=="1" exit /b 0
where curl.exe >nul 2>&1
if errorlevel 1 exit /b 0
set "_LWO_URL=%OLLAMA_HOST%"
if "!_LWO_URL!"=="" set "_LWO_URL=http://127.0.0.1:11434"
if "!_LWO_URL:~-1!"=="/" set "_LWO_URL=!_LWO_URL:~0,-1!"
if /i "!_LWO_URL:~-3!"=="/v1" set "_LWO_URL=!_LWO_URL:~0,-3!"
:: libscript-allow-raw-curl
curl.exe -sS --connect-timeout 5 --max-time 120 -H "Content-Type: application/json" -d "{\"model\":\"!_LWO_MOD!\",\"prompt\":\"warmup\",\"stream\":false,\"keep_alive\":\"!_LWO_KA!\",\"options\":{\"num_predict\":1,\"num_ctx\":512,\"num_gpu\":0}}" "!_LWO_URL!/api/generate" >nul 2>&1
exit /b 0
