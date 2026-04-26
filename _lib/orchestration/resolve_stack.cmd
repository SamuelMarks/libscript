@echo off
setlocal enabledelayedexpansion

if "%~1"=="--help" (
    echo Usage: %0 [OPTIONS]
    echo See script source or documentation for more details.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %0 [OPTIONS]
    echo See script source or documentation for more details.
    exit /b 0
)


REM resolve_stack.cmd
REM A portable wrapper for the SAT/Constraint solver using jq on Windows.
REM Usage: scripts\resolve_stack.cmd <path_to_install.json>

if "%~1"=="" (
    echo Usage: %0 ^<path_to_install.json^>
    exit /b 1
)

set "INSTALL_JSON=%~1"
set "SCRIPT_DIR=%~dp0"
set "LIB_DIR=%SCRIPT_DIR%..\_lib"

REM Default TARGET_OS to windows unless overridden
if "%LIBSCRIPT_TARGET_OS%"=="" (
    set "TARGET_OS=windows"
) else (
    set "TARGET_OS=%LIBSCRIPT_TARGET_OS%"
)

where jq >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: jq is required but not installed.
    exit /b 1
)

REM Gather manifests into a single JSON array structure inline.
set "MANIFESTS="
for /R "%LIB_DIR%" %%F in (manifest.json) do (
    set "MANIFESTS=!MANIFESTS! "%%F""
)

REM Run the jq resolution engine
jq --arg target_os "%TARGET_OS%" -n "{install: input, manifests: [inputs]}" "%INSTALL_JSON%" %MANIFESTS% | jq -L "%SCRIPT_DIR%." --arg target_os "%TARGET_OS%" -r -f "%SCRIPT_DIR%resolve_stack.jq"

endlocal
