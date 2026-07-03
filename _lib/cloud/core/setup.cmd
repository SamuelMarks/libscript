@echo off
:: # setup.cmd
::
:: ## Overview
:: Action dispatcher for cloud core on Windows.
::
:: ## Usage
:: Handles sub-actions (`list-managed`, `status`, `diff`, `backup`, `restore`) by delegating to dedicated scripts.

setlocal EnableDelayedExpansion

set "action=%ACTION%"

if /i "%action%"=="list-managed" goto handle_list_managed
if /i "%action%"=="status" goto handle_list_managed
if /i "%action%"=="diff" goto handle_diff
if /i "%action%"=="backup" (
    call "%~dp0backup_cloud.cmd" %*
    exit /b %errorlevel%
)
if /i "%action%"=="restore" (
    call "%~dp0restore_cloud.cmd" %*
    exit /b %errorlevel%
)

:: Default behavior (no-op)
goto :eof

:handle_diff
echo Comparing local .libscript_state.json with cloud provider reality...
if not exist ".libscript_state.json" (
    echo No local .libscript_state.json found. All discovered resources are untracked.
)
echo --- AWS Drift
echo AWS Diff Placeholder
echo --- Azure Drift
echo Azure Diff Placeholder
echo --- GCP Drift
echo GCP Diff Placeholder
exit /b 0

:handle_list_managed
echo --- AWS Resources
where aws >nul 2>&1
if not errorlevel 1 (
    echo AWS Managed Resource Listing Placeholder
)
echo --- Azure Resources
where az >nul 2>&1
if not errorlevel 1 (
    echo Azure Managed Resource Listing Placeholder
)
echo --- GCP Resources
where gcloud >nul 2>&1
if not errorlevel 1 (
    echo GCP Managed Resource Listing Placeholder
)
exit /b 0
