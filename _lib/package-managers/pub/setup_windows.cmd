@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for pub on Windows.
:: Downloads and installs the official Dart SDK distribution containing pub.
::
:: ## Usage
:: Automatically invoked during libscript pub installation on Windows.

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
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

where pub >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "ARCH=x64"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARCH=arm64"

set "DEST_DIR=%USERPROFILE%\.local\dart"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "BIN_DIR=%USERPROFILE%\.local\bin"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

set "URL=https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-windows-%ARCH%-release.zip"
set "TEMP_ZIP=%TEMP%\dart.zip"

echo Downloading Dart SDK (%ARCH%) from %URL%...
curl.exe -sSL "%URL%" -o "%TEMP_ZIP%"
if errorlevel 1 (
    echo Failed to download Dart SDK.
    exit /b 1
)

tar -xf "%TEMP_ZIP%" -C "%DEST_DIR%"
del "%TEMP_ZIP%" >nul 2>&1

if exist "%DEST_DIR%\dart-sdk\bin\dart.exe" (
    (
        echo @echo off
        echo if "%%~1"=="--version" ^(
        echo     "%DEST_DIR%\dart-sdk\bin\dart.exe" --version
        echo     exit /b %%errorlevel%%
        echo ^)
        echo "%DEST_DIR%\dart-sdk\bin\dart.exe" pub %%*
    ) > "%BIN_DIR%\pub.cmd"
    (
        echo @echo off
        echo "%DEST_DIR%\dart-sdk\bin\dart.exe" %%*
    ) > "%BIN_DIR%\dart.cmd"
    echo pub installed successfully to %BIN_DIR%.
    exit /b 0
)

exit /b 1
