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
