@echo off
:: # config.cmd
::
:: ## Overview
:: Configuration management engine for Open edX on Windows.
:: Provides get, set, list, generate, save, printvalue, printroot, patches, and validate
:: operations for environment configurations with full Tutor `config` CLI parity.
::
:: ## Usage
::   call config.cmd [get|set|list|generate|save|printvalue|printroot|patches|validate|help] [options]
::
:: ## Exit Codes
::   0 - Operation succeeded
::   1 - Validation or execution error

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

if "!LIBSCRIPT_ROOT_DIR!"=="" (
    for %%i in ("%~dp0..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

if "!OPENEDX_INSTALL_DIR!"=="" (
    if exist "%ProgramData%\OpenEdX\install_dir.txt" (
        set /p OPENEDX_INSTALL_DIR=<"%ProgramData%\OpenEdX\install_dir.txt"
    ) else if defined LIBSCRIPT_HOME (
        set "OPENEDX_INSTALL_DIR=%LIBSCRIPT_HOME%\openedx"
    ) else (
        set "OPENEDX_INSTALL_DIR=%USERPROFILE%\.libscript\openedx"
    )
)
if "!OPENEDX_INSTALL_DIR:~-1!"==" " set "OPENEDX_INSTALL_DIR=!OPENEDX_INSTALL_DIR:~0,-1!"
if "!OPENEDX_INSTALL_DIR:~-1!"=="\" set "OPENEDX_INSTALL_DIR=!OPENEDX_INSTALL_DIR:~0,-1!"

set "CONF_DIR=!OPENEDX_INSTALL_DIR!\config"
set "LMS_CONF=!CONF_DIR!\lms.env.json"
set "CMS_CONF=!CONF_DIR!\cms.env.json"
set "SCHEMA_FILE=%~dp0vars.schema.json"

set "CMD=%~1"
if "%CMD%"=="" goto show_help
if "%CMD%"=="help" goto show_help
if "%CMD%"=="--help" goto show_help
if "%CMD%"=="-h" goto show_help

if /i "%CMD%"=="get" goto do_get
if /i "%CMD%"=="printvalue" goto do_get
if /i "%CMD%"=="set" goto do_set
if /i "%CMD%"=="list" goto do_list
if /i "%CMD%"=="generate" goto do_generate
if /i "%CMD%"=="save" goto do_generate
if /i "%CMD%"=="printroot" goto do_printroot
if /i "%CMD%"=="patches" goto do_patches
if /i "%CMD%"=="validate" goto do_validate

echo [ERROR] Unknown config command: %CMD% >&2
goto show_help

:: ## ensure_conf
:: Ensures config directory and baseline config files exist.
:ensure_conf
if not exist "%CONF_DIR%" mkdir "%CONF_DIR%"
if not exist "%LMS_CONF%" call :do_generate >nul 2>nul
exit /b 0

:: ## do_get
:: Retrieves a configuration key value.
:do_get
call :ensure_conf
set "KEY=%~2"
if "%KEY%"=="" (
    echo [ERROR] Key parameter is required. >&2
    exit /b 1
)
call "%~dp0config_helper.cmd" get "%LMS_CONF%" "%KEY%"
if errorlevel 1 exit /b 1
exit /b 0

:: ## do_set
:: Sets a configuration key value.
:do_set
call :ensure_conf
set "KEY=%~2"
set "VAL=%~3"
if "%KEY%"=="" (
    echo [ERROR] Key parameter is required. >&2
    exit /b 1
)
call "%~dp0config_helper.cmd" set "%LMS_CONF%" "%CMS_CONF%" "%KEY%" "%VAL%"
if errorlevel 1 exit /b 1
exit /b 0

:: ## do_list
:: Prints the full LMS configuration file.
:do_list
call :ensure_conf
if exist "%LMS_CONF%" (
    type "%LMS_CONF%"
    echo.
) else (
    echo [WARN] Configuration file not found.
)
exit /b 0

:: ## do_generate
:: Generates baseline LMS and CMS JSON configurations.
:do_generate
if not exist "%CONF_DIR%" mkdir "%CONF_DIR%"
call "%~dp0config_helper.cmd" generate "%LMS_CONF%" "%CMS_CONF%"
if errorlevel 1 exit /b 1
exit /b 0

:: ## do_printroot
:: Prints the root Open edX installation directory.
:do_printroot
echo %OPENEDX_INSTALL_DIR%
exit /b 0

:: ## do_patches
:: Lists or displays Tutor-compatible patch slots.
:do_patches
set "SUB=%~2"
if "%SUB%"=="" set "SUB=list"
if /i "%SUB%"=="list" (
    for %%S in (openedx-common-settings openedx-lms-production-settings openedx-cms-production-settings openedx-lms-development-settings openedx-cms-development-settings lms-env cms-env openedx-auth caddyfile) do (
        echo %%S
    )
    exit /b 0
)
if /i "%SUB%"=="show" (
    call :ensure_conf
    call "%~dp0config_helper.cmd" get "%LMS_CONF%" "PATCHES.%~3"
    exit /b 0
)
echo [ERROR] Unknown patches subcommand: %SUB% >&2
exit /b 1

:: ## do_validate
:: Validates configuration JSON syntax and schema.
:do_validate
call :ensure_conf
echo [INFO] Validating %LMS_CONF%...
call "%~dp0config_helper.cmd" validate "%LMS_CONF%" "%SCHEMA_FILE%"
if errorlevel 1 exit /b 1
exit /b 0

:: ## show_help
:: Displays configuration CLI usage instructions.
:show_help
echo Open edX Configuration Management Engine (Windows)
echo.
echo Usage:
echo   call config.cmd get ^<key^>
echo   call config.cmd set ^<key^> ^<value^>
echo   call config.cmd list
echo   call config.cmd generate
echo   call config.cmd save
echo   call config.cmd printvalue ^<key^>
echo   call config.cmd printroot
echo   call config.cmd patches [list^|show ^<name^>]
echo   call config.cmd validate
echo   call config.cmd help
exit /b 0
