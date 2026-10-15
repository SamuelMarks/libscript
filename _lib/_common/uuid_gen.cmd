@echo off
:: # uuid_gen.cmd
::
:: ## Overview
:: Deterministic UUIDv5 generator utility for LibScript Windows Installer packaging.
:: Generates reproducible GUIDs based on namespace and component name/version using
:: built-in Windows PowerShell or certutil without external interpreter dependencies.
::
:: ## Usage
:: uuid_gen.cmd [NAMESPACE_UUID] <NAME>

setlocal EnableDelayedExpansion
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
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

set "NAMESPACE=%~1"
set "SEED_NAME=%~2"

if not "%NAMESPACE%"=="" if "%SEED_NAME%"=="" (
    set "SEED_NAME=%~1"
    set "NAMESPACE=6ba7b810-9dad-11d1-80b4-00c04fd430c8"
)

if "%NAMESPACE%"=="" (
    set "NAMESPACE=6ba7b810-9dad-11d1-80b4-00c04fd430c8"
)
if "%SEED_NAME%"=="" (
    echo Usage: %~nx0 [NAMESPACE_UUID] ^<NAME^> >&2
    exit /b 1
)

call :generate_uuid_v5 "%NAMESPACE%" "%SEED_NAME%"
exit /b %ERRORLEVEL%

:: ## generate_uuid_v5
:: Generates an RFC 4122 UUIDv5 string using native Windows PowerShell SHA1 cryptography.
:generate_uuid_v5
where powershell >nul 2>nul
if %ERRORLEVEL% equ 0 (
    powershell -NoProfile -Command ^
        "$ns = [Guid]::Parse('%~1'); $bytes = $ns.ToByteArray(); [Array]::Reverse($bytes, 0, 4); [Array]::Reverse($bytes, 4, 2); [Array]::Reverse($bytes, 6, 2); $nameBytes = [System.Text.Encoding]::UTF8.GetBytes('%~2'); $sha = [System.Security.Cryptography.SHA1]::Create(); $hash = $sha.ComputeHash($bytes + $nameBytes); $hash[6] = ($hash[6] -band 0x0f) -bor 0x50; $hash[8] = ($hash[8] -band 0x3f) -bor 0x80; [Array]::Reverse($hash, 0, 4); [Array]::Reverse($hash, 4, 2); [Array]::Reverse($hash, 6, 2); [Guid]::new([byte[]]($hash[0..15])).ToString().ToUpper()"
    exit /b 0
)

where pwsh >nul 2>nul
if %ERRORLEVEL% equ 0 (
    pwsh -NoProfile -Command ^
        "$ns = [Guid]::Parse('%~1'); $bytes = $ns.ToByteArray(); [Array]::Reverse($bytes, 0, 4); [Array]::Reverse($bytes, 4, 2); [Array]::Reverse($bytes, 6, 2); $nameBytes = [System.Text.Encoding]::UTF8.GetBytes('%~2'); $sha = [System.Security.Cryptography.SHA1]::Create(); $hash = $sha.ComputeHash($bytes + $nameBytes); $hash[6] = ($hash[6] -band 0x0f) -bor 0x50; $hash[8] = ($hash[8] -band 0x3f) -bor 0x80; [Array]::Reverse($hash, 0, 4); [Array]::Reverse($hash, 4, 2); [Array]::Reverse($hash, 6, 2); [Guid]::new([byte[]]($hash[0..15])).ToString().ToUpper()"
    exit /b 0
)

echo [ERROR] Built-in Windows PowerShell is required to generate UUIDv5. >&2
exit /b 1
