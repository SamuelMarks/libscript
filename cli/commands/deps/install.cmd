@echo off
:: # install.cmd
::
:: ## Overview
:: Resolves and installs dependencies required by libscript components with reuse-else-create semantics.
:: 
:: ## Usage
:: Execute this script to fetch and setup required dependencies.

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

if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=!SCRIPT_DIR!\..\..\.."
)
set "json_file=libscript.json"
set "force_reinstall=0"
set "force_rebuild=0"
for %%A in (%2 %3 %4 %5 %6) do (
    set "_ia=%%~A"
    if /i "!_ia!"=="--force-reinstall" (
        set "force_reinstall=1"
        set "FORCE_REINSTALL=1"
    ) else if /i "!_ia!"=="--force-rebuild" (
        set "force_rebuild=1"
        set "FORCE_REBUILD=1"
    ) else if not "!_ia!"=="" (
        if not "!_ia:~0,1!"=="-" set "json_file=!_ia!"
    )
)
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
            set "LIBSCRIPT_SECRETS=!SCRIPT_DIR!\secrets"
        )
    )
)

if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" --hydrate "!json_file!"
)

call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\run_hooks.cmd" "!json_file!" "pre_install"

call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\resolve_stack.cmd" "!json_file!" > "!json_file!.resolved.json" 2>nul
REM Parallel Download Phase
echo Checking and downloading missing dependencies in parallel...
for /f "tokens=1,2,3" %%a in ('jq -r --arg def "latest" --arg empty "" ".selected[] | [.name, (.version // $def), (.override // $empty)] | @tsv" "!json_file!.resolved.json" 2^>nul') do (
    if "%%c"=="" (
        start "" /b cmd /c "call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" download "%%a" "%%b""
    ) else if "%%c"=="null" (
        start "" /b cmd /c "call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" download "%%a" "%%b""
    )
)

ping 127.0.0.1 -n 4 >nul

REM Serial Reuse-Else-Create Install Phase
echo Resolving dependencies ^(reuse-else-create^)...
for /f "tokens=1,2,3" %%a in ('jq -r --arg def "latest" --arg empty "" ".selected[] | [.name, (.version // $def), (.override // $empty)] | @tsv" "!json_file!.resolved.json" 2^>nul') do (
    set "has_override=0"
    if not "%%c"=="" (
        if not "%%c"=="null" set "has_override=1"
    )
    if "!has_override!"=="1" (
        echo Skipping installation of %%a ^(override provided: %%c^)
    ) else (
        set "_dep_reused=0"
        if "!force_reinstall!"=="0" (
            if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" (
                set "STACK="
                call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_check_installed_version "%%a" "%%b" >nul 2>&1
                if not errorlevel 1 set "_dep_reused=1"
            )
        )
        if "!_dep_reused!"=="1" (
            echo [REUSE] Dependency '%%a' ^(%%b^) is already installed; reusing existing installation.
        ) else (
            echo [CREATE] Installing missing dependency '%%a' ^(%%b^)...
            call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install "%%a" "%%b"
        )
    )
    for /d %%C in ("!LIBSCRIPT_ROOT_DIR!\_lib\*") do (
        if exist "%%C\%%a\env.cmd" (
            set "STACK="
            set "LIBSCRIPT_VERSION=%%b"
            call "%%C\%%a\env.cmd"
        )
    )
)
if exist "!json_file!.resolved.json" del "!json_file!.resolved.json"

for %%F in ("!json_file!") do set "_MANIFEST_DIR=%%~dpF"
if "!_MANIFEST_DIR:~-1!"=="\" set "_MANIFEST_DIR=!_MANIFEST_DIR:~0,-1!"
set "_ENV_OUT=!_MANIFEST_DIR!\.env.libscript"
if exist "!_ENV_OUT!" (
    findstr /v /b /c:"PATH=" /c:"SERVICE_PATH=" "!_ENV_OUT!" > "!_ENV_OUT!.tmp" 2>nul
    move /y "!_ENV_OUT!.tmp" "!_ENV_OUT!" >nul 2>&1
)
echo PATH=!PATH!>> "!_ENV_OUT!"
echo SERVICE_PATH=!PATH!>> "!_ENV_OUT!"

if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\python_env.cmd" (
    set "_PY_VER=3.12"
    for /f "delims=" %%V in ('jq -r "(.deps.python // .dependencies.python // \"3.12\")" "!json_file!" 2^>nul') do set "_PY_VER=%%V"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\python_env.cmd" libscript_python_ensure_venv_owner "!_MANIFEST_DIR!" "!_PY_VER!"
    for /d %%P in ("!_MANIFEST_DIR!\*") do (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\python_env.cmd" libscript_python_ensure_venv_owner "%%~fP" "!_PY_VER!"
    )
)

call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\run_hooks.cmd" "!json_file!" "install"
if errorlevel 1 exit /b 1

if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\provision_db.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\provision_db.cmd" "!json_file!"
    if errorlevel 1 exit /b 1
)

call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\run_hooks.cmd" "!json_file!" "post_install"
if errorlevel 1 exit /b 1
call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\run_hooks.cmd" "!json_file!" "db_migrate"
if errorlevel 1 exit /b 1
endlocal & (
    set "PATH=%PATH%"
    set "SERVICE_PATH=%PATH%"
    set "NODEJS_VERSION=%NODEJS_VERSION%"
    set "PYTHON_VERSION=%PYTHON_VERSION%"
    set "PYTHONHOME=%PYTHONHOME%"
    set "PYTHONPATH=%PYTHONPATH%"
    set "PYTHON_VENV=%PYTHON_VENV%"
    set "VIRTUAL_ENV=%VIRTUAL_ENV%"
    set "GOROOT=%GOROOT%"
    set "GO_VERSION=%GO_VERSION%"
    set "JAVA_HOME=%JAVA_HOME%"
    set "JAVA_VERSION=%JAVA_VERSION%"
    set "RUST_VERSION=%RUST_VERSION%"
    set "CARGO_HOME=%CARGO_HOME%"
    set "RUSTUP_HOME=%RUSTUP_HOME%"
    set "PHP_VERSION=%PHP_VERSION%"
    set "RUBY_VERSION=%RUBY_VERSION%"
    set "POSTGRES_VERSION=%POSTGRES_VERSION%"
    set "POSTGRESQL_VERSION=%POSTGRESQL_VERSION%"
    set "POSTGRES_URL=%POSTGRES_URL%"
    set "DATABASE_URL=%DATABASE_URL%"
    set "DUCKDB_PATH=%DUCKDB_PATH%"
    set "SQLITE_PATH=%SQLITE_PATH%"
    set "REDIS_URL=%REDIS_URL%"
    set "VALKEY_URL=%VALKEY_URL%"
)
exit /b 0
