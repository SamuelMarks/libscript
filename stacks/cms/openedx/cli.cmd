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
set "SCRIPT_DIR=%~dp0"

set "SUBCMD=%~1"

if "%SUBCMD%"=="user" (
    call "%SCRIPT_DIR%user.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="demo" (
    call "%SCRIPT_DIR%import_demo.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="dbshell" (
    call "%SCRIPT_DIR%dbshell.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="mongosh" (
    call "%SCRIPT_DIR%dbshell.cmd" mongo %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="redis-cli" (
    call "%SCRIPT_DIR%dbshell.cmd" redis %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="healthcheck" (
    call "%SCRIPT_DIR%healthcheck.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="health" (
    call "%SCRIPT_DIR%healthcheck.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="config" (
    call "%SCRIPT_DIR%config.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="backup" (
    call "%SCRIPT_DIR%backup.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="restore" (
    call "%SCRIPT_DIR%restore.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="workers" (
    call "%SCRIPT_DIR%workers.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="theme" (
    call "%SCRIPT_DIR%theme.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="xblock" (
    call "%SCRIPT_DIR%xblock.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="plugin" (
    call "%SCRIPT_DIR%xblock.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="upgrade" (
    call "%SCRIPT_DIR%upgrade.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="mfe" (
    call "%SCRIPT_DIR%mfe.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)

set "PACKAGE_NAME=openedx"
call "%~dp0..\..\..\_lib\_common\component_core.cmd" %*
