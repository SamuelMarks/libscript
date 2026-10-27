@echo off
:: # setup_windows.cmd
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for rebar3 on Windows.
:: Ensures Erlang/OTP is available and installs the official rebar3 distribution.
::
:: ## Usage
:: Automatically invoked during libscript rebar3 installation on Windows.

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

where rebar3 >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local/rebar3"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "BIN_DIR=%USERPROFILE%\.local/bin"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

:: Ensure Erlang / escript is present
set "ESCRIPT_BIN="
where escript >nul 2>&1
if %errorlevel% equ 0 (
    set "ESCRIPT_BIN=escript"
) else (
    for /d %%E in ("%ProgramFiles%\Erlang*") do (
        if exist "%%E\bin\escript.exe" set "ESCRIPT_BIN=%%E\bin\escript.exe"
    )
)

if "%ESCRIPT_BIN%"=="" (
    echo Erlang OTP not detected. Installing via pkg_mgr...
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends Erlang.ErlangOTP
    for /d %%E in ("%ProgramFiles%\Erlang*") do (
        if exist "%%E\bin\escript.exe" set "ESCRIPT_BIN=%%E\bin\escript.exe"
    )
)

if "%ESCRIPT_BIN%"=="" (
    echo Error: Erlang / escript is required to run rebar3.
    exit /b 1
)

set "URL=https://github.com/erlang/rebar3/releases/download/3.27.0/rebar3"
set "REBAR_PATH=%DEST_DIR%/rebar3"

echo Downloading rebar3 from %URL%...
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%URL%" "%REBAR_PATH%"
if errorlevel 1 (
    echo Failed to download rebar3.
    exit /b 1
)

(
    echo @echo off
    echo "%ESCRIPT_BIN%" "%REBAR_PATH%" %%*
) > "%BIN_DIR%/rebar3.cmd"

if exist "%BIN_DIR%/rebar3.cmd" (
    echo rebar3 installed successfully to %BIN_DIR%.
    exit /b 0
)

exit /b 1
