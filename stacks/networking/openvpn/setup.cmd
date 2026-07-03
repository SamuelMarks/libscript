@echo off
:: # setup.cmd
::
:: ## Overview
:: Orchestrates the setup and installation process for the OpenVPN networking stack stack.
:: 
:: ## Usage
:: Execute this script to install and configure openvpn on the local system.

setlocal EnableDelayedExpansion
if not defined LIBSCRIPT_ROOT_DIR set "LIBSCRIPT_ROOT_DIR=%~dp0..\..\.."
set "LOG_CMD=%~dp0\..\..\..\_lib\_common\log.cmd"
if not exist "!LOG_CMD!" set "LOG_CMD=%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd"
call "!LOG_CMD!" :log_warn "openvpn is not supported on Windows natively."
exit /b 0
