@echo off
:: # mounts.cmd
::
:: ## Overview
:: Host directory bind-mount manager for Open edX on Windows (Tutor `mounts` parity).
:: Allows linking local host directories into the Docker-free Open edX environment.
::
:: ## Usage
::   call mounts.cmd add <mount_spec>
::   call mounts.cmd remove <mount_spec>
::   call mounts.cmd list
::   call mounts.cmd clear
::   call mounts.cmd help

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

if "%OPENEDX_INSTALL_DIR%"=="" (
    if defined LIBSCRIPT_HOME (
        set "OPENEDX_INSTALL_DIR=%LIBSCRIPT_HOME%\openedx"
    ) else (
        set "OPENEDX_INSTALL_DIR=%USERPROFILE%\.libscript\openedx"
    )
)

set "MOUNTS_DIR=%OPENEDX_INSTALL_DIR%\mounts"
set "CONF_DIR=%OPENEDX_INSTALL_DIR%\config"
set "MOUNTS_FILE=%CONF_DIR%\mounts.txt"

set "CMD=%~1"
if "%CMD%"=="" set "CMD=list"

if /i "%CMD%"=="add" goto :mounts_add
if /i "%CMD%"=="remove" goto :mounts_remove
if /i "%CMD%"=="rm" goto :mounts_remove
if /i "%CMD%"=="list" goto :mounts_list
if /i "%CMD%"=="ls" goto :mounts_list
if /i "%CMD%"=="clear" goto :mounts_clear
if /i "%CMD%"=="help" goto :show_help
if /i "%CMD%"=="--help" goto :show_help
if /i "%CMD%"=="-h" goto :show_help

echo [ERROR] Unknown mounts command: %CMD% >&2
goto :show_help

:: ## mounts_add
:: Registers a local directory mount in mounts.txt.
:mounts_add
set "SPEC=%~2"
if "%SPEC%"=="" (
    echo [ERROR] Mount specification is required. >&2
    exit /b 1
)
if not exist "%MOUNTS_DIR%" mkdir "%MOUNTS_DIR%"
if not exist "%CONF_DIR%" mkdir "%CONF_DIR%"
if exist "%MOUNTS_FILE%" (
    findstr /x /c:"%SPEC%" "%MOUNTS_FILE%" >nul 2>&1
    if errorlevel 1 (
        echo %SPEC%>>"%MOUNTS_FILE%"
    )
) else (
    echo %SPEC%>"%MOUNTS_FILE%"
)
echo [PASS] Added mount: %SPEC%
exit /b 0

:: ## mounts_remove
:: Removes a mount specification from mounts.txt.
:mounts_remove
set "SPEC=%~2"
if "%SPEC%"=="" (
    echo [ERROR] Mount specification is required. >&2
    exit /b 1
)
if exist "%MOUNTS_FILE%" (
    findstr /v /x /c:"%SPEC%" "%MOUNTS_FILE%" > "%MOUNTS_FILE%.tmp" 2>nul
    move /y "%MOUNTS_FILE%.tmp" "%MOUNTS_FILE%" >nul 2>&1
)
echo [PASS] Removed mount: %SPEC%
exit /b 0

:: ## mounts_list
:: Lists all configured directory mounts.
:mounts_list
if exist "%MOUNTS_FILE%" (
    type "%MOUNTS_FILE%"
) else (
    echo [INFO] No mounts currently configured.
)
exit /b 0

:: ## mounts_clear
:: Clears all configured directory mounts.
:mounts_clear
if exist "%MOUNTS_FILE%" del /f /q "%MOUNTS_FILE%"
if exist "%MOUNTS_DIR%" rmdir /s /q "%MOUNTS_DIR%"
if not exist "%MOUNTS_DIR%" mkdir "%MOUNTS_DIR%"
echo [PASS] Cleared all mounts.
exit /b 0

:: ## show_help
:: Displays usage instructions for mounts.cmd.
:show_help
echo Open edX Host Directory Mounts Manager (Windows)
echo.
echo Usage:
echo   call mounts.cmd add ^<mount_spec^>
echo   call mounts.cmd remove ^<mount_spec^>
echo   call mounts.cmd list
echo   call mounts.cmd clear
echo   call mounts.cmd help
exit /b 0
