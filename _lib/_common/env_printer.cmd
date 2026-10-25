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
    endlocal & (
        set "PATH=%PATH%"
        set "LIBSCRIPT_HOME=%LIBSCRIPT_HOME%"
        set "NODEJS_VERSION=%NODEJS_VERSION%"
        set "PYTHON_VERSION=%PYTHON_VERSION%"
        set "PYTHONHOME=%PYTHONHOME%"
        set "PYTHONPATH=%PYTHONPATH%"
        set "PYTHON_VENV=%PYTHON_VENV%"
        set "VIRTUAL_ENV=%VIRTUAL_ENV%"
        set "UV_VERSION=%UV_VERSION%"
        set "UV_BIN=%UV_BIN%"
        set "NPX_BIN=%NPX_BIN%"
        set "POSTGRES_VERSION=%POSTGRES_VERSION%"
        set "POSTGRESQL_VERSION=%POSTGRESQL_VERSION%"
        set "POSTGRES_USER=%POSTGRES_USER%"
        set "POSTGRES_PASSWORD=%POSTGRES_PASSWORD%"
        set "POSTGRES_HOST=%POSTGRES_HOST%"
        set "POSTGRES_PORT=%POSTGRES_PORT%"
        set "POSTGRES_DB=%POSTGRES_DB%"
        set "POSTGRES_URL=%POSTGRES_URL%"
        set "DATABASE_URL=%DATABASE_URL%"
        set "DUCKDB_PATH=%DUCKDB_PATH%"
        set "SQLITE_PATH=%SQLITE_PATH%"
        set "REDIS_URL=%REDIS_URL%"
        set "VALKEY_URL=%VALKEY_URL%"
    )
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
if "!_HM_DIR:~-1!"=="\" set "_HM_DIR=!_HM_DIR:~0,-1!"
for %%E in ("!_HM_DIR!\.env" "!_HM_DIR!\.env.secrets" "!_HM_DIR!\.env.libscript") do (
    if exist "%%~fE" (
        for /f "usebackq tokens=1* delims==" %%A in ("%%~fE") do (
            if not "%%A"=="" if not "%%A:~0,1%"=="#" (
                if not defined %%A set "%%A=%%~B"
            )
        )
    )
)
where jq >nul 2>&1
if errorlevel 1 exit /b 0
set "_HM_TMP=%TEMP%\libscript_hm_!RANDOM!.txt"
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\resolve_stack.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\resolve_stack.cmd" "!_HM_JSON!" > "!_HM_TMP!.json" 2>nul
    jq -r ".selected[]? | .name + \" \" + (.version // \"latest\")" "!_HM_TMP!.json" > "!_HM_TMP!" 2>nul
    if exist "!_HM_TMP!.json" del /q "!_HM_TMP!.json" >nul 2>&1
)
for %%S in ("!_HM_TMP!") do set "_HM_SIZE=%%~zS"
if "!_HM_SIZE!"=="" set "_HM_SIZE=0"
if "!_HM_SIZE!"=="0" (
    jq -r "((.dependencies // {}) | if type == \"object\" then to_entries[]? | select(.key != \"runtime\" and .key != \"build\" and .key != \"optional\") | .key + \" \" + (if (.value | type) == \"object\" then (.value.version // \"latest\") elif (.value | type) == \"string\" then .value else \"latest\" end) else empty end), ((.databases // .infrastructure.databases) | if type == \"object\" then to_entries[]? | (.value.engine // .value.type // \"postgres\") + \" \" + (.value.version // \"latest\") elif type == \"array\" then .[]? | (.engine // .type // \"postgres\") + \" \" + (.version // \"latest\") else empty end)" "!_HM_JSON!" > "!_HM_TMP!" 2>nul
)
if exist "!_HM_TMP!" (
    for /f "usebackq tokens=1,2" %%a in ("!_HM_TMP!") do (
        set "LIBSCRIPT_VERSION=%%b"
        for /d %%C in ("!LIBSCRIPT_ROOT_DIR!\_lib\*") do (
            if exist "%%C\%%a\env.cmd" (
                set "STACK="
                call "%%C\%%a\env.cmd"
            )
        )
    )
    del /q "!_HM_TMP!" >nul 2>&1
)
if "!UV_BIN!"=="" set "UV_BIN=uv"
if "!NPX_BIN!"=="" set "NPX_BIN=npx"
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
set "_OLD_PATH=!PATH!"
call :hydrate_manifest "!_PM_JSON!"
for %%P in ("!PATH:;=" "!") do (
    set "_P_ITEM=%%~P"
    if not "!_P_ITEM!"=="" (
        echo ";!_OLD_PATH!;" | findstr /I /C:";!_P_ITEM!;" >nul 2>&1
        if errorlevel 1 (
            call :emit_path "!_PM_FMT!" "!_P_ITEM!"
        )
    )
)
exit /b 0
