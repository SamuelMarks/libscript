@echo off
:: # test_wordpress_genuine.cmd
setlocal EnableDelayedExpansion

:: ## Overview
:: Tests genuine WordPress PHP execution by sending a request to the installer.
::
:: ## Usage
:: tests\test_wordpress_genuine.cmd

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
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

echo [INFO] Testing genuine WordPress PHP execution...
powershell -NoProfile -Command "$res = Invoke-WebRequest -Uri 'http://localhost:80/wp-admin/install.php' -UseBasicParsing; if ($res.StatusCode -ne 200) { exit 1 }"
if errorlevel 1 (
  echo [ERROR] WordPress install.php did not return 200 OK. >&2
  exit /b 1
)
echo [PASS] Genuine WordPress execution confirmed.
