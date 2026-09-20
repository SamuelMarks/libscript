@echo off
:: # healthcheck.cmd
::
:: ## Overview
:: Full-stack diagnostic and health probe module for Open edX on Windows.
:: Validates MySQL, MongoDB, Redis, Meilisearch, Celery, LMS HTTP, CMS HTTP, and SMTP listeners.
::
:: ## Usage
::   call healthcheck.cmd [--json]
::   call healthcheck.cmd help
::
:: ## Exit Codes
::   0 - All probes healthy
::   1 - One or more health checks failed

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%~dp0..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

if "%OPENEDX_INSTALL_DIR%"=="" (
    if defined LIBSCRIPT_HOME (
        set "OPENEDX_INSTALL_DIR=%LIBSCRIPT_HOME%\openedx"
    ) else (
        set "OPENEDX_INSTALL_DIR=%USERPROFILE%\.libscript\openedx"
    )
)

if "%LMS_HOST%"=="" set "LMS_HOST=127.0.0.1"
if "%LMS_PORT%"=="" set "LMS_PORT=8000"
if "%CMS_HOST%"=="" set "CMS_HOST=127.0.0.1"
if "%CMS_PORT%"=="" set "CMS_PORT=8001"
if "%MYSQL_HOST%"=="" set "MYSQL_HOST=127.0.0.1"
if "%MYSQL_PORT%"=="" set "MYSQL_PORT=3306"
if "%MONGODB_HOST%"=="" set "MONGODB_HOST=127.0.0.1"
if "%MONGODB_PORT%"=="" set "MONGODB_PORT=27017"
if "%REDIS_HOST%"=="" set "REDIS_HOST=127.0.0.1"
if "%REDIS_PORT%"=="" set "REDIS_PORT=6379"
if "%MEILISEARCH_HOST%"=="" set "MEILISEARCH_HOST=127.0.0.1"
if "%MEILISEARCH_PORT%"=="" set "MEILISEARCH_PORT=7700"
if "%SMTP_HOST%"=="" set "SMTP_HOST=127.0.0.1"
if "%SMTP_PORT%"=="" set "SMTP_PORT=25"

set "HEALTH_HELPER=%SCRIPT_DIR%health_helper.cmd"

set "ARG1=%~1"
if "%ARG1%"=="" goto run_probes
if "%ARG1%"=="--json" goto run_probes
if "%ARG1%"=="help" goto show_help
if "%ARG1%"=="--help" goto show_help
if "%ARG1%"=="-h" goto show_help

:: ## run_probes
:: Executes full-stack diagnostic health probes across all services.
:run_probes
set "JSON_OUTPUT=0"
if "%ARG1%"=="--json" set "JSON_OUTPUT=1"

call "%HEALTH_HELPER%" "%JSON_OUTPUT%" "%LMS_HOST%" "%LMS_PORT%" "%CMS_HOST%" "%CMS_PORT%" "%MYSQL_HOST%" "%MYSQL_PORT%" "%MONGODB_HOST%" "%MONGODB_PORT%" "%REDIS_HOST%" "%REDIS_PORT%" "%MEILISEARCH_HOST%" "%MEILISEARCH_PORT%" "%SMTP_HOST%" "%SMTP_PORT%"
exit /b %errorlevel%

:: ## show_help
:: Displays healthcheck utility command usage.
:show_help
echo Open edX Healthcheck Diagnostics CLI (Windows)
echo.
echo Usage:
echo   call healthcheck.cmd [--json]
echo   call healthcheck.cmd help
exit /b 0
