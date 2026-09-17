@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
:: # create_server_block.cmd
::
:: ## Overview
:: Creates and configures an IIS site and FastCGI handler on Windows.
::
:: ## Usage
:: create_server_block.cmd

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0create_server_block.ps1" %*
exit /b %ERRORLEVEL%
