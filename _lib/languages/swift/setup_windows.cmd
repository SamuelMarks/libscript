@echo off
:: # setup_windows.cmd
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for Swift on Windows.
:: Installs the official Swift Toolchain for Windows via winget package with selective components
:: to conserve disk space and ensure non-interactive headless success.
::
:: ## Usage
:: Automatically invoked during libscript swift installation on Windows.

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

where swift >nul 2>&1
if %errorlevel% equ 0 exit /b 0

for /d %%S in ("%LOCALAPPDATA%\Programs\Swift\Toolchains\*") do (
    if exist "%%S\usr\bin\swift.exe" (
        set "SWIFT_BIN=%%S\usr\bin"
        goto :create_shims
    )
)
for /d %%S in ("%ProgramFiles%\Swift\Toolchains\*") do (
    if exist "%%S\usr\bin\swift.exe" (
        set "SWIFT_BIN=%%S\usr\bin"
        goto :create_shims
    )
)

echo Installing Swift Toolchain via pkg_mgr...
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends "Swift.Toolchain"

:: ## create_shims
:: Creates executable command shims for the installed Swift toolchain in the user bin directory.
:create_shims
for /d %%S in ("%LOCALAPPDATA%\Programs\Swift\Toolchains\*") do (
    if exist "%%S\usr\bin\swift.exe" set "SWIFT_BIN=%%S\usr\bin"
)
for /d %%S in ("%ProgramFiles%\Swift\Toolchains\*") do (
    if exist "%%S\usr\bin\swift.exe" set "SWIFT_BIN=%%S\usr\bin"
)

if defined SWIFT_BIN (
    set "DEST_DIR=%USERPROFILE%\.libscript\swift\latest\bin"
    if not exist "!DEST_DIR!" mkdir "!DEST_DIR!"
    (
        echo @echo off
        echo "!SWIFT_BIN!\swift.exe" %%*
    ) > "!DEST_DIR!\swift.cmd"

    if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
    copy /y "!DEST_DIR!\swift.cmd" "%USERPROFILE%\.local\bin\swift.cmd" >nul 2>&1
    echo Swift installed successfully from !SWIFT_BIN!.
    exit /b 0
)

echo Swift installation could not be located.
exit /b 1
