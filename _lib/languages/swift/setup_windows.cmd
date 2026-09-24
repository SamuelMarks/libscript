@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for Swift on Windows.
:: Installs the official Swift Toolchain for Windows via winget package with selective components
:: to conserve disk space and ensure non-interactive headless success.
::
:: ## Usage
:: Automatically invoked during libscript swift installation on Windows.

set "THIS_FILE=%~f0"

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

echo Installing Swift Toolchain via winget...
winget install --id Swift.Toolchain --silent --accept-package-agreements --accept-source-agreements --override "/quiet /install /norestart OptionsInstallDBG=0 OptionsInstallIDE=0 OptionsInstallPy=0 OptionsInstallSupport=0 OptionsInstallUtilities=0 OptionsInstallWindowsSDKX86=0 OptionsInstallWindowsRedistX86=0 OptionsInstallWindowsSDKAMD64=0 OptionsInstallWindowsRedistAMD64=0 OptionsInstallAndroidPlatform=0 OptionsInstallAndroidSDKARM64=0 OptionsInstallAndroidSDKAMD64=0"
if errorlevel 1 (
    echo Retrying Swift Toolchain install with standard parameters...
    winget install --id Swift.Toolchain --silent --accept-package-agreements --accept-source-agreements
)

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
