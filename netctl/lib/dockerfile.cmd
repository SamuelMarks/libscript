@echo off
:: # dockerfile.cmd
::
:: ## Overview
:: Network control library module for dockerfile.
:: 
:: ## Usage
:: This script provides internal functions and should not be executed directly.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if "%NETCTL_STATE_FILE%"=="" set NETCTL_STATE_FILE=.netctl.json

if not exist "%NETCTL_STATE_FILE%" (
    echo Error: State file '%NETCTL_STATE_FILE%' not found. >&2
    exit /b 1
)

for /f "delims=" %%p in ('jq -r ".listen[]" "%NETCTL_STATE_FILE%" 2^>nul') do (
    set "listen_str=%%p"
    if not "!listen_str:~0,5!"=="unix:" (
        for /f "tokens=2 delims=:" %%k in ("!listen_str!") do (
            if not "%%k"=="" set "listen_str=%%k"
        )
        echo EXPOSE !listen_str!
    )
)
exit /b 0
