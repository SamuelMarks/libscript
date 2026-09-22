@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface dispatcher for the Open edX stack on Windows.
:: Routes commands to submodules or standard LibScript component core.
::
:: ## Usage
::   call cli.cmd <subcommand> [args...]
::   call cli.cmd help

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
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%SCRIPT_DIR%\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "SUBCMD=%~1"

if "%SUBCMD%"=="start" (
    call "%SCRIPT_DIR%\service.cmd" start %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="stop" (
    call "%SCRIPT_DIR%\service.cmd" stop %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="restart" (
    call "%SCRIPT_DIR%\service.cmd" restart %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="status" (
    call "%SCRIPT_DIR%\service.cmd" status %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="lms" (
    call "%SCRIPT_DIR%\service.cmd" lms %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="studio" (
    call "%SCRIPT_DIR%\service.cmd" studio %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="cms" (
    call "%SCRIPT_DIR%\service.cmd" studio %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="user" (
    call "%SCRIPT_DIR%\user.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="demo" (
    call "%SCRIPT_DIR%\import_demo.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="dbshell" (
    call "%SCRIPT_DIR%\dbshell.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="mongosh" (
    call "%SCRIPT_DIR%\dbshell.cmd" mongo %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="redis-cli" (
    call "%SCRIPT_DIR%\dbshell.cmd" redis %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="healthcheck" (
    call "%SCRIPT_DIR%\healthcheck.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="health" (
    call "%SCRIPT_DIR%\healthcheck.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="config" (
    call "%SCRIPT_DIR%\config.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="backup" (
    call "%SCRIPT_DIR%\backup.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="restore" (
    call "%SCRIPT_DIR%\restore.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="workers" (
    call "%SCRIPT_DIR%\workers.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="theme" (
    call "%SCRIPT_DIR%\theme.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="xblock" (
    call "%SCRIPT_DIR%\xblock.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="plugin" (
    call "%SCRIPT_DIR%\xblock.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="upgrade" (
    call "%SCRIPT_DIR%\upgrade.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="mfe" (
    call "%SCRIPT_DIR%\mfe.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)

set "PACKAGE_NAME=openedx"
if exist "%LIBSCRIPT_ROOT_DIR%\_lib\_common\component_core.cmd" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\component_core.cmd" %*
    exit /b %errorlevel%
)
if exist "%SCRIPT_DIR%\..\..\..\_lib\_common\component_core.cmd" (
    call "%SCRIPT_DIR%\..\..\..\_lib\_common\component_core.cmd" %*
    exit /b %errorlevel%
)
if exist "%SCRIPT_DIR%\..\..\..\libscript\_lib\_common\component_core.cmd" (
    call "%SCRIPT_DIR%\..\..\..\libscript\_lib\_common\component_core.cmd" %*
    exit /b %errorlevel%
)
echo [ERROR] component_core.cmd not found >&2
exit /b 1
