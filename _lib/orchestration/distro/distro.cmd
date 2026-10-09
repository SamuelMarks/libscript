@echo off
setlocal EnableDelayedExpansion
:: # distro.cmd
::
:: ## Overview
:: Unified distribution synthesis entrypoint on Windows, dispatching to
:: Debian, Alpine, and Red Hat style OS synthesis pipelines.
::
:: ## Usage
:: call _lib\orchestration\distro\distro.cmd <build-debian | build-alpine | build-redhat>

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
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

if not defined LIBSCRIPT_ROOT_DIR (
    for %%i in ("%SCRIPT_DIR%\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "ACTION=%~1"
if "%ACTION%"=="" goto show_help
shift

if /i "%ACTION%"=="build-debian" goto do_debian
if /i "%ACTION%"=="debian" goto do_debian
if /i "%ACTION%"=="build-alpine" goto do_alpine
if /i "%ACTION%"=="alpine" goto do_alpine
if /i "%ACTION%"=="build-redhat" goto do_redhat
if /i "%ACTION%"=="redhat" goto do_redhat

:show_help
echo Usage: distro.cmd ^<build-debian ^| build-alpine ^| build-redhat^> [options...]
echo Commands:
echo   build-debian   Synthesizes Debian-style distribution (.deb, apt, dpkg)
echo   build-alpine   Synthesizes Alpine-style distribution (.apk, apk-tools, openrc)
echo   build-redhat   Synthesizes Red Hat-style distribution (.rpm, dnf, rpmbuild)
exit /b 1

:do_debian
call "%SCRIPT_DIR%\build_debian.cmd" %*
exit /b %ERRORLEVEL%

:do_alpine
call "%SCRIPT_DIR%\build_alpine.cmd" %*
exit /b %ERRORLEVEL%

:do_redhat
call "%SCRIPT_DIR%\build_redhat.cmd" %*
exit /b %ERRORLEVEL%
