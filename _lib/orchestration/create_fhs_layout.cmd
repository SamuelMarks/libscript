@echo off
:: # create_fhs_layout.cmd
::
:: ## Overview
:: Initializes a standard Filesystem Hierarchy Standard (FHS) directory layout
:: within a target sysroot directory on Windows, populating default configuration skeletons.
::
:: ## Usage
:: Run `create_fhs_layout.cmd <target_sysroot>` to initialize the FHS directory tree.

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
    echo Usage: %~nx0 ^<target_sysroot^>
    echo Initializes standard FHS tree in the target directory.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 ^<target_sysroot^>
    echo Initializes standard FHS tree in the target directory.
    exit /b 0
)

set "TARGET_DIR=%~1"
if "%TARGET_DIR%"=="" set "TARGET_DIR=%LIBSCRIPT_TARGET_SYSROOT%"
if "%TARGET_DIR%"=="" (
    echo [ERROR] Target sysroot directory required.
    echo Usage: %~nx0 ^<target_sysroot^>
    exit /b 1
)

set "STAMP_DIR=%TARGET_DIR%\var\lib\libscript\stamps"
if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"
if exist "%STAMP_DIR%\.stamp.fhs_layout" (
    echo [INFO] FHS layout already initialized at %TARGET_DIR%. Skipping.
    exit /b 0
)

echo [INFO] Creating standard FHS layout in %TARGET_DIR%...

if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
if not exist "%TARGET_DIR%\sbin" mkdir "%TARGET_DIR%\sbin"
if not exist "%TARGET_DIR%\etc" mkdir "%TARGET_DIR%\etc"
if not exist "%TARGET_DIR%\usr\bin" mkdir "%TARGET_DIR%\usr\bin"
if not exist "%TARGET_DIR%\usr\sbin" mkdir "%TARGET_DIR%\usr\sbin"
if not exist "%TARGET_DIR%\usr\lib" mkdir "%TARGET_DIR%\usr\lib"
if not exist "%TARGET_DIR%\usr\include" mkdir "%TARGET_DIR%\usr\include"
if not exist "%TARGET_DIR%\usr\share" mkdir "%TARGET_DIR%\usr\share"
if not exist "%TARGET_DIR%\usr\local\bin" mkdir "%TARGET_DIR%\usr\local\bin"
if not exist "%TARGET_DIR%\usr\local\sbin" mkdir "%TARGET_DIR%\usr\local\sbin"
if not exist "%TARGET_DIR%\usr\local\lib" mkdir "%TARGET_DIR%\usr\local\lib"
if not exist "%TARGET_DIR%\usr\local\share" mkdir "%TARGET_DIR%\usr\local\share"
if not exist "%TARGET_DIR%\var\log" mkdir "%TARGET_DIR%\var\log"
if not exist "%TARGET_DIR%\var\run" mkdir "%TARGET_DIR%\var\run"
if not exist "%TARGET_DIR%\var\lib" mkdir "%TARGET_DIR%\var\lib"
if not exist "%TARGET_DIR%\var\cache" mkdir "%TARGET_DIR%\var\cache"
if not exist "%TARGET_DIR%\var\tmp" mkdir "%TARGET_DIR%\var\tmp"
if not exist "%TARGET_DIR%\tmp" mkdir "%TARGET_DIR%\tmp"
if not exist "%TARGET_DIR%\boot" mkdir "%TARGET_DIR%\boot"
if not exist "%TARGET_DIR%\dev" mkdir "%TARGET_DIR%\dev"
if not exist "%TARGET_DIR%\proc" mkdir "%TARGET_DIR%\proc"
if not exist "%TARGET_DIR%\sys" mkdir "%TARGET_DIR%\sys"
if not exist "%TARGET_DIR%\mnt" mkdir "%TARGET_DIR%\mnt"
if not exist "%TARGET_DIR%\opt" mkdir "%TARGET_DIR%\opt"
if not exist "%TARGET_DIR%\root" mkdir "%TARGET_DIR%\root"
if not exist "%TARGET_DIR%\home" mkdir "%TARGET_DIR%\home"
if not exist "%TARGET_DIR%\run" mkdir "%TARGET_DIR%\run"

if not exist "%TARGET_DIR%\etc\passwd" (
    (
        echo root:x:0:0:root:/root:/bin/sh
        echo daemon:x:1:1:daemon:/usr/sbin:/bin/false
        echo bin:x:2:2:bin:/bin:/bin/false
        echo sys:x:3:3:sys:/dev:/bin/false
        echo nobody:x:65534:65534:nobody:/:/bin/false
    ) > "%TARGET_DIR%\etc\passwd"
)

if not exist "%TARGET_DIR%\etc\group" (
    (
        echo root:x:0:
        echo daemon:x:1:
        echo bin:x:2:
        echo sys:x:3:
        echo wheel:x:10:root
        echo sudo:x:27:
        echo nogroup:x:65534:
    ) > "%TARGET_DIR%\etc\group"
)

if not exist "%TARGET_DIR%\etc\hosts" (
    (
        echo 127.0.0.1   localhost
        echo ::1         localhost ip6-localhost ip6-loopback
    ) > "%TARGET_DIR%\etc\hosts"
)

if not exist "%TARGET_DIR%\etc\os-release" (
    (
        echo NAME="LibScript OS"
        echo ID="libscript"
        echo PRETTY_NAME="LibScript Universal OS"
        echo VERSION="1.0"
        echo VERSION_ID="1.0"
        echo HOME_URL="https://github.com/libscript/libscript"
    ) > "%TARGET_DIR%\etc\os-release"
)

type nul > "%STAMP_DIR%\.stamp.fhs_layout"
echo [INFO] FHS layout successfully initialized: %TARGET_DIR%
exit /b 0
