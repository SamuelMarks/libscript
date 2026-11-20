@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface router for ReactOS Build Environment (rosbe) on Windows.
::
:: ## Usage
:: _lib\toolchains\rosbe\cli.cmd <install|ls|ls-remote|use|uninstall|target-add|which|exec> [args]

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

if /i "%~1"=="target-add" (
    shift
    call :target_add "%~1"
    exit /b !errorlevel!
)

set "PACKAGE_NAME=rosbe"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\component_core.cmd" %*
exit /b !errorlevel!

:: ## target_add
:: Enables i686-w64-mingw32 or x86_64-w64-mingw32 target support idempotently.
:target_add
set "_TGT=%~1"
set "_NORM="
set "_SUB="
if /i "!_TGT!"=="i686-w64-mingw32" ( set "_NORM=i686-w64-mingw32" & set "_SUB=i386" )
if /i "!_TGT!"=="i386" ( set "_NORM=i686-w64-mingw32" & set "_SUB=i386" )
if /i "!_TGT!"=="x86_64-w64-mingw32" ( set "_NORM=x86_64-w64-mingw32" & set "_SUB=amd64" )
if /i "!_TGT!"=="amd64" ( set "_NORM=x86_64-w64-mingw32" & set "_SUB=amd64" )
if "!_NORM!"=="" (
    echo [ERROR] Unsupported RosBE target "!_TGT!". >&2
    exit /b 1
)
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
set "_VER=%ROSBE_VERSION%"
if "!_VER!"=="" set "_VER=2.2.1"
if /i "!_VER!"=="latest" set "_VER=2.2.1"
set "_INST_DIR=%LIBSCRIPT_ROSBE_INSTALL_DIR%"
if "!_INST_DIR!"=="" set "_INST_DIR=%LIBSCRIPT_HOME%\rosbe\!_VER!"
if not exist "!_INST_DIR!" (
    set "ACTION=install"
    call "!SCRIPT_DIR!\setup_generic.cmd" >nul
)
if not exist "!_INST_DIR!\!_SUB!\bin" mkdir "!_INST_DIR!\!_SUB!\bin"
if exist "!_INST_DIR!\targets.list" (
    findstr /I /X /C:"!_NORM!" "!_INST_DIR!\targets.list" >nul 2>&1
    if not errorlevel 1 (
        echo [SKIP] RosBE target !_NORM! already enabled.
        exit /b 0
    )
)
echo.!_NORM!>> "!_INST_DIR!\targets.list"
echo [OK] Enabled RosBE target !_NORM!.
exit /b 0
