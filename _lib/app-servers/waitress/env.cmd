@echo off
:: # env.cmd
::
:: ## Overview
:: Sets environment variables for Waitress on Windows.
::
:: ## Usage
:: Call or execute in the current command shell:
::   call env.cmd

set "THIS_FILE=%~f0"

if "%WAITRESS_PORT%"=="" set "WAITRESS_PORT=8000"
if "%WAITRESS_HOST%"=="" set "WAITRESS_HOST=0.0.0.0"
if "%WAITRESS_THREADS%"=="" set "WAITRESS_THREADS=4"
