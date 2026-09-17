@echo off
:: # env.cmd
::
:: ## Overview
:: Sets environment variables for Gunicorn on Windows.
::
:: ## Usage
:: Call or execute in the current command shell:
::   call env.cmd

set "THIS_FILE=%~f0"

if "%GUNICORN_WORKERS%"=="" set "GUNICORN_WORKERS=2"
if "%GUNICORN_BIND%"=="" set "GUNICORN_BIND=0.0.0.0:8000"
if "%GUNICORN_VERSION%"=="" set "GUNICORN_VERSION=latest"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if exist "%LIBSCRIPT_HOME%\gunicorn\%GUNICORN_VERSION%\Scripts" (
    set "PATH=%LIBSCRIPT_HOME%\gunicorn\%GUNICORN_VERSION%\Scripts;%PATH%"
)
