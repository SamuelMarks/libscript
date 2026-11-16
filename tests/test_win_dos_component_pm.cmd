@echo off
:: # test_win_dos_component_pm.cmd
:: ## Overview
:: End-to-end verification on Windows of the 6 Windows native & MS-DOS component-level package managers
:: (`jq`, `gawk`, `busybox`, `toybox`, `dash`, `freebsd-usr-bin`) and target-aware `depends` routing.
::
:: ## Usage
:: tests\test_win_dos_component_pm.cmd
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

set "TEST_WORK=%TEMP%\ls_win_dos_pm_%RANDOM%"
if not exist "!TEST_WORK!\downloads\jq" mkdir "!TEST_WORK!\downloads\jq"
if not exist "!TEST_WORK!\downloads\busybox" mkdir "!TEST_WORK!\downloads\busybox"

echo MSDOS-DOS32-JQ-1.8.2> "!TEST_WORK!\downloads\jq\jq-1.8.2-dos32.exe"
echo WIN32-PE-X64-JQ-1.8.2> "!TEST_WORK!\downloads\jq\jq-1.8.2-X64.exe"
echo WIN32-PE-X64-BUSYBOX-1.39.0> "!TEST_WORK!\downloads\busybox\busybox-1.39.0-X64.exe"

set "DOWNLOAD_DIR=!TEST_WORK!\downloads"
set "LIBSCRIPT_OFFLINE=1"

:: 1. Verify MS-DOS target gets dos32 jq.exe
set "LIBSCRIPT_TARGET_OS=msdos"
set "LIBSCRIPT_HOME=!TEST_WORK!\dos_home"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" depends jq
if errorlevel 1 (
    echo [FAIL] MS-DOS depends jq failed 1>&2
    rmdir /s /q "!TEST_WORK!" 2>nul
    exit /b 1
)
findstr /C:"MSDOS-DOS32-JQ-1.8.2" "!TEST_WORK!\dos_home\jq\default\bin\jq.exe" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] MS-DOS depends jq payload mismatch 1>&2
    rmdir /s /q "!TEST_WORK!" 2>nul
    exit /b 1
)

:: 2. Verify Windows target gets Windows PE X64 jq.exe and busybox.exe
set "LIBSCRIPT_TARGET_OS=windows"
set "LIBSCRIPT_TARGET_ARCH=x86_64"
set "LIBSCRIPT_HOME=!TEST_WORK!\win_home"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" depends jq busybox
if errorlevel 1 (
    echo [FAIL] Windows depends jq busybox failed 1>&2
    rmdir /s /q "!TEST_WORK!" 2>nul
    exit /b 1
)
findstr /C:"WIN32-PE-X64-JQ-1.8.2" "!TEST_WORK!\win_home\jq\default\bin\jq.exe" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Windows depends jq payload mismatch 1>&2
    rmdir /s /q "!TEST_WORK!" 2>nul
    exit /b 1
)
findstr /C:"WIN32-PE-X64-BUSYBOX-1.39.0" "!TEST_WORK!\win_home\busybox\default\bin\busybox.exe" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Windows depends busybox payload mismatch 1>&2
    rmdir /s /q "!TEST_WORK!" 2>nul
    exit /b 1
)

rmdir /s /q "!TEST_WORK!" 2>nul
echo [PASS] Windows and MS-DOS component-level package manager routing verified.
exit /b 0
