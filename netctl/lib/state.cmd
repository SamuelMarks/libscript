@echo off
setlocal EnableDelayedExpansion

if "%NETCTL_STATE_FILE%"=="" set NETCTL_STATE_FILE=.netctl.json

if "%~1"=="init" goto init
if "%~1"=="listen" goto listen
if "%~1"=="static" goto static
if "%~1"=="proxy" goto proxy
if "%~1"=="rewrite" goto rewrite
exit /b 1

:init
if not exist "%NETCTL_STATE_FILE%" (
    echo {"listen":[],"routes":{}} > "%NETCTL_STATE_FILE%"
) else (
    for %%I in ("%NETCTL_STATE_FILE%") do if %%~zI equ 0 (
        echo {"listen":[],"routes":{}} > "%NETCTL_STATE_FILE%"
    )
)
exit /b 0

:listen
call :init
jq --arg p "%~2" ".listen += [$p] | .listen |= unique" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0

:static
call :init
jq --arg p "%~2" --arg t "%~3" ".routes[$p] = {\"type\": \"static\", \"target\": $t}" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0

:proxy
call :init
jq --arg p "%~2" --arg t "%~3" ".routes[$p] = {\"type\": \"proxy\", \"target\": $t}" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0

:rewrite
call :init
jq --arg p "%~2" --arg pt "%~3" ".routes[$p] = {\"type\": \"rewrite\", \"pattern\": $pt}" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0
