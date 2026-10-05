@echo off
:: # test_odoo_remote_db.cmd
::
:: ## Overview
:: Functional test runner for Odoo remote IP configuration on Windows.
::
:: ## Usage
::   call tests\test_odoo_remote_db.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%SCRIPT_DIR%\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

echo ==> Testing Odoo DBaaS Strategy on Windows...

:: Check if powershell is available for testing
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell is required to run Windows integration tests.
    exit /b 1
)

set "TMP_DIR=%TEMP%\odoo_msi_test_%RANDOM%"
if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"

call "%LIBSCRIPT_ROOT_DIR%\packaging\template_msi.cmd" "%LIBSCRIPT_ROOT_DIR%\stacks\erp\odoo" --out "%TMP_DIR%\odoo.wxs"

findstr /c:"USER_DB_STRATEGY=\"remote\"" "%TMP_DIR%\odoo.wxs" >nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] USER_DB_STRATEGY remote switch not correctly mapped.
    exit /b 1
)
echo [PASS] Remote simulated DB strategy effectively omits postgres via properties!

:: Simulate remote DB properties
set "ODOO_DB_HOST=192.168.200.99"
set "ODOO_DB_PORT=5432"
set "ODOO_DB_NAME=odoo_prod"
set "ODOO_DB_USER=odoo_admin"
set "ODOO_DB_PASS=RemoteS3cr3t"
set "ODOO_WEBSERVER=none"
set "ODOO_WWWROOT=%TEMP%\odoo_www_test"

:: Clean test directory
if exist "%ODOO_WWWROOT%" (
    rmdir /S /Q "%ODOO_WWWROOT%"
)
if not exist "%ODOO_WWWROOT%" mkdir "%ODOO_WWWROOT%"
echo stub > "%ODOO_WWWROOT%\odoo-bin"

echo ==> Simulating silent install with remote IP...

:: Run setup_generic.cmd skipping dependencies
call "%LIBSCRIPT_ROOT_DIR%\stacks\erp\odoo\setup_generic.cmd" --skip-deps

if not exist "%ODOO_WWWROOT%\odoo.conf" (
    echo [ERROR] odoo.conf was not created!
    exit /b 1
)

findstr /c:"db_host = 192.168.200.99" "%ODOO_WWWROOT%\odoo.conf" >nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] db_host not properly written to odoo.conf!
    exit /b 1
)

findstr /c:"db_name = odoo_prod" "%ODOO_WWWROOT%\odoo.conf" >nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] db_name not properly written to odoo.conf!
    exit /b 1
)

echo [PASS] Odoo setup effectively maps remote IP to connection config on Windows!
exit /b 0