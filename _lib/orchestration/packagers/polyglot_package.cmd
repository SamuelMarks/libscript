@echo off
setlocal EnableDelayedExpansion
:: # polyglot_package.cmd
::
:: ## Overview
:: Multi-distribution cross-packaging engine on Windows that generates
:: .apk, .deb, and .rpm package formats simultaneously.
::
:: ## Usage
:: call _lib\orchestration\packagers\polyglot_package.cmd <pkg_name> <pkg_version> <staging_dir> [out_base_dir]

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

set "PKG_NAME=%~1"
if "%PKG_NAME%"=="" set "PKG_NAME=sample-pkg"
set "PKG_VER=%~2"
if "%PKG_VER%"=="" set "PKG_VER=1.0.0"
set "STAGE_DIR=%~3"
if "%STAGE_DIR%"=="" set "STAGE_DIR=%LIBSCRIPT_ROOT_DIR%\build\stage_polyglot"
set "OUT_BASE=%~4"
if "%OUT_BASE%"=="" set "OUT_BASE=%LIBSCRIPT_ROOT_DIR%\build\packages"

if not exist "%OUT_BASE%\apk" mkdir "%OUT_BASE%\apk"
if not exist "%OUT_BASE%\deb" mkdir "%OUT_BASE%\deb"
if not exist "%OUT_BASE%\rpm" mkdir "%OUT_BASE%\rpm"

echo [POLYGLOT] Starting multi-distribution cross-packaging for %PKG_NAME% %PKG_VER%...

call "%SCRIPT_DIR%\build_apk.cmd" "%PKG_NAME%" "%PKG_VER%" "%STAGE_DIR%" "%OUT_BASE%\apk"
call "%SCRIPT_DIR%\build_deb.cmd" "%PKG_NAME%" "%PKG_VER%" "%STAGE_DIR%" "%OUT_BASE%\deb"
call "%SCRIPT_DIR%\build_rpm.cmd" "%PKG_NAME%" "%PKG_VER%" "%STAGE_DIR%" "%OUT_BASE%\rpm"

set "APK_FILE=%OUT_BASE%\apk\%PKG_NAME%-%PKG_VER%.apk"
set "DEB_FILE=%OUT_BASE%\deb\%PKG_NAME%_%PKG_VER%_amd64.deb"
set "RPM_FILE=%OUT_BASE%\rpm\%PKG_NAME%-%PKG_VER%-1.x86_64.rpm"

if exist "%APK_FILE%" if exist "%DEB_FILE%" if exist "%RPM_FILE%" (
    echo [OK] Polyglot cross-packaging succeeded for %PKG_NAME% across APK, DEB, and RPM.
    exit /b 0
)

echo [ERROR] One or more package formats failed to generate. >&2
exit /b 1
