@echo off
:: # test.cmd
::
:: ## Overview
:: Test suite for the msi-rs component on Windows.
:: Validates that msi-rs CLI and WiX/msitools replacement binaries are installed and operational.
::
:: ## Usage
:: Execute this script to perform a component-specific test on Windows:
::   test.cmd

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

if exist "%~dp0env.cmd" (
    call "%~dp0env.cmd"
)

set "_FOUND_CLI=0"
where msi-cli.exe >nul 2>&1 && (msi-cli.exe --help >nul & echo [PASS] msi-cli is operational & set "_FOUND_CLI=1")
if "!_FOUND_CLI!"=="0" where msi-rs.exe >nul 2>&1 && (msi-rs.exe --help >nul & echo [PASS] msi-rs is operational & set "_FOUND_CLI=1")
if "!_FOUND_CLI!"=="0" where msi.exe >nul 2>&1 && (msi.exe --help >nul & echo [PASS] msi is operational & set "_FOUND_CLI=1")
if "!_FOUND_CLI!"=="0" where wix.exe >nul 2>&1 && (wix.exe --help >nul & echo [PASS] wix is operational & set "_FOUND_CLI=1")

if "!_FOUND_CLI!"=="0" (
    echo [FAIL] No msi-rs executable found in PATH >&2
    exit /b 1
)

:: ## test_roundtrip_msi
:: Verifies full round-trip WiX XML compilation, linking, and inspection via msi-rs toolchain.
where candle.exe >nul 2>&1
if not errorlevel 1 where light.exe >nul 2>&1
if not errorlevel 1 (
    set "TMP_TEST=%TEMP%\msi_rs_roundtrip_%RANDOM%"
    if not exist "!TMP_TEST!" mkdir "!TMP_TEST!" >nul 2>&1
    echo hello 1 > "!TMP_TEST!\test1.txt"
    echo hello 2 > "!TMP_TEST!\test2.txt"

    (
        echo ^<?xml version="1.0" encoding="UTF-8"?^>
        echo ^<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi"^>
        echo   ^<Product Id="*" Name="MsiRsRoundtripTest" Language="1033" Version="1.0.0" Manufacturer="LibScript" UpgradeCode="12345678-1234-1234-1234-1234567890AB"^>
        echo     ^<Package InstallerVersion="200" Compressed="yes" InstallScope="perMachine" /^>
        echo     ^<Media Id="1" Cabinet="media1.cab" EmbedCab="yes" /^>
        echo     ^<Directory Id="TARGETDIR" Name="SourceDir"^>
        echo       ^<Directory Id="ProgramFilesFolder"^>
        echo         ^<Directory Id="INSTALLFOLDER" Name="MsiRsTest"^>
        echo           ^<Component Id="Comp1" Guid="12345678-1234-1234-1234-123456789001"^>
        echo             ^<File Id="File1" Source="test1.txt" KeyPath="yes" /^>
        echo           ^</Component^>
        echo           ^<Component Id="Comp2" Guid="12345678-1234-1234-1234-123456789002"^>
        echo             ^<File Id="File2" Source="test2.txt" KeyPath="yes" /^>
        echo           ^</Component^>
        echo         ^</Directory^>
        echo       ^</Directory^>
        echo     ^</Directory^>
        echo     ^<Feature Id="Main" Title="Main" Level="1"^>
        echo       ^<ComponentRef Id="Comp1" /^>
        echo       ^<ComponentRef Id="Comp2" /^>
        echo     ^</Feature^>
        echo   ^</Product^>
        echo ^</Wix^>
    ) > "!TMP_TEST!\sample.wxs"

    pushd "!TMP_TEST!"
    candle.exe sample.wxs -out sample.wixobj >nul 2>&1
    light.exe -sval sample.wixobj -out sample.msi >nul 2>&1
    if not exist "sample.msi" (
        popd
        rmdir /s /q "!TMP_TEST!" 2>nul
        echo [FAIL] msi-rs roundtrip compilation failed to generate sample.msi >&2
        exit /b 1
    )
    where msiinfo.exe >nul 2>&1
    if not errorlevel 1 (
        msiinfo.exe tables sample.msi > tables.txt 2>nul
        findstr /C:"Component" tables.txt >nul 2>&1
        if errorlevel 1 (
            popd
            rmdir /s /q "!TMP_TEST!" 2>nul
            echo [FAIL] msiinfo tables inspection did not return standard Component table >&2
            exit /b 1
        )
        echo [PASS] msi-rs roundtrip compilation and msiinfo inspection verified
    ) else (
        echo [PASS] msi-rs roundtrip compilation verified (sample.msi generated)
    )
    popd
    rmdir /s /q "!TMP_TEST!" 2>nul
)

exit /b 0
