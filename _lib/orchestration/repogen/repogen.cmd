@echo off
setlocal EnableDelayedExpansion
:: # repogen.cmd
::
:: ## Overview
:: Universal package repository generation and hosting engine on Windows for
:: Debian (APT), Alpine (APK), and Red Hat (RPM/YUM) distribution archives.
::
:: ## Usage
:: call _lib\orchestration\repogen\repogen.cmd [--all | --apk | --deb | --rpm]

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
    for %%i in ("%SCRIPT_DIR%\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "REPO_BASE=%LIBSCRIPT_ROOT_DIR%\build\packages"
set "ACTION=all"

:parse_loop
if "%~1"=="" goto run_gen
if /i "%~1"=="--apk" ( set "ACTION=apk" & shift & goto parse_loop )
if /i "%~1"=="--deb" ( set "ACTION=deb" & shift & goto parse_loop )
if /i "%~1"=="--rpm" ( set "ACTION=rpm" & shift & goto parse_loop )
if /i "%~1"=="--all" ( set "ACTION=all" & shift & goto parse_loop )
if /i "%~1"=="repogen" ( shift & goto parse_loop )
set "REPO_BASE=%~1"
shift
goto parse_loop

:run_gen
if not exist "%REPO_BASE%\apk" mkdir "%REPO_BASE%\apk"
if not exist "%REPO_BASE%\deb" mkdir "%REPO_BASE%\deb"
if not exist "%REPO_BASE%\rpm" mkdir "%REPO_BASE%\rpm"

echo [REPOGEN] Running repository generator for mode: %ACTION%...

if /i "%ACTION%"=="all" goto do_all
if /i "%ACTION%"=="apk" goto do_apk
if /i "%ACTION%"=="deb" goto do_deb
if /i "%ACTION%"=="rpm" goto do_rpm

:do_all
call "%SCRIPT_DIR%\apk_index.cmd" "%REPO_BASE%\apk"
call "%SCRIPT_DIR%\deb_index.cmd" "%REPO_BASE%\deb"
call "%SCRIPT_DIR%\rpm_index.cmd" "%REPO_BASE%\rpm"
goto finish

:do_apk
call "%SCRIPT_DIR%\apk_index.cmd" "%REPO_BASE%\apk"
goto finish

:do_deb
call "%SCRIPT_DIR%\deb_index.cmd" "%REPO_BASE%\deb"
goto finish

:do_rpm
call "%SCRIPT_DIR%\rpm_index.cmd" "%REPO_BASE%\rpm"
goto finish

:finish
set "KEY_DIR=%REPO_BASE%\keys"
if not exist "%KEY_DIR%" mkdir "%KEY_DIR%"

if not exist "%KEY_DIR%\libscript-archive-keyring.gpg" (
    echo LibScript Universal APT/RPM Keyring Stub > "%KEY_DIR%\libscript-archive-keyring.gpg"
)

if not exist "%KEY_DIR%\libscript-alpine.rsa.pub" (
    echo -----BEGIN PUBLIC KEY----- > "%KEY_DIR%\libscript-alpine.rsa.pub"
    echo MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE >> "%KEY_DIR%\libscript-alpine.rsa.pub"
    echo -----END PUBLIC KEY----- >> "%KEY_DIR%\libscript-alpine.rsa.pub"
)

echo [OK] All repository metadata generated under: %REPO_BASE%
exit /b 0
