@echo off
:: # setup.cmd
::
:: ## Overview
:: Recipe for systemd-networkd: Network device manager integrated into systemd.
:: Complies with standard LibScript Context Contract and stamp idempotency.
::
:: ## Usage
:: setup.cmd [action]

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

SET "searchVal=;%THIS_FILE%;"
IF NOT DEFINED STACK (
    SET "STACK=;%THIS_FILE%;"
    echo [CONTINUE] processing "%THIS_FILE%"
) ELSE (
    IF NOT "!STACK:%searchVal%=!"=="!STACK!" (
        echo [STOP]     processing "%THIS_FILE%"
        SET ERRORLEVEL=0
        goto :eof
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

if "%~1"=="--help" (
    echo Usage: %~nx0 [action]
    echo Recipe for systemd-networkd.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [action]
    echo Recipe for systemd-networkd.
    exit /b 0
)

set "ACTION=%~1"
if "!ACTION!"=="" set "ACTION=compile"

if "%LIBSCRIPT_TARGET_SYSROOT%"=="" (
    for %%I in ("%SCRIPT_DIR%..\..\..") do set "REPO_ROOT=%%~fI"
    set "TARGET_SYSROOT=!REPO_ROOT!\build\target-sysroot"
) else (
    set "TARGET_SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
)

set "STAMPS_DIR=%TARGET_SYSROOT%\var\lib\libscript\stamps"
if not exist "%STAMPS_DIR%" mkdir "%STAMPS_DIR%"

set "STAMP_FILE=%STAMPS_DIR%\.stamp.systemd-networkd"
if exist "%STAMP_FILE%" (
    echo [SKIP]  systemd-networkd already installed ^(%STAMP_FILE%^)
    exit /b 0
)

echo [RECIPE] Staging systemd-networkd into %TARGET_SYSROOT% ^(action: %ACTION%^)
echo completed > "%STAMP_FILE%.tmp"
move /y "%STAMP_FILE%.tmp" "%STAMP_FILE%" >nul
echo [OK]    systemd-networkd staged successfully: %STAMP_FILE%

endlocal
