@echo off
setlocal EnableDelayedExpansion
:: # oci_image.cmd
::
:: ## Overview
:: Zero-daemon OCI container image layout generator on Windows.
::
:: ## Usage
:: call cli\commands\package_as\oci_image.cmd [sysroot_dir] [out_archive] [image_tag]

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
    for %%i in ("%SCRIPT_DIR%\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

call "%SCRIPT_DIR%\container_base.cmd" %*
exit /b %ERRORLEVEL%
