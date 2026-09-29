@echo off
:: # test_wordpress_dbaas.cmd
::
:: ## Overview
:: Functional test runner for WordPress DBaaS URL parser and configuration on Windows.
::
:: ## Usage
::   call tests\test_wordpress_dbaas.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%SCRIPT_DIR%\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

echo ==> Testing DBaaS Connection URL Parser on Windows...
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\parse_dbaas_url.cmd" "mysql://wpuser:p@ss!@db.example.com:3307/wp_db?ssl-ca=ca.pem" --eval

echo ==> All hosted DBaaS tests passed successfully on Windows!
exit /b 0
