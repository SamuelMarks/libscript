@echo off
:: # base.cmd
::
:: ## Overview
:: Bootstraps the FreeBSD base system directory layout and configuration
:: markers on Windows host environments.
::
:: ## Usage
:: base.cmd [sysroot_path] [freebsd_version] [arch]

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
    echo Usage: %~nx0 [sysroot_path] [freebsd_version] [arch]
    echo Bootstraps FreeBSD base system into sysroot.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [freebsd_version] [arch]
    echo Bootstraps FreeBSD base system into sysroot.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\freebsd-sysroot"
set "VERSION=%~2"
if "%VERSION%"=="" set "VERSION=14.1-RELEASE"
set "ARCH=%~3"
if "%ARCH%"=="" set "ARCH=amd64"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\base.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"
if exist "%STAMP_FILE%" (
    echo [SKIP]     FreeBSD base system already bootstrapped in %SYSROOT%
    exit /b 0
)

echo [BASE]     Bootstrapping FreeBSD %VERSION% (%ARCH%) into %SYSROOT%...

for %%d in (bin boot dev etc home lib libexec media mnt net proc rescue root sbin sys tmp usr var) do (
    if not exist "%SYSROOT%\%%d" mkdir "%SYSROOT%\%%d"
)
for %%d in (bin sbin lib local share) do (
    if not exist "%SYSROOT%\usr\%%d" mkdir "%SYSROOT%\usr\%%d"
)
for %%d in (run log db tmp service) do (
    if not exist "%SYSROOT%\var\%%d" mkdir "%SYSROOT%\var\%%d"
)

echo %VERSION%> "%SYSROOT%\etc\libscript-freebsd-version"

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       FreeBSD base bootstrap completed.
exit /b 0
