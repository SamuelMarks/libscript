@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

rem ## Overview
rem Abstracts reading logs for a given service on Windows.
rem
rem ## Usage
rem call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\logs_service.cmd" "%*" "postgresql" "C:\path\to\log.txt"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"
:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop
:found_root

set "ACTION=%~1"
set "SVC_NAME=%~2"
set "LOG_FILES=%~3"

if not "%LOG_FILES%"=="" (
    if exist "%LOG_FILES%" (
        if "%ACTION%"=="tail -f" (
            powershell -Command "Get-Content -Path '%LOG_FILES%' -Wait -Tail 100"
            exit /b 0
        ) else (
            powershell -Command "Get-Content -Path '%LOG_FILES%' -Tail 100"
            exit /b 0
        )
    )
)

rem Fallback to Windows Event Logs
if "%ACTION%"=="tail -f" (
    powershell -Command "Get-EventLog -LogName Application -Source '%SVC_NAME%' -Newest 100"
) else (
    powershell -Command "Get-EventLog -LogName Application -Source '%SVC_NAME%' -Newest 100"
)

exit /b 0
