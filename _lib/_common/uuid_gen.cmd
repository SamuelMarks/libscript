@echo off
rem ## Overview
rem Deterministic UUIDv5 generator utility for LibScript Windows Installer packaging.
rem Generates reproducible GUIDs based on namespace and component name/version.
rem
rem ## Usage
rem   call _lib\_common\uuid_gen.cmd <NAMESPACE_UUID> <NAME>
rem
rem ## Parameters
rem   NAMESPACE_UUID  Base UUID namespace (e.g. 6ba7b810-9dad-11d1-80b4-00c04fd430c8)
rem   NAME            Unique string seed (e.g. "libscript.mysql.8.0.39")

setlocal enabledelayedexpansion

set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1 && (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "NAMESPACE=%~1"
set "SEED_NAME=%~2"

if "%NAMESPACE%"=="" (
    set "NAMESPACE=6ba7b810-9dad-11d1-80b4-00c04fd430c8"
)
if "%SEED_NAME%"=="" (
    echo Usage: %~nx0 [NAMESPACE_UUID] ^<NAME^> >&2
    exit /b 1
)

:: Prefer Python if available
where python >nul 2>nul
if %ERRORLEVEL% equ 0 (
    python -c "import uuid, sys; print(str(uuid.uuid5(uuid.UUID(sys.argv[1]), sys.argv[2])).upper())" "%NAMESPACE%" "%SEED_NAME%"
    exit /b 0
)

:: Prefer PowerShell if available
where powershell >nul 2>nul
if %ERRORLEVEL% equ 0 (
    powershell -NoProfile -Command ^
        "$ns = [Guid]::Parse('%NAMESPACE%'); $bytes = $ns.ToByteArray(); [Array]::Reverse($bytes, 0, 4); [Array]::Reverse($bytes, 4, 2); [Array]::Reverse($bytes, 6, 2); $nameBytes = [System.Text.Encoding]::UTF8.GetBytes('%SEED_NAME%'); $sha = [System.Security.Cryptography.SHA1]::Create(); $hash = $sha.ComputeHash($bytes + $nameBytes); $hash[6] = ($hash[6] -band 0x0f) -bor 0x50; $hash[8] = ($hash[8] -band 0x3f) -bor 0x80; [Array]::Reverse($hash, 0, 4); [Array]::Reverse($hash, 4, 2); [Array]::Reverse($hash, 6, 2); [Guid]::new($hash[0..15]).ToString().ToUpper()"
    exit /b 0
)

echo [ERROR] No Python or PowerShell available to generate UUID. >&2
exit /b 1
