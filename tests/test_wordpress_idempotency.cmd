@echo off
:: # test_wordpress_idempotency.cmd
::
:: ## Overview
:: Two-pass idempotency verification test for WordPress 7.1.2 on Windows.
::
:: ## Usage
::   call tests\test_wordpress_idempotency.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%SCRIPT_DIR%\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "TMP_DIR=%TEMP%\wp_idem_%RANDOM%"
if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"

echo [INFO] Executing Windows Setup Pass 1...
call "%LIBSCRIPT_ROOT_DIR%\stacks\cms\wordpress\setup_generic.cmd" --wwwroot "%TMP_DIR%" --server-name "wordpress.local"
if not exist "%TMP_DIR%\wp-config.php" (
    echo [ERROR] Pass 1 failed to create wp-config.php >&2
    rd /s /q "%TMP_DIR%" >nul 2>&1
    exit /b 1
)

echo [INFO] Executing Windows Setup Pass 2...
call "%LIBSCRIPT_ROOT_DIR%\stacks\cms\wordpress\setup_generic.cmd" --wwwroot "%TMP_DIR%" --server-name "wordpress.local"

rd /s /q "%TMP_DIR%" >nul 2>&1
echo ==> Two-pass idempotency verification succeeded on Windows!
exit /b 0
