@echo off
:: # os_info.cmd
::
:: ## Overview
:: Detects and exports environment variables describing the Windows operating system and architecture.
::
:: ## Usage
:: Call this script to initialize OS, TARGET_OS, ARCH, and PKG_MGR variables on Windows.

set "THIS_FILE=%~f0"

:: ## detect_os_info
:: Executes detect_os_info functionality.
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
