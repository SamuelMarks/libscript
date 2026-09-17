@echo off
:: # env.cmd
::
:: ## Overview
:: Sets environment variables for Exim on Windows.
::
:: ## Usage
:: Call or execute in the current command shell:
::   call env.cmd

set "THIS_FILE=%~f0"

if "%EXIM_SMTP_PORT%"=="" set "EXIM_SMTP_PORT=25"
if "%EXIM_RELAY_FROM_HOSTS%"=="" set "EXIM_RELAY_FROM_HOSTS=127.0.0.1"
