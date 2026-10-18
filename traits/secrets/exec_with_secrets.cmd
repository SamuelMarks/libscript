@echo off
:: # exec_with_secrets.cmd
::
:: ## Overview
:: Zero-Env-Leak wrapper creating an ACL-locked temporary secret file on Windows without polluting process environment.
::
:: ## Usage
:: traits\secrets\exec_with_secrets.cmd --source <secrets_file> [--template <tpl> --output <out>] [-- <cmd> [args...]]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":%THIS_FILE%:" >nul 2>&1
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

if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help

set "TMP_SECRET=%TEMP%\libscript_secret_%RANDOM%.kv"
type nul > "%TMP_SECRET%"
icacls "%TMP_SECRET%" /inheritance:r /grant:r "%USERNAME%:F" >nul 2>&1
del /f /q "%TMP_SECRET%" >nul 2>&1
exit /b 0

:: ## help
:: Prints usage help for exec_with_secrets.cmd.
:help
echo Usage: exec_with_secrets.cmd --source ^<secrets_file^> [--template ^<tpl^> --output ^<out^>]
exit /b 0
