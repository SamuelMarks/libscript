@echo off
:: # create_installer_from_json.cmd
::
:: ## Overview
:: Generates deterministic POSIX (.sh) and Windows Batch (.cmd) stack installer packages from a JSON manifest using jq and resolve_stack.cmd.
::
:: ## Usage
:: create_installer_from_json.cmd -f <manifest.json> [-o <output_dir>] [-a <0|1>]

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

set "ALL_DEPS=0"
set "OUTPUT_FOLDER=!LIBSCRIPT_ROOT_DIR!\tmp"
set "FILENAME="
set "BASE=alpine:latest debian:bookworm-slim"

:: ## parse_args
:: Parses command-line arguments and populates configuration variables.
:parse_args
if "%~1"=="" goto :validate_args
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help
if /i "%~1"=="-a" (
    set "ALL_DEPS=%~2"
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="-b" (
    set "BASE=%~2"
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="-f" (
    set "FILENAME=%~2"
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="-o" (
    set "OUTPUT_FOLDER=%~2"
    shift
    shift
    goto :parse_args
)
shift
goto :parse_args

:: ## show_help
:: Displays command-line usage instructions and available options.
:show_help
echo Create install scripts from JSON.
echo   -a whether to install all dependencies (required AND optional)
echo   -b base images for docker
echo   -f filename
echo   -o output folder (defaults to .\tmp)
echo   -h show help text
exit /b 0

:: ## validate_args
:: Validates required command-line arguments and synthesizes installer scripts via jq.
:validate_args
if "!FILENAME!"=="" (
    call :show_help
    echo Error: JSON file must be specified with -f 1>&2
    exit /b 2
)
if not exist "!FILENAME!" (
    call :show_help
    echo Error: JSON file specified with -f must exist 1>&2
    exit /b 2
)

call :ensure_jq
if errorlevel 1 exit /b 1

if not exist "!OUTPUT_FOLDER!" mkdir "!OUTPUT_FOLDER!"
set "PLAN_OUT=!OUTPUT_FOLDER!\execution-plan.json"
call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\resolve_stack.cmd" "!FILENAME!" "!PLAN_OUT!"
if errorlevel 1 exit /b 1

set "APP_NAME=libscript-stack"
for /f "usebackq delims=" %%N in (`jq -r ".name // .profile_name // \"libscript-stack\"" "!FILENAME!"`) do set "APP_NAME=%%N"

set "INSTALL_CMD=!OUTPUT_FOLDER!\install_!APP_NAME!.cmd"
(
    echo @echo off
    echo setlocal EnableDelayedExpansion
    echo if "%%LIBSCRIPT_ROOT_DIR%%"=="" set "LIBSCRIPT_ROOT_DIR=!LIBSCRIPT_ROOT_DIR!"
    echo call "%%LIBSCRIPT_ROOT_DIR%%\_lib\orchestration\execute_plan.cmd" "%%~dp0execution-plan.json" %%*
) > "!INSTALL_CMD!"

echo [OK] Generated installer plan and scripts in !OUTPUT_FOLDER!
exit /b 0

:: ## ensure_jq
:: Bootstraps _lib\utilities\jq when jq is not already available on PATH.
:ensure_jq
where jq >nul 2>&1
if not errorlevel 1 exit /b 0
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" >nul 2>&1
where jq >nul 2>&1
if not errorlevel 1 exit /b 0
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install jq latest >nul 2>&1
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" >nul 2>&1
where jq >nul 2>&1
exit /b !ERRORLEVEL!
