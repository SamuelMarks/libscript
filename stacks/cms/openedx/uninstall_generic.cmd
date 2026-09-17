@echo off
:: # uninstall_generic.cmd
::
:: ## Overview
:: Windows generic uninstallation script for Open edX.
::
:: ## Usage
:: Execute this script to uninstall Open edX.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
rmdir /s /q "%LIBSCRIPT_HOME%\openedx" 2>nul
exit /b 0
