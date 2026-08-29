@echo off
:: # merge_location_into_server.cmd
::
:: ## Overview
:: Lifecycle script for merge_location_into_server.cmd.
::
:: ## Usage
:: See merge_location_into_server.cmd for implementation details.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%~1"=="" (
    echo Usage: %0 ^<EXISTING_CONFIG^> ^<NEW_LOCATION_BLOCK^> ^<TARGET_SERVER_NAME^> [TARGET_LISTEN_REGEX]
    exit /b 1
)

set "TARGET_LISTEN_REGEX=443.*ssl"
if not "%~4"=="" set "TARGET_LISTEN_REGEX=%~4"

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { . '%~dp0merge_location_into_server.ps1'; Merge-LocationIntoServer -ExistingConfig '%~1' -NewLocationBlock '%~2' -TargetServerName '%~3' -TargetListenRegex '%TARGET_LISTEN_REGEX%' }"
exit /b %ERRORLEVEL%
