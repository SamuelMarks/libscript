@echo off
:: # init.cmd
::
:: ## Overview
:: Configures modular init system supervision inside FreeBSD target sysroot
:: on Windows host environments.
::
:: ## Usage
:: init.cmd [sysroot_path] [provider] [services_list]

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


if "%~1"=="--help" (
    echo Usage: %~nx0 [sysroot_path] [provider] [services_list]
    echo Configures FreeBSD init system.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [provider] [services_list]
    echo Configures FreeBSD init system.
    exit /b 0
)

set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\freebsd-sysroot"
set "PROVIDER=%~2"
if "%PROVIDER%"=="" set "PROVIDER=bsd-rc"
set "SERVICES=%~3"
if "%SERVICES%"=="" set "SERVICES=sshd,cron,devd"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\init_%PROVIDER%.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"
if not exist "%SYSROOT%\etc" mkdir "%SYSROOT%\etc"
if not exist "%SYSROOT%\boot" mkdir "%SYSROOT%\boot"

if exist "%STAMP_FILE%" (
    echo [SKIP]     FreeBSD init system %PROVIDER% already configured in %SYSROOT%
    exit /b 0
)

echo [INIT]     Configuring init provider %PROVIDER%...

if "%PROVIDER%"=="bsd-rc" (
    findstr /C:"# BSD rc.d enabled services" "%SYSROOT%\etc\rc.conf" >nul 2>&1
    if errorlevel 1 (
        echo # BSD rc.d enabled services>> "%SYSROOT%\etc\rc.conf"
        echo sshd_enable="YES">> "%SYSROOT%\etc\rc.conf"
        echo cron_enable="YES">> "%SYSROOT%\etc\rc.conf"
        echo devd_enable="YES">> "%SYSROOT%\etc\rc.conf"
    )
)
if "%PROVIDER%"=="openrc" (
    if not exist "%SYSROOT%\etc\init.d" mkdir "%SYSROOT%\etc\init.d"
    findstr /C:"init_path=" "%SYSROOT%\boot\loader.conf" >nul 2>&1
    if errorlevel 1 echo init_path="/sbin/openrc-init:/sbin/init">> "%SYSROOT%\boot\loader.conf"
)
if "%PROVIDER%"=="runit" (
    if not exist "%SYSROOT%\var\service" mkdir "%SYSROOT%\var\service"
    findstr /C:"init_path=" "%SYSROOT%\boot\loader.conf" >nul 2>&1
    if errorlevel 1 echo init_path="/usr/local/sbin/runit-init:/sbin/init">> "%SYSROOT%\boot\loader.conf"
)
if "%PROVIDER%"=="s6" (
    if not exist "%SYSROOT%\etc\s6" mkdir "%SYSROOT%\etc\s6"
    findstr /C:"init_path=" "%SYSROOT%\boot\loader.conf" >nul 2>&1
    if errorlevel 1 echo init_path="/usr/local/bin/s6-svscan:/sbin/init">> "%SYSROOT%\boot\loader.conf"
)
if "%PROVIDER%"=="dinit" (
    if not exist "%SYSROOT%\etc\dinit.d" mkdir "%SYSROOT%\etc\dinit.d"
    findstr /C:"init_path=" "%SYSROOT%\boot\loader.conf" >nul 2>&1
    if errorlevel 1 echo init_path="/usr/local/sbin/dinit:/sbin/init">> "%SYSROOT%\boot\loader.conf"
)

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       Init provider %PROVIDER% configured successfully.
exit /b 0
