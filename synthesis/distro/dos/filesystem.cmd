@echo off
:: # filesystem.cmd
::
:: ## Overview
:: Compiles mkdosfs_img.exe on Windows and packs LIBSCRIPT_TARGET_SYSROOT into a bootable FAT12/16/32 image.
::
:: ## Usage
:: synthesis\distro\dos\filesystem.cmd <sysroot_dir> <output_img> [media_type]

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

set "SYSROOT=%~1"
if "!SYSROOT!"=="" set "SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
set "OUT_IMG=%~2"
if "!OUT_IMG!"=="" set "OUT_IMG=%LIBSCRIPT_ROOT_DIR%\build\synthesis\dos.raw"
set "MEDIA=%~3"
if "!MEDIA!"=="" set "MEDIA=%LIBSCRIPT_DOS_MEDIA_TYPE%"
if "!MEDIA!"=="" set "MEDIA=auto"
set "STRATUM=%LIBSCRIPT_DOS_STRATUM%"
if "!STRATUM!"=="" set "STRATUM=dos32-dpmi"
set "DOS_OS=%LIBSCRIPT_TARGET_OS%"
if "!DOS_OS!"=="" set "DOS_OS=freedos"

if /I "!MEDIA!"=="auto" (
    if /I "!STRATUM!"=="dos16-fcb" ( set "MEDIA=floppy-1440k" ) else if /I "!STRATUM!"=="dos16-handle" ( set "MEDIA=floppy-1440k" ) else if /I "!DOS_OS!"=="freedos" ( set "MEDIA=hdd-fat32" ) else ( set "MEDIA=hdd-fat16" )
)

set "MKFAT=!LIBSCRIPT_ROOT_DIR!\build\tools\mkdosfs_img.exe"
if not exist "!LIBSCRIPT_ROOT_DIR!\build\tools" mkdir "!LIBSCRIPT_ROOT_DIR!\build\tools"
if not exist "!MKFAT!" call :ensure_mkfat || exit /b 1
for %%D in ("!OUT_IMG!") do if not exist "%%~dpD" mkdir "%%~dpD"

set "EXTRA="
for %%U in (var opt usr "etc\profile.d") do (
    if exist "!SYSROOT!\%%~U" rmdir /s /q "!SYSROOT!\%%~U"
)
if /I "!STRATUM!"=="dos16-fcb" (
    if exist "!SYSROOT!\etc" rmdir /s /q "!SYSROOT!\etc"
    set "EXTRA=--flat-only"
)
"!MKFAT!" "--sysroot=!SYSROOT!" "--out=!OUT_IMG!" "--media=!MEDIA!" "--label=LIBSCRIP" !EXTRA!
exit /b !errorlevel!

:: ## ensure_mkfat
:: Compiles mkdosfs_img.c with cl.exe, gcc/clang, or zig cc.
:ensure_mkfat
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos32\compile_host_c89.cmd" "!SCRIPT_DIR!\src\mkdosfs_img.c" "!MKFAT!"
exit /b !errorlevel!
