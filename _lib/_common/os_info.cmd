@echo off
:: # os_info.cmd
::
:: ## Overview
:: Detects and exports environment variables describing the Windows operating system and architecture.
::
:: ## Usage
:: Call this script to initialize OS, TARGET_OS, ARCH, and PKG_MGR variables on Windows.

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

:: ## detect_os_info
:: Detects the host operating system, distribution, and CPU architecture.
:detect_os_info
set "OS=Windows_NT"
set "TARGET_OS=windows"
set "UNAME=Windows_NT"
set "UNAME_LOWER=windows"

if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set "ARCH=x86_64"
    set "ARCH_ALT=amd64"
) else if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set "ARCH=aarch64"
    set "ARCH_ALT=arm64"
) else if /i "%PROCESSOR_ARCHITECTURE%"=="x86" (
    set "ARCH=i686"
    set "ARCH_ALT=386"
) else (
    set "ARCH=%PROCESSOR_ARCHITECTURE%"
    set "ARCH_ALT=%PROCESSOR_ARCHITECTURE%"
)

where winget >nul 2>&1
if not errorlevel 1 (
    set "PKG_MGR=winget"
) else (
    where choco >nul 2>&1
    if not errorlevel 1 (
        set "PKG_MGR=choco"
    ) else (
        where scoop >nul 2>&1
        if not errorlevel 1 (
            set "PKG_MGR=scoop"
        ) else (
            set "PKG_MGR="
        )
    )
)

exit /b 0
