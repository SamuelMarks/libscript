@echo off
:: # log.cmd
setlocal EnableDelayedExpansion
:: # LibScript Logging Module (Windows Batch)
::
:: ## Overview
:: This module provides standardized logging functions for Windows.
::
:: ## Usage
:: ```batch
:: call "%LIBSCRIPT_ROOT_DIR%\\_lib\\_common\\log.cmd" :log_info "Message"
:: ```

:: LibScript Unified Logging Utility (Windows)

:: Levels: 0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR
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
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

if "%LIBSCRIPT_LOG_LEVEL%"=="" set "LIBSCRIPT_LOG_LEVEL=1"
if "%LIBSCRIPT_LOG_FORMAT%"=="" set "LIBSCRIPT_LOG_FORMAT=text"

goto :eof

:: ## log_debug
:: Logs a debug-level diagnostic message.
:log_debug
call :_libscript_log_msg "DEBUG" 0 "%~1"
exit /b

:: ## log_info
:: Logs an informational status message.
:log_info
call :_libscript_log_msg "INFO" 1 "%~1"
exit /b

:: ## log_success
:: Logs a success confirmation message.
:log_success
call :_libscript_log_msg "SUCCESS" 2 "%~1"
exit /b

:: ## log_warn
:: Logs a warning message to standard error.
:log_warn
call :_libscript_log_msg "WARN" 3 "%~1"
exit /b

:: ## log_error
:: Logs an error message to standard error.
:log_error
call :_libscript_log_msg "ERROR" 4 "%~1"
exit /b

:: ## _libscript_log_msg
:: Formats and emits a timestamped log message at the specified severity level.
:_libscript_log_msg
set "level_name=%~1"
set "level_num=%~2"
set "msg=%~3"

if !level_num! LSS !LIBSCRIPT_LOG_LEVEL! exit /b

:: Standard timestamp ISO-8601-like
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do set "ts_date=%%c-%%a-%%b"
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set "ts_time=%%a:%%b"
set "timestamp=!ts_date!T!ts_time!"

if /i "%LIBSCRIPT_LOG_FORMAT%"=="json" (
    set "clean_msg=!msg:"=\"!"
    set "json_out={"timestamp":"!timestamp!","level":"!level_name!","message":"!clean_msg!"}"
    
    if defined LIBSCRIPT_LOG_FILE echo !json_out!>> "%LIBSCRIPT_LOG_FILE%"
    echo !json_out!
) else (
    set "text_out=[!level_name!] !msg!"
    if defined LIBSCRIPT_LOG_FILE echo !timestamp! !text_out!>> "%LIBSCRIPT_LOG_FILE%"
    echo !text_out! 1>&2
)
exit /b
