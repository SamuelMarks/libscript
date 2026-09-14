@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for sh on Windows.
:: Prepares and configures sh on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript sh installation on Windows.

set "THIS_FILE=%~f0"

where sh >nul 2>&1
if %errorlevel% equ 0 exit /b 0

if exist "%ProgramFiles%\Git\bin\sh.exe" exit /b 0
if exist "%ProgramFiles%\Git\usr\bin\sh.exe" exit /b 0

where busybox >nul 2>&1
if errorlevel 1 (
    if defined LIBSCRIPT_ROOT_DIR (
        echo Installing busybox to provide POSIX sh...
        call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install busybox
    )
)

where busybox >nul 2>&1
if not errorlevel 1 (
    set "DEST_DIR=%USERPROFILE%\.local\bin"
    if not exist "!DEST_DIR!" mkdir "!DEST_DIR!"
    (
        echo @echo off
        echo busybox sh %%*
    ) > "!DEST_DIR!\sh.cmd"
    exit /b 0
)

echo Failed to provision sh on Windows.
exit /b 1
