@echo off
:: # env.cmd
::
:: ## Overview
:: Sets environment variables for Uvicorn on Windows.
::
:: ## Usage
:: Call or execute in the current command shell:
::   call env.cmd

set "THIS_FILE=%~f0"

if "%UVICORN_PORT%"=="" set "UVICORN_PORT=8000"
if "%UVICORN_HOST%"=="" set "UVICORN_HOST=0.0.0.0"
if "%UVICORN_WORKERS%"=="" set "UVICORN_WORKERS=2"
