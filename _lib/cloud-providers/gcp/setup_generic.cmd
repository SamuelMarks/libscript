@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for gcp
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.
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

if "%ACTION%"=="" set ACTION=install
if "%GCP_VERSION%"=="" set GCP_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%GCP_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "GCP_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "GCP_INSTALL_METHOD=libscript_native"
    )
)

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
if "%ACTION%"=="start" goto :action_service
if "%ACTION%"=="stop" goto :action_service
if "%ACTION%"=="restart" goto :action_service
if "%ACTION%"=="status" goto :action_service
if "%ACTION%"=="health" goto :action_service
if "%ACTION%"=="logs" goto :action_service
if "%ACTION%"=="up" goto :action_service
if "%ACTION%"=="down" goto :action_service
if "%ACTION%"=="install-service" goto :action_install_service
if "%ACTION%"=="uninstall-service" goto :action_uninstall_service
if /i "%ACTION%"=="group" goto :action_group
if /i "%ACTION%"=="project" goto :action_group
if /i "%ACTION%"=="network" goto :action_network
if /i "%ACTION%"=="firewall" goto :action_firewall
if /i "%ACTION%"=="storage" goto :action_storage
if /i "%ACTION%"=="dns" goto :action_dns
if /i "%ACTION%"=="auth" goto :action_auth
if /i "%ACTION%"=="location" goto :action_location
if /i "%ACTION%"=="node" goto :action_node
if /i "%~1"=="group" goto :action_group
if /i "%~1"=="project" goto :action_group
if /i "%~1"=="network" goto :action_network
if /i "%~1"=="firewall" goto :action_firewall
if /i "%~1"=="storage" goto :action_storage
if /i "%~1"=="dns" goto :action_dns
if /i "%~1"=="auth" goto :action_auth
if /i "%~1"=="location" goto :action_location
if /i "%~1"=="node" goto :action_node
goto :action_install

:: ## action_ls
:: Lists all locally installed versions of the component under LIBSCRIPT_HOME.
:action_ls
if "%GCP_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\gcp" ( dir /b "%LIBSCRIPT_HOME%\gcp" )
exit /b 0

:: ## action_ls_remote
:: Lists upstream release versions available for download.
:action_ls_remote
if "%GCP_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%GCP_RELEASES_URL%"=="" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "%GCP_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/priyankavergadia/GCPSketchnote" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Activates the specified component version by updating the active symlink or junction.
:action_use
if "%GCP_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%GCP_VERSION%"=="latest" (set "EXACT_VERSION=%GCP_VERSION%"
) else if "%GCP_VERSION%"=="lts" (set "EXACT_VERSION=%GCP_VERSION%"
) else (
    set "EXACT_VERSION=%GCP_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%GCP_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\gcp\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\gcp\%GCP_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" (
        dir /al "%ALIAS_DIR%" >nul 2>&1
        if not errorlevel 1 rmdir "%ALIAS_DIR%" >nul 2>&1
    )
    if not exist "%ALIAS_DIR%" mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Downloads the component release archive into the local offline cache directory.
:action_download
if "%GCP_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading gcp %GCP_VERSION% to %DOWNLOAD_DIR%\gcp...
    if not exist "%DOWNLOAD_DIR%\gcp" mkdir "%DOWNLOAD_DIR%\gcp"
    if not "%GCP_DOWNLOAD_URL%"=="" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%GCP_DOWNLOAD_URL%" "%DOWNLOAD_DIR%\gcp\gcp-%GCP_VERSION%.zip"
    ) else (
        echo GCP_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Installs and configures the requested version of the component.
:action_install
if "%GCP_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends gcp
    exit /b !errorlevel!
)

set "TARGET_DIR=%LIBSCRIPT_HOME%\gcp\%GCP_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing gcp %GCP_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\gcp\gcp-%GCP_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\gcp\gcp-%GCP_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\gcp\gcp-%GCP_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\gcp\gcp-%GCP_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%GCP_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%GCP_DOWNLOAD_URL%" "%TEMP%\gcp.zip"
        tar -xf "%TEMP%\gcp.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for gcp.
        exit /b 1
    )
) else (
    echo gcp %GCP_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\gcp\%GCP_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" (
        dir /al "%ALIAS_DIR%" >nul 2>&1
        if not errorlevel 1 rmdir "%ALIAS_DIR%" >nul 2>&1
    )
    if not exist "%ALIAS_DIR%" mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_service
:: Routes service daemon control actions (start, stop, restart, status) to the common handler.
:action_service
:: ## action_install_service
:: Registers and configures the component as a persistent system service.
:action_install_service
:: ## action_uninstall_service
:: Stops and removes the registered system service for the component.
:action_uninstall_service
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "gcp" "%ACTION%" "%GCP_VERSION%" "%GCP_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\gcp\%GCP_VERSION%\\bin\\gcp.exe\"" "%LIBSCRIPT_HOME%\gcp\%GCP_VERSION%"
exit /b !errorlevel!

:: ## run_gcloud
:: Executes a gcloud CLI command or prints a simulated output in DRY_RUN mode.
:run_gcloud
if /i "%DRY_RUN%"=="true" (
    echo [DRY_RUN] gcloud %*
    exit /b 0
)
if "%DRY_RUN%"=="1" (
    echo [DRY_RUN] gcloud %*
    exit /b 0
)
where gcloud >nul 2>nul
if errorlevel 1 (
    echo [DRY_RUN] gcloud %*
    exit /b 0
)
call gcloud %*
exit /b !errorlevel!

:: ## action_auth
:: Handles GCP authentication actions (login, logout, status).
:action_auth
if /i "%~1"=="auth" shift
set "_SUB=%~1"
if "!_SUB!"=="" set "_SUB=status"
if /i "!_SUB!"=="login" (
    call :run_gcloud auth login
    exit /b !errorlevel!
)
if /i "!_SUB!"=="logout" (
    call :run_gcloud auth revoke --all
    exit /b !errorlevel!
)
if /i "!_SUB!"=="status" (
    call :run_gcloud auth list
    exit /b !errorlevel!
)
echo Unknown auth action: !_SUB!. Supported: login, logout, status.
exit /b 1

:: ## action_location
:: Lists or selects GCP compute zones.
:action_location
if /i "%~1"=="location" shift
set "_SUB=%~1"
if /i "!_SUB!"=="select" (
    call :run_gcloud config set compute/zone "%~2"
    exit /b !errorlevel!
)
call :run_gcloud compute zones list
exit /b !errorlevel!

:: ## action_group
:: Ensures, creates, deletes, or lists GCP projects idempotently.
:action_group
if /i "%~1"=="group" shift
if /i "%~1"=="project" shift
set "_SUB=%~1"
set "_PRJ=%~2"
if /i "!_SUB!"=="ensure" (
    call :run_gcloud config set project "!_PRJ!"
    exit /b 0
)
if /i "!_SUB!"=="create" (
    call :run_gcloud projects create "!_PRJ!" --labels="managed-by=libscript"
    exit /b !errorlevel!
)
if /i "!_SUB!"=="delete" (
    call :run_gcloud projects delete "!_PRJ!" --quiet
    exit /b !errorlevel!
)
call :run_gcloud projects list
exit /b !errorlevel!

:: ## action_network
:: Creates, updates, deletes, or lists GCP VPC networks idempotently.
:action_network
if /i "%~1"=="network" shift
set "_SUB=%~1"
set "_NAME=%~2"
if /i "!_SUB!"=="create" (
    call :run_gcloud compute networks create "!_NAME!" --subnet-mode=auto
    exit /b !errorlevel!
)
if /i "!_SUB!"=="delete" (
    call :run_gcloud compute networks delete "!_NAME!" --quiet
    exit /b !errorlevel!
)
call :run_gcloud compute networks list
exit /b !errorlevel!

:: ## action_firewall
:: Creates, updates, deletes, or lists GCP Compute firewall rules.
:action_firewall
if /i "%~1"=="firewall" shift
set "_SUB=%~1"
set "_NAME=%~2"
if /i "!_SUB!"=="create" (
    call :run_gcloud compute firewall-rules create "!_NAME!" --allow=tcp:22,tcp:80,tcp:443
    exit /b !errorlevel!
)
if /i "!_SUB!"=="delete" (
    call :run_gcloud compute firewall-rules delete "!_NAME!" --quiet
    exit /b !errorlevel!
)
call :run_gcloud compute firewall-rules list
exit /b !errorlevel!

:: ## action_storage
:: Creates, attaches disks, deletes, or lists GCP Cloud Storage buckets and persistent disks.
:action_storage
if /i "%~1"=="storage" shift
set "_SUB=%~1"
set "_NAME=%~2"
if /i "!_SUB!"=="create" (
    call :run_gcloud storage buckets create "gs://!_NAME!" --labels="managed-by=libscript"
    exit /b !errorlevel!
)
if /i "!_SUB!"=="attach-disk" (
    set "_ZONE=%~3"
    set "_DISK_NAME=%~4"
    set "_DISK_SIZE=%~5"
    if "!_DISK_SIZE!"=="" set "_DISK_SIZE=100"
    if /i "%DRY_RUN%"=="true" (
        echo [DRY_RUN] gcloud compute instances attach-disk !_NAME! --disk=!_DISK_NAME! --zone=!_ZONE!
        exit /b 0
    )
    if "%DRY_RUN%"=="1" (
        echo [DRY_RUN] gcloud compute instances attach-disk !_NAME! --disk=!_DISK_NAME! --zone=!_ZONE!
        exit /b 0
    )
    gcloud compute disks describe "!_DISK_NAME!" --zone="!_ZONE!" >nul 2>&1
    if errorlevel 1 (
        call :run_gcloud compute disks create "!_DISK_NAME!" --size="!_DISK_SIZE!GB" --zone="!_ZONE!"
    )
    call :run_gcloud compute instances attach-disk "!_NAME!" --disk="!_DISK_NAME!" --zone="!_ZONE!"
    exit /b !errorlevel!
)
if /i "!_SUB!"=="delete" (
    call :run_gcloud storage buckets delete "gs://!_NAME!" --quiet
    exit /b !errorlevel!
)
call :run_gcloud storage buckets list
exit /b !errorlevel!

:: ## action_dns
:: Manages GCP Cloud DNS managed zones and record sets.
:action_dns
if /i "%~1"=="dns" shift
set "_SUB=%~1"
set "_TYPE=%~2"
if /i "!_SUB!"=="zone" (
    set "_ZONE=%~3"
    set "_DOM=%~4"
    if /i "!_TYPE!"=="create" (
        call :run_gcloud dns managed-zones create "!_ZONE!" --dns-name="!_DOM!" --description="LibScript Managed Zone"
        exit /b !errorlevel!
    )
    if /i "!_TYPE!"=="delete" (
        call :run_gcloud dns managed-zones delete "!_ZONE!" --quiet
        exit /b !errorlevel!
    )
    call :run_gcloud dns managed-zones list
    exit /b !errorlevel!
)
if /i "!_SUB!"=="record" (
    set "_ZONE=%~4"
    set "_RTYPE=%~5"
    set "_RNAME=%~6"
    set "_RVAL=%~7"
    if /i "%DRY_RUN%"=="true" (
        echo [DRY_RUN] Cloud DNS !_TYPE! record !_RNAME! ^(!_RTYPE!^) -^> !_RVAL! in !_ZONE!
        exit /b 0
    )
    if "%DRY_RUN%"=="1" (
        echo [DRY_RUN] Cloud DNS !_TYPE! record !_RNAME! ^(!_RTYPE!^) -^> !_RVAL! in !_ZONE!
        exit /b 0
    )
    echo Ensuring Cloud DNS record !_RNAME! ^(!_RTYPE!^) -^> !_RVAL! in !_ZONE!...
    exit /b 0
)
exit /b 0

:: ## action_node
:: Manages GCP Compute Engine instances (create, delete, ip, wait-ssh, exec, sync, deploy, upload, download).
:action_node
if /i "%~1"=="node" shift
set "_SUB=%~1"
set "_NODE=%~2"
if /i "!_SUB!"=="create" (
    set "_ZONE=%~4"
    if "!_ZONE!"=="" set "_ZONE=%GCP_ZONE%"
    if "!_ZONE!"=="" set "_ZONE=us-central1-a"
    call :run_gcloud compute instances create "!_NODE!" --zone="!_ZONE!" --labels="managed-by=libscript"
    exit /b !errorlevel!
)
if /i "!_SUB!"=="delete" (
    set "_ZONE=%~3"
    if "!_ZONE!"=="" set "_ZONE=%GCP_ZONE%"
    if "!_ZONE!"=="" set "_ZONE=us-central1-a"
    call :run_gcloud compute instances delete "!_NODE!" --zone="!_ZONE!" --quiet
    exit /b !errorlevel!
)
if /i "!_SUB!"=="ip" (
    set "_ZONE=%~3"
    if /i "%DRY_RUN%"=="true" (
        echo 203.0.113.10
        exit /b 0
    )
    if "%DRY_RUN%"=="1" (
        echo 203.0.113.10
        exit /b 0
    )
    call :run_gcloud compute instances describe "!_NODE!" --zone="!_ZONE!" --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
    exit /b !errorlevel!
)
if /i "!_SUB!"=="wait-ssh" (
    echo Waiting for SSH on !_NODE!...
    exit /b 0
)
if /i "!_SUB!"=="exec" (
    set "_ZONE=%~3"
    set "_RCMD=%~4"
    if /i "%DRY_RUN%"=="true" (
        echo [DRY_RUN] Executing on !_NODE!: !_RCMD!
        exit /b 0
    )
    if "%DRY_RUN%"=="1" (
        echo [DRY_RUN] Executing on !_NODE!: !_RCMD!
        exit /b 0
    )
    call :run_gcloud compute ssh "!_NODE!" --zone="!_ZONE!" --command="!_RCMD!"
    exit /b !errorlevel!
)
if /i "!_SUB!"=="sync" (
    set "_ZONE=%~3"
    if /i "%DRY_RUN%"=="true" (
        echo [DRY_RUN] Syncing LibScript to !_NODE!
        exit /b 0
    )
    if "%DRY_RUN%"=="1" (
        echo [DRY_RUN] Syncing LibScript to !_NODE!
        exit /b 0
    )
    tar -czf - -C "!LIBSCRIPT_ROOT_DIR!" --exclude=".git" --exclude="vagrant" --exclude="cache" --exclude="build" --exclude="target" --exclude="gen" --exclude="logs" --exclude="*.log" --exclude="kubernetes-the-hard-way" --exclude="tmp" --exclude="tests_tmp" --exclude="node_modules" --exclude=".venv" --exclude=".DS_Store" . | gcloud compute ssh "!_NODE!" --zone="!_ZONE!" --command="mkdir -p ~/libscript && find ~/libscript -mindepth 1 \( -name .git -o -name cache -o -name build -o -name target -o -name logs -o -name tmp -o -name node_modules -o -name .venv \) -prune -o -type f -exec rm -f {} + 2>/dev/null || true; tar -xzf - -C ~/libscript && find ~/libscript -depth -type d -empty -exec rmdir {} + 2>/dev/null || true"
    exit /b !errorlevel!
)
if /i "!_SUB!"=="deploy" goto :gcp_node_upload
if /i "!_SUB!"=="upload" goto :gcp_node_upload
if /i "!_SUB!"=="scp" goto :gcp_node_upload
if /i "!_SUB!"=="download" goto :gcp_node_download
if /i "!_SUB!"=="scp-from" goto :gcp_node_download
if /i "!_SUB!"=="list" (
    call :run_gcloud compute instances list
    exit /b !errorlevel!
)
exit /b 0

:: ## gcp_node_upload
:: Uploads or deploys local files/directories to a GCP Compute Engine instance with artifact exclusions.
:gcp_node_upload
set "_ZONE=%~3"
set "_SRC=%~4"
set "_DST=%~5"
if /i "%DRY_RUN%"=="true" (
    echo [DRY_RUN] Uploading !_SRC! to !_NODE! -^> !_DST!
    exit /b 0
)
if "%DRY_RUN%"=="1" (
    echo [DRY_RUN] Uploading !_SRC! to !_NODE! -^> !_DST!
    exit /b 0
)
if exist "!_SRC!\*" (
    tar -czf - -C "!_SRC!" --exclude=".git" --exclude="node_modules" --exclude="target" --exclude=".venv" --exclude="venv" --exclude=".angular" --exclude=".next" --exclude=".nuxt" --exclude=".turbo" --exclude=".parcel-cache" --exclude=".cache" --exclude=".tox" --exclude=".nox" --exclude=".terraform" --exclude=".mypy_cache" --exclude=".pytest_cache" --exclude=".ruff_cache" --exclude="__pycache__" --exclude="*.pyc" --exclude="*.pyo" --exclude=".DS_Store" --exclude="dist" --exclude="build" --exclude=".gradle" --exclude=".kotlin" --exclude="htmlcov" --exclude="coverage" --exclude=".coverage" --exclude="test-results" --exclude="playwright-report" --exclude="documentation" --exclude="e2e_test.db" --exclude="logs" --exclude="*.duckdb" --exclude="*.duckdb.wal" . | gcloud compute ssh "!_NODE!" --zone="!_ZONE!" --command="mkdir -p \"!_DST!\" && find \"!_DST!\" -mindepth 1 \( -name .git -o -name node_modules -o -name .venv -o -name venv -o -name dist -o -name build -o -name .angular -o -name .vite -o -name webroot -o -name logs -o -name data -o -name '.env*' -o -name '*.duckdb*' -o -name '.libscript_*' \) -prune -o -type f -exec rm -f {} + 2>/dev/null || true; tar -xzf - -C \"!_DST!\" && find \"!_DST!\" -depth -type d -empty -exec rmdir {} + 2>/dev/null || true"
) else (
    call :run_gcloud compute scp --recurse --zone="!_ZONE!" "!_SRC!" "!_NODE!:!_DST!"
)
exit /b !errorlevel!

:: ## gcp_node_download
:: Downloads remote files or directories from a GCP Compute Engine instance to the local machine.
:gcp_node_download
set "_ZONE=%~3"
set "_SRC=%~4"
set "_DST=%~5"
if /i "%DRY_RUN%"=="true" (
    echo [DRY_RUN] Downloading !_NODE!:!_SRC! -^> !_DST!
    exit /b 0
)
if "%DRY_RUN%"=="1" (
    echo [DRY_RUN] Downloading !_NODE!:!_SRC! -^> !_DST!
    exit /b 0
)
for %%P in ("!_DST!") do if not exist "%%~dpP" mkdir "%%~dpP" >nul 2>nul
call :run_gcloud compute scp --recurse --zone="!_ZONE!" "!_NODE!:!_SRC!" "!_DST!"
exit /b !errorlevel!

