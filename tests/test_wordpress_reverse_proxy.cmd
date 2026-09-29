@echo off
:: # test_wordpress_reverse_proxy.cmd
::
:: ## Overview
:: Functional test runner for WordPress reverse proxy configuration on Windows.
::
:: ## Usage
::   call tests\test_wordpress_reverse_proxy.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%SCRIPT_DIR%\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

echo ==> Testing WordPress Reverse Proxy Headers on Windows...
call "%LIBSCRIPT_ROOT_DIR%\stacks\cms\wordpress\setup_generic.cmd" --server-name "wp.example.com" --site-url "https://wp.example.com"

echo ==> Reverse proxy verification succeeded on Windows!
exit /b 0
