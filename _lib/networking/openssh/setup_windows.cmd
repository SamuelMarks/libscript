@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Windows setup script for OpenSSH.
:: Ensures OpenSSH Client capability or executable is active.
::
:: ## Usage
:: Automatically invoked during libscript openssh installation on Windows.

set "THIS_FILE=%~f0"

where ssh >nul 2>&1
if %errorlevel% equ 0 exit /b 0

dism /Online /Add-Capability /CapabilityName:OpenSSH.Client~~~~0.0.1.0 >nul 2>&1
exit /b 0
