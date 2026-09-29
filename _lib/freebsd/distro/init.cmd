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

SET "searchVal=;%THIS_FILE%;"
IF NOT DEFINED STACK (
    SET "STACK=;%THIS_FILE%;"
    echo [CONTINUE] processing "%THIS_FILE%"
) ELSE (
    IF NOT "!STACK:%searchVal%=!"=="!STACK!" (
        echo [STOP]     processing "%THIS_FILE%"
        SET ERRORLEVEL=0
        goto :eof
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

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

set "SCRIPT_DIR=%~dp0"
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
    findstr /C:"# BSD rc.d enabled services" "%SYSROOT%\etcc.conf" >nul 2>&1
    if errorlevel 1 (
        echo # BSD rc.d enabled services>> "%SYSROOT%\etcc.conf"
        echo sshd_enable="YES">> "%SYSROOT%\etcc.conf"
        echo cron_enable="YES">> "%SYSROOT%\etcc.conf"
        echo devd_enable="YES">> "%SYSROOT%\etcc.conf"
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
