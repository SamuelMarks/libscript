@echo off
:: # cli.cmd
::
:: ## Overview
:: Windows entry point for cloud orchestration commands (deploy, teardown, backup, restore).
::
:: ## Usage
:: Dispatches sub-commands (e.g., `deploy_cloud`, `teardown_cloud`) and manages remote state lock/unlock.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=core"

set "SKIP_STATE=0"
for %%a in (%*) do (
    if "%%a"=="diff" set "SKIP_STATE=1"
    if "%%a"=="list-managed" set "SKIP_STATE=1"
    if "%%a"=="status" set "SKIP_STATE=1"
    if "%%a"=="--help" set "SKIP_STATE=1"
    if "%%a"=="-h" set "SKIP_STATE=1"
)

if "%SKIP_STATE%"=="0" (
    if exist "%~dp0state_backend.cmd" (
        call "%~dp0state_backend.cmd" pull_state
        call "%~dp0state_backend.cmd" lock_state
        if errorlevel 1 exit /b 1
    )
)

call "%~dp0\..\..\_common\component_core.cmd" %*
set "CLI_ERR=%ERRORLEVEL%"

if "%SKIP_STATE%"=="0" (
    if exist "%~dp0state_backend.cmd" (
        call "%~dp0state_backend.cmd" push_state
        call "%~dp0state_backend.cmd" unlock_state
    )
)

exit /b %CLI_ERR%
