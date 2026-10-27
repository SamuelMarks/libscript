@echo off
:: # assemble.cmd
::
:: ## Overview
:: Orchestrates illumos distribution synthesis from a JSON profile specification
:: on Windows host environments.
::
:: ## Usage
:: assemble.cmd [profile_json_path] [target_sysroot]

setlocal EnableDelayedExpansion
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


if "%~1"=="--help" (
    echo Usage: %~nx0 [profile_json_path] [target_sysroot]
    echo Orchestrates illumos distribution assembly.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [profile_json_path] [target_sysroot]
    echo Orchestrates illumos distribution assembly.
    exit /b 0
)

set "REPO_ROOT=!SCRIPT_DIR!\..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "PROFILE=%~1"
if "%PROFILE%"=="" set "PROFILE=%REPO_ROOT%\profiles\illumos\minimal-server.json"
set "SYSROOT=%~2"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\illumos-sysroot"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\assembled.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"

if exist "%STAMP_FILE%" (
    echo [SKIP]     illumos distribution already assembled in %SYSROOT%
    exit /b 0
)

echo [ASSEMBLE] Synthesizing illumos distribution using profile: %PROFILE%...

call "!SCRIPT_DIR!\base.cmd" "%SYSROOT%" "r151048" "amd64"
call "!SCRIPT_DIR!\zfs.cmd" "%SYSROOT%" "rpool" "lz4"
call "!SCRIPT_DIR!\config.cmd" "%SYSROOT%" "illumos-distro" "true"
call "!SCRIPT_DIR!\pkg.cmd" "%SYSROOT%" "ips" "https://pkg.omnios.org/r151048/core"
call "!SCRIPT_DIR!\users.cmd" "%SYSROOT%" "vagrant"
call "!SCRIPT_DIR!\init.cmd" "%SYSROOT%" "smf" "svc:/network/ssh:default,svc:/system/cron:default" "svc:/milestone/multi-user-server:default"
call "!SCRIPT_DIR!\display.cmd" "%SYSROOT%" "none" "none"
call "!SCRIPT_DIR!\desktop.cmd" "%SYSROOT%" "none" "vagrant"
call "!SCRIPT_DIR!\dm.cmd" "%SYSROOT%" "none" ""
call "!SCRIPT_DIR!\audio.cmd" "%SYSROOT%" "none"

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       illumos distribution assembly complete.
exit /b 0
