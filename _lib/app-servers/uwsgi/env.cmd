@echo off
:: # env.cmd
::
:: ## Overview
:: Sets environment variables for uWSGI on Windows.
::
:: ## Usage
:: Call or execute in the current command shell:
::   call env.cmd

set "THIS_FILE=%~f0"

if "%UWSGI_WORKERS%"=="" set "UWSGI_WORKERS=2"
if "%UWSGI_VERSION%"=="" set "UWSGI_VERSION=2.0.24"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if exist "%LIBSCRIPT_HOME%\uwsgi\%UWSGI_VERSION%\bin" (
    set "PATH=%LIBSCRIPT_HOME%\uwsgi\%UWSGI_VERSION%\bin;%PATH%"
)
