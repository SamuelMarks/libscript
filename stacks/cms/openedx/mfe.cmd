@echo off
:: # mfe.cmd
::
:: ## Overview
:: Micro-Frontend (MFE) build, configuration, and delivery pipeline for Open edX on Windows.
:: Manages learning, authn, account, and course-authoring MFEs.
::
:: ## Usage
::   call mfe.cmd build <mfe_name> [--version <version>]
::   call mfe.cmd deploy <mfe_name> [--dest <path>]
::   call mfe.cmd list
::   call mfe.cmd help
::
:: ## Exit Codes
::   0 - Success
::   1 - Error

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%~dp0..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

if "%OPENEDX_INSTALL_DIR%"=="" (
    if defined LIBSCRIPT_HOME (
        set "OPENEDX_INSTALL_DIR=%LIBSCRIPT_HOME%\openedx"
    ) else (
        set "OPENEDX_INSTALL_DIR=%USERPROFILE%\.libscript\openedx"
    )
)

set "MFE_ROOT_DIR=%OPENEDX_INSTALL_DIR%\mfes"
set "MFE_DIST_DIR=%OPENEDX_INSTALL_DIR%\mfe_dist"
if not exist "%MFE_ROOT_DIR%" mkdir "%MFE_ROOT_DIR%"
if not exist "%MFE_DIST_DIR%" mkdir "%MFE_DIST_DIR%"

set "MFE_HELPER=%SCRIPT_DIR%mfe_helper.cmd"

set "CMD=%~1"
if "%CMD%"=="" goto show_help
if "%CMD%"=="help" goto show_help
if "%CMD%"=="--help" goto show_help
if "%CMD%"=="-h" goto show_help

if "%CMD%"=="build" goto do_build
if "%CMD%"=="deploy" goto do_deploy
if "%CMD%"=="list" goto do_list

echo [ERROR] Unknown mfe command: %CMD% >&2
goto show_help

:: ## do_build
:: Builds an Open edX Micro-Frontend asset bundle.
:do_build
shift
set "MFE_NAME=%~1"
if "%MFE_NAME%"=="" (
    echo [ERROR] MFE name required. >&2
    exit /b 1
)
shift
set "VERSION=master"
if "%~1"=="--version" (
    set "VERSION=%~2"
    shift
    shift
)

echo [INFO] Building MFE '%MFE_NAME%'...
call "%MFE_HELPER%" build "%MFE_ROOT_DIR%" "%MFE_NAME%" "%VERSION%"
exit /b %errorlevel%

:: ## do_deploy
:: Deploys an Open edX Micro-Frontend bundle to the web distribution directory.
:do_deploy
shift
set "MFE_NAME=%~1"
if "%MFE_NAME%"=="" (
    echo [ERROR] MFE name required. >&2
    exit /b 1
)
shift
set "DEST_PATH="
if "%~1"=="--dest" (
    set "DEST_PATH=%~2"
    shift
    shift
)

echo [INFO] Deploying MFE '%MFE_NAME%'...
call "%MFE_HELPER%" deploy "%MFE_ROOT_DIR%" "%MFE_DIST_DIR%" "%MFE_NAME%" "%DEST_PATH%"
exit /b %errorlevel%

:: ## do_list
:: Lists configured Micro-Frontends and their build/deployment status.
:do_list
echo ============================================================
call "%MFE_HELPER%" list "%MFE_ROOT_DIR%"
echo ============================================================
exit /b 0

:: ## show_help
:: Displays MFE CLI command usage.
:show_help
echo Open edX Micro-Frontend (MFE) Pipeline CLI (Windows)
echo.
echo Usage:
echo   call mfe.cmd build ^<mfe_name^> [--version ^<version^>]
echo   call mfe.cmd deploy ^<mfe_name^> [--dest ^<path^>]
echo   call mfe.cmd list
echo   call mfe.cmd help
exit /b 0
