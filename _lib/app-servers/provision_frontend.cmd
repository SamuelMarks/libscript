@echo off
:: # provision_frontend.cmd
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

:: ## Overview
:: Declarative Frontend Orchestrator. Resolves NPM dependencies, compiles modern MFEs
:: via Webpack/Vite, executes monolithic static asset pipelines, and stages to webroots.
::
:: ## Usage
::   call provision_frontend.cmd --app-dir <dir> --manifest <path> --packaging <path>

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

set "APP_DIR="
set "MANIFEST_PATH="
set "PACKAGING_PATH="

:: ## parse_args
:: Parses command-line arguments and populates configuration variables.
:parse_args
if "%~1"=="" goto run_provision
if "%~1"=="--app-dir" ( set "APP_DIR=%~2" & shift & shift & goto parse_args )
if "%~1"=="--manifest" ( set "MANIFEST_PATH=%~2" & shift & shift & goto parse_args )
if "%~1"=="--packaging" ( set "PACKAGING_PATH=%~2" & shift & shift & goto parse_args )
shift
goto parse_args

:: ## run_provision
:: Performs the run_provision operation and updates component state.
:run_provision
if "%APP_DIR%"=="" ( echo Error: Missing app-dir >&2 & exit /b 1 )
if "%MANIFEST_PATH%"=="" ( echo Error: Missing manifest >&2 & exit /b 1 )
if "%PACKAGING_PATH%"=="" ( echo Error: Missing packaging >&2 & exit /b 1 )

set "WEBROOT_BASE=%APP_DIR%\webroot"
if not exist "%WEBROOT_BASE%" mkdir "%WEBROOT_BASE%"

:: 1. Dependency Resolution (MFE/Node pipelines)
if exist "%APP_DIR%\package.json" (
    pushd "%APP_DIR%"
    if exist "package-lock.json" (
        call npm ci --prefer-offline --no-audit
    ) else if exist "npm-shrinkwrap.json" (
        call npm ci --prefer-offline --no-audit
    ) else (
        call npm install --no-audit
    )
    popd
)

:: 2. MFE Compilation & 3. Monolithic Pipeline Mock
:: Note: True dynamic parsing requires PowerShell on Windows without jq.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Continue'; if (Get-Command 'jq' -ErrorAction SilentlyContinue) { $svcs = (jq -c '.services[]? | select(.type == \"static\")' '%PACKAGING_PATH%'); foreach ($svc in $svcs) { $id = ($svc | jq -r '.id'); $target = Join-Path '%WEBROOT_BASE%' $id; if (-not (Test-Path $target)) { New-Item -ItemType Directory -Path $target | Out-Null }; Write-Host 'Simulating MFE Build for:' $id } }"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Continue'; if (Get-Command 'jq' -ErrorAction SilentlyContinue) { $hooks = (jq -c '.lifecycle_hooks.pre_install[]?' '%PACKAGING_PATH%'); foreach ($hook in $hooks) { $cmd = ($hook | jq -r '.command'); if ($cmd -match 'collectstatic' -or $cmd -match 'paver') { Write-Host 'Simulating Monolithic Asset Collection:' $cmd } } }"

exit /b 0
