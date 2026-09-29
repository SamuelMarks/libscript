@echo off
:: # test_wordpress_stack.cmd
::
:: ## Overview
:: Functional test runner for WordPress 7.1.2 management tools on Windows.
::
:: ## Usage
::   call tests\test_wordpress_stack.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%SCRIPT_DIR%\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "WP_DIR=%LIBSCRIPT_ROOT_DIR%\stacks\cms\wordpress"

echo ==> Testing WordPress CLI Router on Windows...
call "%WP_DIR%\cli.cmd" help
if errorlevel 1 exit /b 1

echo ==> Testing WordPress Database Console on Windows...
call "%WP_DIR%\dbshell.cmd" help
if errorlevel 1 exit /b 1

echo ==> Testing WordPress Config Engine on Windows...
call "%WP_DIR%\config.cmd" help
if errorlevel 1 exit /b 1

echo ==> Testing WordPress User Management on Windows...
call "%WP_DIR%\user.cmd" help
if errorlevel 1 exit /b 1

echo ==> Testing WordPress Cron Scheduler on Windows...
call "%WP_DIR%\cron.cmd" help
if errorlevel 1 exit /b 1

echo ==> All WordPress tools verified successfully on Windows!
exit /b 0
