@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
:: # prepare_artifacts.cmd
::
:: ## Overview
:: Validates generated installer artifact packages and produces cryptographic
:: SHA256 checksums (.sha256) on Windows.
::
:: ## Usage
:: devtools\ci\prepare_artifacts.cmd <artifact_path> [artifact_path...]

if "%~1"=="" goto :no_args
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:: ## show_help
:: Displays usage instructions and supported command-line options.
:show_help
echo Usage: %~nx0 ^<artifact_path^> [artifact_path...]
echo Validates artifact files and produces companion .sha256 checksum files.
echo.
echo Options:
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:: ## no_args
:: Handles missing artifact path arguments error.
:no_args
echo [ERROR] No artifact paths specified. >&2
call :show_help >&2
exit /b 1

:: ## main
:: Iterates over all artifact file paths passed on the command line.
:main
set "ERRORS=0"
:process_loop
if "%~1"=="" goto :finish
call :process_single "%~1"
if %ERRORLEVEL% neq 0 set /a ERRORS+=1
shift
goto :process_loop

:: ## process_single
:: Verifies an artifact file exists and produces its SHA256 hash.
:process_single
set "TARGET_FILE=%~f1"
set "FILE_NAME=%~nx1"
set "SHA_FILE=%TARGET_FILE%.sha256"

if not exist "%TARGET_FILE%" (
    echo [ERROR] Artifact not found: %TARGET_FILE% >&2
    exit /b 1
)

:: Get file size
for %%A in ("%TARGET_FILE%") do set "FILE_SIZE=%%~zA"
if "%FILE_SIZE%"=="0" (
    echo [ERROR] Artifact file is empty: %TARGET_FILE% >&2
    exit /b 1
)

set "SHA256_HASH="
:: Prefer PowerShell Get-FileHash if available
where powershell >nul 2>&1
if %ERRORLEVEL% equ 0 (
    for /f "usebackq delims=" %%H in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-FileHash -Path '%TARGET_FILE%' -Algorithm SHA256).Hash.ToLower()"`) do (
        set "SHA256_HASH=%%H"
    )
)

:: Fallback to certutil if powershell not available or failed
if not defined SHA256_HASH (
    where certutil >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        for /f "tokens=* skip=1" %%H in ('certutil -hashfile "%TARGET_FILE%" SHA256 2^>nul') do (
            if not defined SHA256_HASH (
                set "line=%%H"
                if not "!line:CertUtil=!"=="!line!" goto :skip_hash
                set "SHA256_HASH=!line: =!"
            )
        )
    )
)
:skip_hash

if not defined SHA256_HASH (
    echo [ERROR] Unable to compute SHA256 hash for %TARGET_FILE% >&2
    exit /b 1
)

> "%SHA_FILE%" echo %SHA256_HASH%  %FILE_NAME%
echo [INFO] Successfully prepared: %TARGET_FILE% (%FILE_SIZE% bytes, SHA256: %SHA256_HASH%)
exit /b 0

:: ## finish
:: Concludes execution and exits with aggregate error status.
:finish
if %ERRORS% gtr 0 exit /b 1
exit /b 0
