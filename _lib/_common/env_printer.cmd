@echo off
:: # env_printer.cmd
::
:: ## Overview
:: Environment variable exporter and formatting utility for LibScript on Windows.
:: Supports emitting single-component or manifest-wide environment configurations
:: in cmd, powershell, json, docker, and posix formats.
::
:: ## Usage
:: env_printer.cmd [FORMAT] [PREFIX_PATH] [COMP_DIR]
:: env_printer.cmd --manifest [MANIFEST_FILE] [FORMAT]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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

if /i "%~1"=="--hydrate" (
    set "MANIFEST_FILE=%~2"
    if "!MANIFEST_FILE!"=="" set "MANIFEST_FILE=libscript.json"
    call :hydrate_manifest "!MANIFEST_FILE!"
    endlocal & set "PATH=%PATH%"
    exit /b 0
)

if /i "%~1"=="--manifest" (
    set "MANIFEST_FILE=%~2"
    if "!MANIFEST_FILE!"=="" set "MANIFEST_FILE=libscript.json"
    set "FORMAT=%~3"
    if "!FORMAT!"=="" set "FORMAT=cmd"
    call :print_manifest "!MANIFEST_FILE!" "!FORMAT!"
    endlocal
    exit /b 0
)

set "FORMAT=%~1"
if "%FORMAT%"=="" set "FORMAT=cmd"
set "PREFIX_PATH=%~2"
set "TARGET_COMP_DIR=%~3"
if "%TARGET_COMP_DIR%"=="" set "TARGET_COMP_DIR=%COMP_DIR%"

if "%FORMAT%"=="dockerfile" set "FORMAT=docker"
if "%FORMAT%"=="envfile" set "FORMAT=docker_compose"
if "%FORMAT%"=="ps1" set "FORMAT=powershell"

if not "%PREFIX_PATH%"=="" (
    call :emit_path "!FORMAT!" "!PREFIX_PATH!\bin"
    if exist "!PREFIX_PATH!\Scripts" (
        call :emit_path "!FORMAT!" "!PREFIX_PATH!\Scripts"
    )
)

endlocal
exit /b 0

:: ## emit_path
:: Emits a PATH addition statement in the specified output format.
:emit_path
set "_FMT=%~1"
set "_BIN=%~2"
if "!_BIN!"=="" exit /b 0
if "!_FMT!"=="cmd" (
    echo echo %%PATH%% ^| findstr /i /c:"!_BIN!" ^>nul ^|^| SET "PATH=!_BIN!;!PATH!"
) else if "!_FMT!"=="powershell" (
    echo if ^($env:PATH -notlike '*!_BIN!*'^) {
    echo   $env:PATH = "!_BIN!;" + $env:PATH
    echo }
) else if "!_FMT!"=="docker" (
    set "FWD_BIN=!_BIN:\=/!"
    echo ENV PATH="!FWD_BIN!:$PATH"
) else if "!_FMT!"=="docker_compose" (
    set "FWD_BIN=!_BIN:\=/!"
    echo PATH=!FWD_BIN!:$PATH
) else if "!_FMT!"=="json" (
    set "ESCAPED_BIN=!_BIN:\=\!"
    echo { "PATH": "!ESCAPED_BIN!" }
) else (
    set "FWD_BIN=!_BIN:\=/!"
    echo if case ":$PATH:" in ^(*":!FWD_BIN!:"*^) false;; ^(*^) true;; esac; then
    echo   export PATH="!FWD_BIN!:$PATH"
    echo fi
)
exit /b 0

:: ## hydrate_manifest
:: Evaluates env.cmd for all dependencies declared in a manifest file.
:hydrate_manifest
set "_HM_JSON=%~1"
if not exist "!_HM_JSON!" exit /b 0
for %%F in ("!_HM_JSON!") do set "_HM_DIR=%%~dpF"
if exist "!_HM_DIR!\.env.libscript" (
    for /f "usebackq tokens=1* delims==" %%A in ("!_HM_DIR!\.env.libscript") do (
        if not "%%A"=="" if not "%%A:~0,1%"=="#" set "%%A=%%B"
    )
)
where jq >nul 2>&1
if errorlevel 1 exit /b 0
for /f "tokens=1,2" %%a in ('jq -r "(.dependencies // {}) | to_entries[]? | .key + " " + (if (.value | type) == "object" then (.value.version // "latest") elif (.value | type) == "string" then .value else "latest" end)" "!_HM_JSON!" 2^>nul') do (
    for /d %%C in ("!LIBSCRIPT_ROOT_DIR!\_lib\*") do (
        if exist "%%C\%%a\env.cmd" (
            set "STACK="
            call "%%C\%%a\env.cmd"
        )
    )
)
exit /b 0

:: ## print_manifest
:: Prints the combined environment statements for all dependencies in a manifest file.
:print_manifest
set "_PM_JSON=%~1"
set "_PM_FMT=%~2"
if not exist "!_PM_JSON!" exit /b 1
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
where jq >nul 2>&1
if errorlevel 1 exit /b 1
for /f "tokens=1,2" %%a in ('jq -r "(.dependencies // {}) | to_entries[]? | .key + " " + (if (.value | type) == "object" then (.value.version // "latest") elif (.value | type) == "string" then .value else "latest" end)" "!_PM_JSON!" 2^>nul') do (
    call :emit_path "!_PM_FMT!" "!LIBSCRIPT_HOME!\%%a\%%b\bin"
)
exit /b 0
