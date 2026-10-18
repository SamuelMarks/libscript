@echo off
:: # base.cmd
::
:: ## Overview
:: Bootstraps the illumos base system directory layout and configuration
:: markers on Windows host environments.
::
:: ## Usage
:: base.cmd [sysroot_path] [illumos_version] [arch]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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
    echo Usage: %~nx0 [sysroot_path] [illumos_version] [arch]
    echo Bootstraps illumos base system into sysroot.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [illumos_version] [arch]
    echo Bootstraps illumos base system into sysroot.
    exit /b 0
)

set "REPO_ROOT=!SCRIPT_DIR!..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\illumos-sysroot"
set "VERSION=%~2"
if "%VERSION%"=="" set "VERSION=r151048"
set "ARCH=%~3"
if "%ARCH%"=="" set "ARCH=amd64"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\base.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"
if exist "%STAMP_FILE%" (
    echo [SKIP]     illumos base system already bootstrapped in %SYSROOT%
    exit /b 0
)

echo [BASE]     Bootstrapping illumos %VERSION% (%ARCH%) into %SYSROOT%...

for %%d in (boot dev devices etc export export\home home kernel lib mnt opt platform proc root sbin system tmp usr var) do (
    if not exist "%SYSROOT%\%%d" mkdir "%SYSROOT%\%%d"
)
for %%d in (bin sbin lib lib\64 kernel share) do (
    if not exist "%SYSROOT%\usr\%%d" mkdir "%SYSROOT%\usr\%%d"
)
for %%d in (adm log run svc svc\manifest tmp) do (
    if not exist "%SYSROOT%\var\%%d" mkdir "%SYSROOT%\var\%%d"
)
for %%d in (contract object volatile) do (
    if not exist "%SYSROOT%\system\%%d" mkdir "%SYSROOT%\system\%%d"
)

echo illumos %VERSION% (%ARCH%)> "%SYSROOT%\etc\release"
echo %VERSION%> "%SYSROOT%\etc\libscript-illumos-version"

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       illumos base bootstrap completed.
exit /b 0
