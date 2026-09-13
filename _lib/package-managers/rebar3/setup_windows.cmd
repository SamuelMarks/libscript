@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for rebar3 on Windows.
:: Ensures Erlang/OTP is available and installs the official rebar3 distribution.
::
:: ## Usage
:: Automatically invoked during libscript rebar3 installation on Windows.

set "THIS_FILE=%~f0"

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
    echo Erlang OTP not detected. Installing via winget...
    winget install --id Erlang.ErlangOTP --silent --accept-package-agreements --accept-source-agreements
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
curl.exe -sSL "%URL%" -o "%REBAR_PATH%"
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
