@echo off
:: # env_printer.cmd
::
:: ## Overview
:: Environment variable exporter and formatting utility for LibScript on Windows.
:: Supports emitting environment configurations in cmd, powershell, json, and posix formats.
:: 
:: ## Usage
:: env_printer.cmd [FORMAT] [PREFIX_PATH]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

SET "searchVal=;%THIS_FILE%;"
IF NOT DEFINED STACK (
    SET "STACK=;%THIS_FILE%;"
    echo [CONTINUE] processing "%THIS_FILE%"
) ELSE (
    IF NOT "!STACK:%searchVal%=!"=="!STACK!" (
        echo [STOP]     processing "%THIS_FILE%"
        SET ERRORLEVEL=0
        goto :eof
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

set "FORMAT=%~1"
if "%FORMAT%"=="" set "FORMAT=cmd"
set "PREFIX_PATH=%~2"

if "%FORMAT%"=="dockerfile" set "FORMAT=docker"
if "%FORMAT%"=="envfile" set "FORMAT=docker_compose"

if not "%PREFIX_PATH%"=="" (
    set "BIN_PATH=%PREFIX_PATH%\bin"
    if "%FORMAT%"=="cmd" (
        echo echo %%PATH%% ^| findstr /i /c:"!BIN_PATH!" ^>nul ^|^| SET "PATH=!BIN_PATH!;!PATH!"
    ) else if "%FORMAT%"=="powershell" (
        echo if ^($env:PATH -notlike '*!BIN_PATH!*'^) {
        echo   $env:PATH = "!BIN_PATH!;" + $env:PATH
        echo }
    ) else if "%FORMAT%"=="docker" (
        set "FWD_BIN=!PREFIX_PATH:\=/!/bin"
        echo ENV PATH="!FWD_BIN!:$PATH"
    ) else if "%FORMAT%"=="docker_compose" (
        set "FWD_BIN=!PREFIX_PATH:\=/!/bin"
        echo PATH=!FWD_BIN!:$PATH
    ) else if "%FORMAT%"=="json" (
        set "ESCAPED_BIN=!BIN_PATH:\=\!"
        echo { "PATH": "!ESCAPED_BIN!" }
    ) else (
        set "FWD_BIN=!PREFIX_PATH:\=/!/bin"
        echo if case ":$PATH:" in ^(*":!FWD_BIN!:"*^) false;; ^(*^) true;; esac; then
        echo   export PATH="!FWD_BIN!:$PATH"
        echo fi
    )
)

exit /b 0
