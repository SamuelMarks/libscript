@echo off
:: LibScript Unified Logging Utility (Windows)

:: Levels: 0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR
if "%LIBSCRIPT_LOG_LEVEL%"=="" set "LIBSCRIPT_LOG_LEVEL=1"
if "%LIBSCRIPT_LOG_FORMAT%"=="" set "LIBSCRIPT_LOG_FORMAT=text"

goto :eof

:log_debug
call :_libscript_log_msg "DEBUG" 0 "%~1"
exit /b

:log_info
call :_libscript_log_msg "INFO" 1 "%~1"
exit /b

:log_success
call :_libscript_log_msg "SUCCESS" 2 "%~1"
exit /b

:log_warn
call :_libscript_log_msg "WARN" 3 "%~1"
exit /b

:log_error
call :_libscript_log_msg "ERROR" 4 "%~1"
exit /b

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
