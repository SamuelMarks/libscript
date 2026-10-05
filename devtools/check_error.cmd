@echo off
:: ## Overview
:: Windows batch wrapper for the associated bash script.
::
:: ## Usage
::   call script.cmd

set "THIS_FILE=%~f0"
sh "%~dpn0.sh" %*
exit /b %ERRORLEVEL%
