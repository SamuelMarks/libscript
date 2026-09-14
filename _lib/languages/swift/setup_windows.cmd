@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for Swift on Windows.
:: Installs the official Swift Toolchain for Windows via winget package.
::
:: ## Usage
:: Automatically invoked during libscript swift installation on Windows.

set "THIS_FILE=%~f0"

where swift >nul 2>&1
if %errorlevel% equ 0 exit /b 0

for /d %%S in ("%LOCALAPPDATA%\Programs\Swift\Toolchains\*") do (
    if exist "%%S\usr\bin\swift.exe" exit /b 0
)
for /d %%S in ("%ProgramFiles%\Swift\Toolchains\*") do (
    if exist "%%S\usr\bin\swift.exe" exit /b 0
)

echo Installing Swift Toolchain via winget...
winget install --id Swift.Toolchain --silent --accept-package-agreements --accept-source-agreements
if errorlevel 1 (
    echo Failed to install Swift Toolchain via winget.
    exit /b 1
)

for /d %%S in ("%LOCALAPPDATA%\Programs\Swift\Toolchains\*") do (
    if exist "%%S\usr\bin\swift.exe" set "SWIFT_BIN=%%S\usr\bin"
)
for /d %%S in ("%ProgramFiles%\Swift\Toolchains\*") do (
    if exist "%%S\usr\bin\swift.exe" set "SWIFT_BIN=%%S\usr\bin"
)

if defined SWIFT_BIN (
    set "DEST_DIR=%USERPROFILE%\.local\bin"
    if not exist "!DEST_DIR!" mkdir "!DEST_DIR!"
    (
        echo @echo off
        echo "!SWIFT_BIN!\swift.exe" %%*
    ) > "!DEST_DIR!\swift.cmd"
)

echo Swift installed successfully.
exit /b 0
