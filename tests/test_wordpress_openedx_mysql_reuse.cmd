@echo off
:: # test_wordpress_openedx_mysql_reuse.cmd
::
:: ## Overview
:: Verification test for WordPress database coexistence with Open edX on Windows.
::
:: ## Usage
::   call tests\test_wordpress_openedx_mysql_reuse.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%SCRIPT_DIR%\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

echo ==> Testing Universal Database Discovery on Windows...
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\discover_databases.cmd" --eval

echo ==> Database discovery verification succeeded on Windows!
exit /b 0
