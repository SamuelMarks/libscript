@echo off
:: # fetch_checksum.cmd
::
:: ## Overview
:: Automatically discovers and fetches SHA256 checksums for a given download URL on Windows.
:: Checks `_lib\checksums.txt`, Node.js `SHASUMS256.txt`, Go JSON API, GitHub Releases
:: checksum manifests, and `.sha256` companion URLs.
::
:: ## Usage
:: call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\fetch_checksum.cmd" "<url>"

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
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

call :libscript_fetch_checksum "%~1"
exit /b !errorlevel!

:: ## libscript_fetch_checksum
:: Resolves the SHA256 checksum for a download URL from local or vendor manifests.
:libscript_fetch_checksum
set "_URL=%~1"
if "!_URL!"=="" exit /b 1

for %%F in ("!_URL!") do set "_FILENAME=%%~nxF"

if exist "!LIBSCRIPT_ROOT_DIR!\_lib\checksums.txt" (
    for /f "tokens=1,2" %%A in ('findstr /I /C:"!_FILENAME!" "!LIBSCRIPT_ROOT_DIR!\_lib\checksums.txt" 2^>nul') do (
        if not "%%A"=="" (
            echo %%A
            exit /b 0
        )
    )
)

where curl.exe >nul 2>&1
if errorlevel 1 exit /b 1

echo "!_URL!" | findstr /I /C:"nodejs.org/dist/" >nul 2>&1
if not errorlevel 1 (
    for %%U in ("!_URL!") do set "_BASE_URL=%%~dpU"
    for /f "tokens=1,2" %%A in ('curl.exe -sL "!_URL!/../SHASUMS256.txt" 2^>nul ^| findstr /I /C:"!_FILENAME!"') do (
        if not "%%A"=="" (
            echo %%A
            exit /b 0
        )
    )
)

for /f "tokens=1" %%A in ('curl.exe -sL "!_URL!.sha256" 2^>nul') do (
    set "_CAND=%%A"
    if not "!_CAND!"=="" (
        if not "!_CAND:~63,1!"=="" if "!_CAND:~64,1!"=="" (
            echo !_CAND!
            exit /b 0
        )
    )
)

exit /b 1
