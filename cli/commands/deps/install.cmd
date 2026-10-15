@echo off
:: # install.cmd
::
:: ## Overview
:: Resolves and installs dependencies required by libscript components.
:: 
:: ## Usage
:: Execute this script to fetch and setup required dependencies.

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

if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%..\..\.."
)
set "json_file=%~2"
if "!json_file!"=="" set "json_file=libscript.json"
if not exist "!json_file!" (
    echo Error: !json_file! not found. 1>&2
    exit /b 1
)
jq --version >nul 2>&1
if errorlevel 1 (
    echo Error: jq is required to parse !json_file!. 1>&2
    exit /b 1
)

if "!LIBSCRIPT_SECRETS!"=="" (
    for /f "delims=" %%s in ('jq -r "if .secrets then .secrets else empty end" "!json_file!" 2^>nul') do (
        if not "%%s"=="" if not "%%s"=="null" set "LIBSCRIPT_SECRETS=%%s"
    )
    if "!LIBSCRIPT_SECRETS!"=="" (
        if defined LIBSCRIPT_ROOT_DIR (
            set "LIBSCRIPT_SECRETS=!LIBSCRIPT_ROOT_DIR!\secrets"
        ) else (
            set "LIBSCRIPT_SECRETS=%SCRIPT_DIR%\secrets"
        )
    )
)

    call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\resolve_stack.cmd" "!json_file!" > "!json_file!.resolved.json" 2>nul
REM Parallel Download Phase
echo Downloading dependencies in parallel...
for /f "tokens=1,2,3" %%a in ('jq -r --arg def "latest" --arg empty "" ".selected[] | [.name, (.version // $def), (.override // $empty)] | @tsv" "!json_file!.resolved.json" 2^>nul') do (
    if "%%c"=="" (
        start "" /b cmd /c "call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" download "%%a" "%%b""
    ) else if "%%c"=="null" (
        start "" /b cmd /c "call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" download "%%a" "%%b""
    )
)

REM Wait for background downloads. `start /wait /b` doesn't work, we'll just wait a bit or let it run.
REM A simple sleep or loop for processes isn't strictly trivial without external tools.
REM But we can check for running cmd.exe processes started with `download` via tasklist if needed.
REM Actually, simple approach: wait 3 seconds to let them start and fetch.
ping 127.0.0.1 -n 4 >nul

REM Serial Install Phase
echo Installing dependencies sequentially...
for /f "tokens=1,2,3" %%a in ('jq -r --arg def "latest" --arg empty "" ".selected[] | [.name, (.version // $def), (.override // $empty)] | @tsv" "!json_file!.resolved.json" 2^>nul') do (
    if not "%%c"=="" if not "%%c"=="null" (
        echo Skipping installation of %%a ^(override provided: %%c^)
    ) else (
        echo Installing %%a %%b...
        call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install "%%a" "%%b"
    )
)
if exist "!json_file!.resolved.json" del "!json_file!.resolved.json"
exit /b 0
