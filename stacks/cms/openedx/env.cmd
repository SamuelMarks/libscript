@echo off
:: # env.cmd
::
:: ## Overview
:: Sets environment variables for Open edX on Windows.
::
:: ## Usage
:: Call or execute in the current command shell:
::   call env.cmd

set "THIS_FILE=%~f0"

if "%OPENEDX_VERSION%"=="" set "OPENEDX_VERSION=master"
if "%LMS_HOST%"=="" set "LMS_HOST=openedx.local"
if "%CMS_HOST%"=="" set "CMS_HOST=studio.openedx.local"
if "%LMS_PORT%"=="" set "LMS_PORT=8000"
if "%CMS_PORT%"=="" set "CMS_PORT=8001"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%OPENEDX_INSTALL_DIR%"=="" set "OPENEDX_INSTALL_DIR=%LIBSCRIPT_HOME%\openedx"
