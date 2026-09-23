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
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\.."
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
    jq --arg target_os "%TARGET_OS%" -n "{config: input, manifests: [inputs]}" "%CONFIG_FILE%" %MANIFESTS% | jq -L "%REPO_ROOT%_lib\utilities" -L "%SCRIPT_DIR%." --arg target_os "%TARGET_OS%" -r -f "%SCRIPT_DIR%resolve_stack.jq"
) else (
    for %%P in ("%OUTPUT_FILE%") do set "OUT_DIR=%%~dpP"
    if not exist "!OUT_DIR!" mkdir "!OUT_DIR!"
    jq --arg target_os "%TARGET_OS%" -n "{config: input, manifests: [inputs]}" "%CONFIG_FILE%" %MANIFESTS% | jq -L "%REPO_ROOT%_lib\utilities" -L "%SCRIPT_DIR%." --arg target_os "%TARGET_OS%" -r -f "%SCRIPT_DIR%resolve_stack.jq" > "%OUTPUT_FILE%"
    echo [INFO] Execution plan generated at %OUTPUT_FILE%
)

endlocal
