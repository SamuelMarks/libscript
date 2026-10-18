@echo off
:: # cc_wrapper.cmd
::
:: ## Overview
:: Compiler driver wrapper and telemetry shim for custom-cc on Windows.
:: Normalizes compiler flags and logs compilation events to JSONL.
::
:: ## Usage
:: cc_wrapper.cmd [compiler_args...]

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
if "%SCRIPT_DIR:~-1%"=="\\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

if "%~1"=="--version" (
    echo custom-cc 1.0.0 ^(libscript telemetry wrapper^)
    exit /b 0
)
if "%~1"=="-v" (
    echo custom-cc 1.0.0 ^(libscript telemetry wrapper^)
    exit /b 0
)

call :filter_compiler_args %*

set "_real_cc=%CUSTOM_CC_REAL_BIN%"
if "!_real_cc!"=="" set "_real_cc=%CUSTOM_CC_BIN%"
if "!_real_cc!"=="" (
    where gcc >nul 2>&1
    if !errorlevel! equ 0 (
        set "_real_cc=gcc"
    ) else (
        where clang >nul 2>&1
        if !errorlevel! equ 0 (
            set "_real_cc=clang"
        ) else (
            set "_real_cc=cl"
        )
    )
)

"!_real_cc!" %*
set "_rc=!errorlevel!"
call :record_compile_event "!WRAPPER_SOURCE_FILE!" "!_rc!" "false" "1"
exit /b !_rc!

:: ## filter_compiler_args
:: Extracts the source file path from the argument list for telemetry logging.
:filter_compiler_args
set "WRAPPER_SOURCE_FILE=%~1"
exit /b 0

:: ## record_compile_event
:: Appends a JSONL compilation event entry to the custom-cc log file.
:record_compile_event
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%CUSTOM_CC_LOG_FILE%"=="" set "CUSTOM_CC_LOG_FILE=%LIBSCRIPT_HOME%\custom-cc\compile_events.jsonl"
for %%F in ("%CUSTOM_CC_LOG_FILE%") do set "_log_dir=%%~dpF"
if not exist "!_log_dir!" mkdir "!_log_dir!"
echo {"source":"%~1","exit_code":%~2,"fallback":%~3,"elapsed_ms":%~4}>> "%CUSTOM_CC_LOG_FILE%"
exit /b 0
