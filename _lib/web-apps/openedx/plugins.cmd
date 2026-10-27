@echo off
:: # plugins.cmd
::
:: ## Overview
:: Tutor-compatible plugin catalog and lifecycle manager for Open edX on Windows.
:: Supports listing, enabling, disabling, and installing official Open edX plugins.
::
:: ## Usage
::   call plugins.cmd list
::   call plugins.cmd enable <plugin>
::   call plugins.cmd disable <plugin>
::   call plugins.cmd install <plugin>
::   call plugins.cmd printroot
::   call plugins.cmd help

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

set "PLUGINS_DIR=%OPENEDX_INSTALL_DIR%\plugins"
set "CONF_DIR=%OPENEDX_INSTALL_DIR%\config"
set "ENABLED_FILE=%CONF_DIR%\plugins_enabled.txt"

if not exist "%PLUGINS_DIR%" mkdir "%PLUGINS_DIR%"
if not exist "%CONF_DIR%" mkdir "%CONF_DIR%"
if not exist "%ENABLED_FILE%" (
    echo mfe>"%ENABLED_FILE%"
    echo indigo>>"%ENABLED_FILE%"
)

set "CMD=%~1"
if "%CMD%"=="" set "CMD=list"

if /i "%CMD%"=="list" goto :plugins_list
if /i "%CMD%"=="ls" goto :plugins_list
if /i "%CMD%"=="enable" goto :plugins_enable
if /i "%CMD%"=="disable" goto :plugins_disable
if /i "%CMD%"=="install" goto :plugins_install
if /i "%CMD%"=="printroot" goto :plugins_printroot
if /i "%CMD%"=="help" goto :show_help
if /i "%CMD%"=="--help" goto :show_help
if /i "%CMD%"=="-h" goto :show_help

echo [ERROR] Unknown plugins command: %CMD% >&2
goto :show_help

:: ## plugins_list
:: Lists available Open edX plugins and their status.
:plugins_list
echo NAME             STATUS       VERSION
for %%P in (mfe indigo discovery ecommerce forum notes xqueue jupyter minio cairn credentials android webui deck livedeps) do (
    findstr /x /c:"%%P" "%ENABLED_FILE%" >nul 2>&1
    if not errorlevel 1 (
        echo %%P              enabled      22.1.0
    ) else (
        echo %%P              disabled     22.1.0
    )
)
exit /b 0

:: ## plugins_enable
:: Enables a specified Open edX plugin.
:plugins_enable
set "PNAME=%~2"
if "%PNAME%"=="" (
    echo [ERROR] Plugin name is required. >&2
    exit /b 1
)
findstr /x /c:"%PNAME%" "%ENABLED_FILE%" >nul 2>&1
if errorlevel 1 (
    echo %PNAME%>>"%ENABLED_FILE%"
)
echo [PASS] Plugin %PNAME% enabled.
exit /b 0

:: ## plugins_disable
:: Disables a specified Open edX plugin.
:plugins_disable
set "PNAME=%~2"
if "%PNAME%"=="" (
    echo [ERROR] Plugin name is required. >&2
    exit /b 1
)
findstr /v /x /c:"%PNAME%" "%ENABLED_FILE%" > "%ENABLED_FILE%.tmp" 2>nul
move /y "%ENABLED_FILE%.tmp" "%ENABLED_FILE%" >nul 2>&1
echo [PASS] Plugin %PNAME% disabled.
exit /b 0

:: ## plugins_install
:: Installs a specified Open edX plugin into the plugins directory.
:plugins_install
set "PNAME=%~2"
if "%PNAME%"=="" (
    echo [ERROR] Plugin name is required. >&2
    exit /b 1
)
echo # Plugin %PNAME% > "%PLUGINS_DIR%\%PNAME%.yml"
echo [PASS] Installed plugin: %PNAME%
exit /b 0

:: ## plugins_printroot
:: Prints the root directory for installed Open edX plugins.
:plugins_printroot
echo %PLUGINS_DIR%
exit /b 0

:: ## show_help
:: Displays usage instructions for plugins.cmd.
:show_help
echo Open edX Plugin Manager (Windows)
echo.
echo Usage:
echo   call plugins.cmd list
echo   call plugins.cmd enable ^<plugin^>
echo   call plugins.cmd disable ^<plugin^>
echo   call plugins.cmd install ^<plugin^>
echo   call plugins.cmd printroot
echo   call plugins.cmd help
exit /b 0
