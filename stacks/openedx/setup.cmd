@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

rem ## Overview
rem Open edX Native Deployment Script for Windows.
rem
rem ## Usage
rem setup.cmd

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"
:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop
:found_root

echo Installing Open edX system dependencies...
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install toolchains/git python nodejs

echo Installing Open edX databases and caches...
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install postgres
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install mongodb
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install redis
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install memcached
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install elasticsearch

echo Installing Open edX Web Server / Reverse Proxy...
if "%LIBSCRIPT_WEB_SERVER%"=="" set "LIBSCRIPT_WEB_SERVER=iis"
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install "%LIBSCRIPT_WEB_SERVER%"

echo Installing Application Server...
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install waitress

echo Open edX dependencies installed successfully.

set "PROXY_PROVISION=%LIBSCRIPT_ROOT_DIR%\_lib\web-servers\provision_proxy.cmd"
if exist "%PROXY_PROVISION%" (
    echo Provisioning Web Proxy...
)

exit /b 0
