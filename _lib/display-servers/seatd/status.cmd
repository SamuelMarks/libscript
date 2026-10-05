@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2^>^&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" ^>^&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

rem ## Overview
rem Status check for display-servers/seatd.
rem
rem ## Usage
rem status.cmd

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

if exist "%SCRIPT_DIR%\test.cmd" (
  call "%SCRIPT_DIR%\test.cmd" %*
)
exit /b !ERRORLEVEL!
