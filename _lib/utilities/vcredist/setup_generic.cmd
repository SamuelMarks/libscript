@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Windows setup for vcredist.
::
:: ## Usage
:: Managed by libscript.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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
if not "%ACTION%"=="install" exit /b 0

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
set "TARGET_DIR=%LIBSCRIPT_HOME%\vcredist\latest"

if exist "%TARGET_DIR%\bin\vcredist.installed" (
    echo [INFO] vcredist is already installed.
    exit /b 0
)

if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"

echo [INFO] Downloading VC++ Redistributable...
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "https://aka.ms/vs/17/release/vc_redist.arm64.exe" "%TEMP%\vc_redist.arm64.exe"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "https://aka.ms/vs/17/release/vc_redist.x64.exe" "%TEMP%\vc_redist.x64.exe"

echo [INFO] Installing VC++ Redistributable...
start /wait "" "%TEMP%\vc_redist.arm64.exe" /install /quiet /norestart
start /wait "" "%TEMP%\vc_redist.x64.exe" /install /quiet /norestart

echo done > "%TARGET_DIR%\bin\vcredist.installed"
exit /b 0
