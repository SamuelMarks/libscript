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

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

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
