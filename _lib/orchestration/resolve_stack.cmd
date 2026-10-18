@echo off
:: # resolve_stack.cmd
::
:: ## Overview
:: A portable dependency resolver and execution plan generator using jq on Windows.
:: Supports both traditional install.json application stacks and declarative os-config.json profiles.
:: Emits flat, topologically sorted execution-plan.json.
::
:: ## Usage
:: Run `resolve_stack.cmd <path_to_config.json> [output_plan.json]` to compute an execution sequence.

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


if "%~1"=="--help" (
    echo Usage: %~nx0 ^<path_to_config.json^> [output_plan.json]
    echo Resolves component dependencies and emits an execution plan.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 ^<path_to_config.json^> [output_plan.json]
    echo Resolves component dependencies and emits an execution plan.
    exit /b 0
)

if "%~1"=="" (
    echo [ERROR] Missing required configuration file argument.
    echo Usage: %~nx0 ^<path_to_config.json^> [output_plan.json]
    exit /b 1
)

set "CONFIG_FILE=%~1"
set "OUTPUT_FILE=%~2"
set "REPO_ROOT=!SCRIPT_DIR!..\.."
set "LIB_DIR=%REPO_ROOT%_lib"

if not exist "%CONFIG_FILE%" (
    echo [ERROR] Configuration file does not exist: %CONFIG_FILE%
    exit /b 1
)

if "%LIBSCRIPT_TARGET_OS%"=="" (
    set "TARGET_OS=windows"
) else (
    set "TARGET_OS=%LIBSCRIPT_TARGET_OS%"
)

where jq >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] jq is required but not installed.
    exit /b 1
)

REM Gather manifests into a single list
set "MANIFESTS="
for /R "%LIB_DIR%" %%F in (manifest.json) do (
    set "MANIFESTS=!MANIFESTS! "%%F""
)

if "%OUTPUT_FILE%"=="" (
    jq --arg target_os "%TARGET_OS%" -n "{config: input, manifests: [inputs]}" "%CONFIG_FILE%" %MANIFESTS% | jq -L "%REPO_ROOT%_lib\utilities" -L "!SCRIPT_DIR!." --arg target_os "%TARGET_OS%" -r -f "!SCRIPT_DIR!resolve_stack.jq"
) else (
    for %%P in ("%OUTPUT_FILE%") do set "OUT_DIR=%%~dpP"
    if not exist "!OUT_DIR!" mkdir "!OUT_DIR!"
    jq --arg target_os "%TARGET_OS%" -n "{config: input, manifests: [inputs]}" "%CONFIG_FILE%" %MANIFESTS% | jq -L "%REPO_ROOT%_lib\utilities" -L "!SCRIPT_DIR!." --arg target_os "%TARGET_OS%" -r -f "!SCRIPT_DIR!resolve_stack.jq" > "%OUTPUT_FILE%"
    echo [INFO] Execution plan generated at %OUTPUT_FILE%
)

endlocal
