@echo off
:: # setup.cmd
::
:: ## Overview
:: Orchestrates the setup and installation process for the WooCommerce e-commerce platform stack.
:: 
:: ## Usage
:: Execute this script to install and configure woocommerce on the local system.

setlocal EnableDelayedExpansion

:: Fallback to running PowerShell for Windows provisioning
set "THIS_FILE=%~f0"
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell not found. Cannot configure WooCommerce on Windows.
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
