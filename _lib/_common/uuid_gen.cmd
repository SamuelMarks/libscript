@echo off
:: # uuid_gen.cmd
:: ## Overview
:: Deterministic RFC 4122 UUIDv5 generator utility for LibScript Windows Installer packaging.
:: Generates reproducible GUIDs based on namespace and component name/version using native Win32
:: `certutil` SHA-1 hashing (zero PowerShell dependency), with `openssl` and PowerShell fallbacks.
:: ## Usage
:: uuid_gen.cmd [NAMESPACE_UUID] <NAME>

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        if "%LIBSCRIPT_DEBUG%"=="1" echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI"

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

:: ## format_sha1_uuidv5
:: Formats a 40-char hex SHA-1 digest into an uppercase RFC 4122 UUIDv5 string.
:format_sha1_uuidv5
set "_HEX=%~1"
set "_HEX=!_HEX: =!"
set "_C16=!_HEX:~16,1!"
set "_VARIANT=8"
if /i "!_C16!"=="0" set "_VARIANT=8"
if /i "!_C16!"=="4" set "_VARIANT=8"
if /i "!_C16!"=="8" set "_VARIANT=8"
if /i "!_C16!"=="c" set "_VARIANT=8"
if /i "!_C16!"=="1" set "_VARIANT=9"
if /i "!_C16!"=="5" set "_VARIANT=9"
if /i "!_C16!"=="9" set "_VARIANT=9"
if /i "!_C16!"=="d" set "_VARIANT=9"
if /i "!_C16!"=="2" set "_VARIANT=A"
if /i "!_C16!"=="6" set "_VARIANT=A"
if /i "!_C16!"=="a" set "_VARIANT=A"
if /i "!_C16!"=="e" set "_VARIANT=A"
if /i "!_C16!"=="3" set "_VARIANT=B"
if /i "!_C16!"=="7" set "_VARIANT=B"
if /i "!_C16!"=="b" set "_VARIANT=B"
if /i "!_C16!"=="f" set "_VARIANT=B"
set "_UUID=!_HEX:~0,8!-!_HEX:~8,4!-5!_HEX:~13,3!-!_VARIANT!!_HEX:~17,3!-!_HEX:~20,12!"
set "_UUID=!_UUID:a=A!"
set "_UUID=!_UUID:b=B!"
set "_UUID=!_UUID:c=C!"
set "_UUID=!_UUID:d=D!"
set "_UUID=!_UUID:e=E!"
set "_UUID=!_UUID:f=F!"
echo !_UUID!
exit /b 0

:: ## generate_uuid_v5
:: Generates an RFC 4122 UUIDv5 string using native Windows certutil SHA-1 or PowerShell fallback.
:generate_uuid_v5
set "_NS_RAW=%~1"
set "_SEED=%~2"
set "_NS_HEX=!_NS_RAW:-=!"

where certutil >nul 2>nul
if %ERRORLEVEL% equ 0 (
    set "_TMP_BASE=%TEMP%\ls_uuid_%RANDOM%_%RANDOM%"
    <nul set /p ="!_SEED!" > "!_TMP_BASE!.seed"
    certutil -encodehex -f "!_TMP_BASE!.seed" "!_TMP_BASE!.seed.hex" 12 >nul 2>&1
    set "_SEED_HEX="
    if exist "!_TMP_BASE!.seed.hex" (
        for /f "usebackq delims=" %%H in ("!_TMP_BASE!.seed.hex") do set "_SEED_HEX=!_SEED_HEX!%%H"
    )
    > "!_TMP_BASE!.in.hex" echo !_NS_HEX!!_SEED_HEX!
    certutil -decodehex -f "!_TMP_BASE!.in.hex" "!_TMP_BASE!.in.bin" >nul 2>&1
    set "_SHA1="
    if exist "!_TMP_BASE!.in.bin" (
        for /f "skip=1 delims=" %%S in ('certutil -hashfile "!_TMP_BASE!.in.bin" SHA1 2^>nul') do (
            if not defined _SHA1 set "_SHA1=%%S"
        )
    )
    del /f /q "!_TMP_BASE!.seed" "!_TMP_BASE!.seed.hex" "!_TMP_BASE!.in.hex" "!_TMP_BASE!.in.bin" >nul 2>&1
    if defined _SHA1 (
        set "_SHA1=!_SHA1: =!"
        if not "!_SHA1:~39,1!"=="" (
            call :format_sha1_uuidv5 "!_SHA1!"
            exit /b 0
        )
    )
)

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

echo [ERROR]Neither certutil nor PowerShell is available to generate UUIDv5. >&2
exit /b 1
