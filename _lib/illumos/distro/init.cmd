@echo off
:: # init.cmd
::
:: ## Overview
:: Configures modular init system supervision inside illumos target sysroot
:: on Windows host environments.
::
:: ## Usage
:: init.cmd [sysroot_path] [provider] [services_list] [milestone]

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
    echo Usage: %~nx0 [sysroot_path] [provider] [services_list] [milestone]
    echo Configures illumos init system.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [provider] [services_list] [milestone]
    echo Configures illumos init system.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\illumos-sysroot"
set "PROVIDER=%~2"
if "%PROVIDER%"=="" set "PROVIDER=smf"
set "SERVICES=%~3"
if "%SERVICES%"=="" set "SERVICES=svc:/network/ssh:default,svc:/system/cron:default"
set "MILESTONE=%~4"
if "%MILESTONE%"=="" set "MILESTONE=svc:/milestone/multi-user-server:default"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\init_%PROVIDER%.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"
if not exist "%SYSROOT%\etc" mkdir "%SYSROOT%\etc"
if not exist "%SYSROOT%\boot" mkdir "%SYSROOT%\boot"

if exist "%STAMP_FILE%" (
    echo [SKIP]     illumos init system %PROVIDER% already configured in %SYSROOT%
    exit /b 0
)

echo [INIT]     Configuring illumos init provider %PROVIDER%...

if "%PROVIDER%"=="smf" (
    if not exist "%SYSROOT%\etc\svc\profile" mkdir "%SYSROOT%\etc\svc\profile"
    (
        echo DEFAULT_MILESTONE="%MILESTONE%"
        echo ENABLED_SERVICES="%SERVICES%"
    ) > "%SYSROOT%/etc/svc/profile/services.conf"
) else if "%PROVIDER%"=="runit" (
    if not exist "%SYSROOT%\etcunit" mkdir "%SYSROOT%\etcunit"
    if not exist "%SYSROOT%\service" mkdir "%SYSROOT%\service"
    echo init_path="/usr/local/sbin/runit-init:/sbin/init">> "%SYSROOT%/boot/loader.conf"
)

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       illumos init provider %PROVIDER% configured.
exit /b 0
