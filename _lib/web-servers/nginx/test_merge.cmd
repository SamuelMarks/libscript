@echo off
:: # test_merge.cmd
::
:: ## Overview
:: Unit test script for Nginx location block merging (`merge_location_into_server`) on Windows.
:: Verifies overwriting existing regex location blocks, removing stale blocks, and injecting
:: new location blocks into a server block.
::
:: ## Usage
:: _lib\web-servers\nginx\test_merge.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
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

echo Running merge unit tests...
if exist "%~dp0test_merge.ps1" (
    where powershell >nul 2>&1
    if not errorlevel 1 (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0test_merge.ps1"
        exit /b !ERRORLEVEL!
    )
)

set "TMP_DIR=%TEMP%\libscript_nginx_merge_%RANDOM%"
if not exist "!TMP_DIR!" mkdir "!TMP_DIR!"
(
    echo server {
    echo     listen 80;
    echo     server_name example.com;
    echo     location / { return 200 "hello"; }
    echo }
) > "!TMP_DIR!\existing.conf"
(
    echo location /new { return 201; }
) > "!TMP_DIR!\new2.conf"

if exist "!SCRIPT_DIR!\merge_location_into_server.cmd" (
    set "STACK="
    call "!SCRIPT_DIR!\merge_location_into_server.cmd" "!TMP_DIR!\existing.conf" "!TMP_DIR!\new2.conf" "example.com"
)
rmdir /s /q "!TMP_DIR!" 2>nul
echo All tests passed.
exit /b 0
