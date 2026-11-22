@echo off
:: # setup.cmd
::
:: ## Overview
:: ReactOS kernel and userland compilation and base staging engine on Windows.
:: Supports source builds via _lib\toolchains\rosbe or upstream ISO extraction via distro\base.cmd.
::
:: ## Usage
:: synthesis\distro\reactos-base\setup.cmd [--strict | --allow-stub] [--from-source] [compile|install|clean]

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

set "STRICT_BUILD=%LIBSCRIPT_STRICT_IMAGE_BUILD%"
if "!STRICT_BUILD!"=="" set "STRICT_BUILD=0"
set "ALLOW_STUB=%LIBSCRIPT_ALLOW_STUB%"
if "!ALLOW_STUB!"=="" set "ALLOW_STUB=0"
set "FROM_SOURCE=%REACTOS_BUILD_FROM_SOURCE%"
if "!FROM_SOURCE!"=="" set "FROM_SOURCE=0"
set "ACTION_ARG="
goto :parse_args

:: ## parse_args
:: Parses CLI options for ReactOS setup.cmd.
:parse_args
if "%~1"=="" goto :args_done
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="--strict" ( set "STRICT_BUILD=1" & set "ALLOW_STUB=0" & shift & goto :parse_args )
if /I "%~1"=="--allow-stub" ( set "ALLOW_STUB=1" & set "STRICT_BUILD=0" & shift & goto :parse_args )
if /I "%~1"=="--from-source" ( set "FROM_SOURCE=1" & shift & goto :parse_args )
set "ACTION_ARG=%~1"
shift
goto :parse_args

:: ## args_done
:: Executes the requested ReactOS build or staging action.
:args_done
set "LIBSCRIPT_STRICT_IMAGE_BUILD=!STRICT_BUILD!"
set "LIBSCRIPT_ALLOW_STUB=!ALLOW_STUB!"
if "!ACTION_ARG!"=="" set "ACTION_ARG=%ACTION%"
if "!ACTION_ARG!"=="" set "ACTION_ARG=install"

set "TARGET_SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
if "!TARGET_SYSROOT!"=="" set "TARGET_SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\reactos-sysroot"
set "STAMP_DIR=!TARGET_SYSROOT!\var\lib\libscript\stamps"
set "STAMP_FILE=!STAMP_DIR!\.stamp.reactos_system"
set "REACTOS_VER=%REACTOS_VERSION%"
if "!REACTOS_VER!"=="" set "REACTOS_VER=0.4.16"
set "TARGET_ARCH=%LIBSCRIPT_TARGET_ARCH%"
if "!TARGET_ARCH!"=="" set "TARGET_ARCH=i686"

if /I "!ACTION_ARG!"=="clean" (
    if exist "!STAMP_FILE!" del /f /q "!STAMP_FILE!" >nul 2>&1
    exit /b 0
)

if exist "!STAMP_FILE!" if exist "!TARGET_SYSROOT!\iso_root\freeldr.sys" (
    echo [SKIP] ReactOS system already staged: !STAMP_FILE!
    exit /b 0
)

if not exist "!STAMP_DIR!" mkdir "!STAMP_DIR!"
if "!FROM_SOURCE!"=="1" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\rosbe\setup.cmd"
    if exist "%REACTOS_SRC_DIR%\configure.cmd" (
        pushd "%REACTOS_SRC_DIR%"
        call configure.cmd
        ninja bootcd
        popd
    ) else if "!STRICT_BUILD!"=="1" if not "!ALLOW_STUB!"=="1" (
        echo [ERROR] REACTOS_SRC_DIR missing configure.cmd for strict source build. >&2
        exit /b 1
    )
)

set "_FLAG=--allow-stub"
if "!STRICT_BUILD!"=="1" set "_FLAG=--strict"
set "STACK="
call "!SCRIPT_DIR!\distro\base.cmd" !_FLAG! "!TARGET_SYSROOT!" "!REACTOS_VER!" "!TARGET_ARCH!"
if errorlevel 1 exit /b !errorlevel!

echo mode=repack> "!STAMP_FILE!"
echo [OK]    reactos_system staged successfully: !STAMP_FILE!
exit /b 0

:: ## show_help
:: Displays usage instructions for ReactOS setup.cmd.
:show_help
echo Usage: %~nx0 [--strict ^| --allow-stub] [--from-source] [compile^|install^|clean]
exit /b 0
