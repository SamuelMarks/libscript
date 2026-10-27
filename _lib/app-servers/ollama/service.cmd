@echo off
:: # service.cmd
::
:: ## Overview
:: Manages background service lifecycle operations (start, stop, status, configure)
:: and OLLAMA_MODELS directory configuration for the ollama component on Windows.
::
:: ## Usage
:: service.cmd [action]

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

set "STACK="
call "!SCRIPT_DIR!\env.cmd"
set "_ACT=%~1"
if "!_ACT!"=="" set "_ACT=%ACTION%"
if "!_ACT!"=="" set "_ACT=status"
set "_SVC=%LIBSCRIPT_SERVICE_NAME%"
if "!_SVC!"=="" set "_SVC=ollama"

if /i "!_ACT!"=="start" call :configure_ollama_env
if /i "!_ACT!"=="restart" call :configure_ollama_env
if /i "!_ACT!"=="install-service" call :configure_ollama_env
if /i "!_ACT!"=="configure" (
    call :configure_ollama_env
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" restart "!_SVC!"
    exit /b !ERRORLEVEL!
)

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" "!_ACT!" "!_SVC!"
exit /b !ERRORLEVEL!

:: ## configure_ollama_env
:: Creates the OLLAMA_MODELS directory and persists the environment override.
:configure_ollama_env
if not exist "!OLLAMA_MODELS!" mkdir "!OLLAMA_MODELS!"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" override-env "!_SVC!" "OLLAMA_MODELS=!OLLAMA_MODELS!"
exit /b 0
