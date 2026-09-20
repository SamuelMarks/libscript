@echo off
:: # config.cmd
::
:: ## Overview
:: Configuration management engine for Open edX on Windows.
:: Provides get, set, list, generate, and validate operations for environment configurations.
::
:: ## Usage
::   call config.cmd get <key>
::   call config.cmd set <key> <value>
::   call config.cmd list
::   call config.cmd generate
::   call config.cmd validate
::   call config.cmd help
::
:: ## Exit Codes
::   0 - Success
::   1 - Configuration error or failure

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

set "CONF_DIR=%OPENEDX_INSTALL_DIR%\config"
set "LMS_CONF=%CONF_DIR%\lms.env.json"
set "CMS_CONF=%CONF_DIR%\cms.env.json"
set "SCHEMA_FILE=%~dp0vars.schema.json"
set "CONFIG_HELPER=%SCRIPT_DIR%config_helper.cmd"

set "CMD=%~1"
if "%CMD%"=="" goto show_help
if "%CMD%"=="help" goto show_help
if "%CMD%"=="--help" goto show_help
if "%CMD%"=="-h" goto show_help

if "%CMD%"=="get" goto do_get
if "%CMD%"=="set" goto do_set
if "%CMD%"=="list" goto do_list
if "%CMD%"=="generate" goto do_generate
if "%CMD%"=="validate" goto do_validate

echo [ERROR] Unknown config command: %CMD% >&2
goto show_help

:: ## do_get
:: Retrieves a configuration value by key.
:do_get
shift
set "KEY=%~1"
if "%KEY%"=="" (
    echo [ERROR] Key parameter is required. >&2
    exit /b 1
)
call "%CONFIG_HELPER%" get "%LMS_CONF%" "%KEY%"
exit /b %errorlevel%

:: ## do_set
:: Sets a configuration key-value pair in both LMS and CMS configurations.
:do_set
shift
set "KEY=%~1"
set "VAL=%~2"
if "%KEY%"=="" (
    echo [ERROR] Key parameter is required. >&2
    exit /b 1
)
call "%CONFIG_HELPER%" set "%LMS_CONF%" "%CMS_CONF%" "%KEY%" "%VAL%"
exit /b %errorlevel%

:: ## do_list
:: Outputs the current LMS JSON configuration.
:do_list
if exist "%LMS_CONF%" (
    type "%LMS_CONF%"
) else (
    echo [WARN] Configuration file not found at %LMS_CONF%.
)
exit /b 0

:: ## do_generate
:: Generates default Open edX configuration files.
:do_generate
call "%CONFIG_HELPER%" generate "%LMS_CONF%" "%CMS_CONF%"
exit /b %errorlevel%

:: ## do_validate
:: Validates the LMS configuration against the JSON schema.
:do_validate
call "%CONFIG_HELPER%" validate "%LMS_CONF%" "%SCHEMA_FILE%"
exit /b %errorlevel%

:: ## show_help
:: Displays configuration tool usage and options.
:show_help
echo Open edX Configuration Management Engine (Windows)
echo.
echo Usage:
echo   call config.cmd get ^<key^>
echo   call config.cmd set ^<key^> ^<value^>
echo   call config.cmd list
echo   call config.cmd generate
echo   call config.cmd validate
echo   call config.cmd help
exit /b 0
