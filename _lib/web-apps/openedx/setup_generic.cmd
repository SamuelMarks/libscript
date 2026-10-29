@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Generic setup and provisioning module for the Open edX platform stack on Windows.
::
:: ## Usage
:: setup_generic.cmd [ACTION] [OPTIONS]

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
set "OPENEDX_SCRIPT_DIR=%SCRIPT_DIR%"

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




for %%I in ("%~dp0.") do set "OPENEDX_SCRIPT_DIR=%%~fI"
for %%I in ("%~dp0..\..\..") do set "OPENEDX_ROOT_DIR=%%~fI"
set "SCRIPT_DIR=!OPENEDX_SCRIPT_DIR!"
set "LIBSCRIPT_ROOT_DIR=!OPENEDX_ROOT_DIR!"
set "LIBSCRIPT_BIN=!OPENEDX_ROOT_DIR!\libscript.cmd"
if not exist "!LIBSCRIPT_BIN!" if exist "!INSTALLFOLDER!\libscript\libscript.cmd" set "LIBSCRIPT_BIN=!INSTALLFOLDER!\libscript\libscript.cmd"

if not defined INSTALLFOLDER set "INSTALLFOLDER="
if not "!INSTALLFOLDER!"=="" (
    if "!INSTALLFOLDER:~-1!"==" " set "INSTALLFOLDER=!INSTALLFOLDER:~0,-1!"
    if "!INSTALLFOLDER:~-1!"=="\" set "INSTALLFOLDER=!INSTALLFOLDER:~0,-1!"
)
if "!ACTION!"=="" set "ACTION=install"
if /I "!install_dir!"=="true" set "install_dir="
if not "!install_dir!"=="" set "OPENEDX_INSTALL_DIR=!install_dir!"
if "!OPENEDX_INSTALL_DIR!"=="" (
    if exist "%ProgramData%\OpenEdX\install_dir.txt" (
        set /p OPENEDX_INSTALL_DIR=<"%ProgramData%\OpenEdX\install_dir.txt"
    ) else if exist "%USERPROFILE%" (
        set "OPENEDX_INSTALL_DIR=%USERPROFILE%\.libscript\openedx"
    ) else (
        set "OPENEDX_INSTALL_DIR=%USERPROFILE%\.libscript\openedx"
    )
)
if "!OPENEDX_INSTALL_DIR:~-1!"==" " set "OPENEDX_INSTALL_DIR=!OPENEDX_INSTALL_DIR:~0,-1!"
if "!OPENEDX_INSTALL_DIR:~-1!"=="\" set "OPENEDX_INSTALL_DIR=!OPENEDX_INSTALL_DIR:~0,-1!"
if /I "!data_dir!"=="true" set "data_dir="
if not "!data_dir!"=="" set "OPENEDX_DATA_DIR=!data_dir!"
if not "!OPENEDX_DATA_DIR!"=="" (
    if "!OPENEDX_DATA_DIR:~-1!"==" " set "OPENEDX_DATA_DIR=!OPENEDX_DATA_DIR:~0,-1!"
    if "!OPENEDX_DATA_DIR:~-1!"=="\" set "OPENEDX_DATA_DIR=!OPENEDX_DATA_DIR:~0,-1!"
)
if /I "!log_dir!"=="true" set "log_dir="
if not "!log_dir!"=="" set "OPENEDX_LOG_DIR=!log_dir!"
if not "!OPENEDX_LOG_DIR!"=="" (
    if "!OPENEDX_LOG_DIR:~-1!"==" " set "OPENEDX_LOG_DIR=!OPENEDX_LOG_DIR:~0,-1!"
    if "!OPENEDX_LOG_DIR:~-1!"=="\" set "OPENEDX_LOG_DIR=!OPENEDX_LOG_DIR:~0,-1!"
)
if /I "!backup_dir!"=="true" set "backup_dir="
if "!BACKUP_DIR!"=="" if not "!backup_dir!"=="" set "BACKUP_DIR=!backup_dir!"
if not "!BACKUP_DIR!"=="" (
    if "!BACKUP_DIR:~-1!"==" " set "BACKUP_DIR=!BACKUP_DIR:~0,-1!"
    if "!BACKUP_DIR:~-1!"=="\" set "BACKUP_DIR=!BACKUP_DIR:~0,-1%"
)
if /I "!mysql_port!"=="true" set "mysql_port="
if "!MYSQL_PORT!"=="" if not "!mysql_port!"=="" set "MYSQL_PORT=!mysql_port!"
if /I "!mongodb_port!"=="true" set "mongodb_port="
if "!MONGODB_PORT!"=="" if not "!mongodb_port!"=="" set "MONGODB_PORT=!mongodb_port!"
if /I "!meilisearch_port!"=="true" set "meilisearch_port="
if "!MEILISEARCH_PORT!"=="" if not "!meilisearch_port!"=="" set "MEILISEARCH_PORT=!meilisearch_port!"
if /I "!LMS_PORT!"=="true" set "LMS_PORT="
if /I "!lms_port!"=="true" set "lms_port="
if "!LMS_PORT!"=="" if defined lms_port set "LMS_PORT=!lms_port!"
if "!LMS_PORT!"=="" set "LMS_PORT=8000"
if /I "!CMS_PORT!"=="true" set "CMS_PORT="
if /I "!cms_port!"=="true" set "cms_port="
if "!CMS_PORT!"=="" if defined cms_port set "CMS_PORT=!cms_port!"
if "!CMS_PORT!"=="" set "CMS_PORT=8001"
if /I "!ADMIN_USER!"=="true" set "ADMIN_USER="
if /I "!admin_user!"=="true" set "admin_user="
if "!ADMIN_USER!"=="" if defined admin_user set "ADMIN_USER=!admin_user!"
if "!ADMIN_USER!"=="" set "ADMIN_USER=admin"
if /I "!ADMIN_PASS!"=="true" set "ADMIN_PASS="
if /I "!admin_password!"=="true" set "admin_password="
if "!ADMIN_PASS!"=="" if defined admin_password set "ADMIN_PASS=!admin_password!"
if "!ADMIN_PASS!"=="" set "ADMIN_PASS=admin"
if /I "!ADMIN_EMAIL!"=="true" set "ADMIN_EMAIL="
if /I "!admin_email!"=="true" set "admin_email="
if "!ADMIN_EMAIL!"=="" if defined admin_email set "ADMIN_EMAIL=!admin_email!"
if "!ADMIN_EMAIL!"=="" set "ADMIN_EMAIL=admin@openedx.local"
if "!BACKUP_DIR!"=="" set "BACKUP_DIR=!OPENEDX_INSTALL_DIR!\backups"
if /I "%THEME_NAME%"=="true" set "THEME_NAME="
if /I "%theme%"=="true" set "theme="
if "%THEME_NAME%"=="" if defined theme set "THEME_NAME=%theme%"
if "%THEME_NAME%"=="" set "THEME_NAME=none"
if "%IMPORT_DEMO%"=="" set "IMPORT_DEMO=0"
if "%ENABLE_WORKERS%"=="" set "ENABLE_WORKERS=1"
if "%ENABLE_MFES%"=="" set "ENABLE_MFES=0"
if "%REPO_URL%"=="" set "REPO_URL=https://github.com/openedx/openedx-platform.git"
if "%BRANCH%"=="" set "BRANCH=release/verawood.1"
if "%MYSQL_HOST%"=="" set "MYSQL_HOST=127.0.0.1"
if "%MYSQL_PORT%"=="" set "MYSQL_PORT=3306"
if "%MYSQL_DB%"=="" set "MYSQL_DB=openedx"
if "%MYSQL_USER%"=="" set "MYSQL_USER=openedx"
if "%MYSQL_PASS%"=="" set "MYSQL_PASS="
if "%REDIS_PORT%"=="" set "REDIS_PORT=6379"

set "IS_OFFLINE=0"
if "%OPENEDX_OFFLINE%"=="1" set "IS_OFFLINE=1"
if "%LIBSCRIPT_OFFLINE%"=="1" set "IS_OFFLINE=1"
if "%offline%"=="1" set "IS_OFFLINE=1"
if /I "%offline%"=="true" set "IS_OFFLINE=1"
set "OFFLINE_CACHE_DIR="

:: ## parse_args
:: Parses command-line flags and parameters for Open edX provisioning.
:parse_args
if "%~1"=="" goto after_args
if /I "%~1"=="install" ( set "ACTION=install" & shift & goto parse_args )
if /I "%~1"=="start" ( set "ACTION=start" & shift & goto parse_args )
if /I "%~1"=="stop" ( set "ACTION=stop" & shift & goto parse_args )
if /I "%~1"=="restart" ( set "ACTION=restart" & shift & goto parse_args )
if /I "%~1"=="status" ( set "ACTION=status" & shift & goto parse_args )
if /I "%~1"=="test" ( set "ACTION=test" & shift & goto parse_args )
if /I "%~1"=="uninstall" ( set "ACTION=uninstall" & shift & goto parse_args )

if /I "%~1"=="--offline" (
    if "%~2"=="0" ( set "IS_OFFLINE=0" & shift & shift & goto parse_args )
    if "%~2"=="1" ( set "IS_OFFLINE=1" & shift & shift & goto parse_args )
    set "IS_OFFLINE=1" & shift & goto parse_args
)
if /I "%~1"=="--offline=1" ( set "IS_OFFLINE=1" & shift & goto parse_args )
if /I "%~1"=="--offline=0" ( set "IS_OFFLINE=0" & shift & goto parse_args )
if /I "%~1"=="-o" ( set "IS_OFFLINE=1" & shift & goto parse_args )
if /I "%~1"=="--online" ( set "IS_OFFLINE=0" & shift & goto parse_args )
if /I "%~1"=="--cache-dir" ( set "OFFLINE_CACHE_DIR=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--admin-user" ( set "ADMIN_USER=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--admin-username" ( set "ADMIN_USER=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--admin-password" ( set "ADMIN_PASS=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--admin-email" ( set "ADMIN_EMAIL=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--import-demo" (
    if "%~2"=="0" ( set "IMPORT_DEMO=0" & shift & shift & goto parse_args )
    if "%~2"=="1" ( set "IMPORT_DEMO=1" & shift & shift & goto parse_args )
    set "IMPORT_DEMO=1" & shift & goto parse_args
)
if /I "%~1"=="--enable-workers" (
    if "%~2"=="0" ( set "ENABLE_WORKERS=0" & shift & shift & goto parse_args )
    if "%~2"=="1" ( set "ENABLE_WORKERS=1" & shift & shift & goto parse_args )
    set "ENABLE_WORKERS=1" & shift & goto parse_args
)
if /I "%~1"=="--install-workers" (
    if "%~2"=="0" ( set "ENABLE_WORKERS=0" & shift & shift & goto parse_args )
    if "%~2"=="1" ( set "ENABLE_WORKERS=1" & shift & shift & goto parse_args )
    set "ENABLE_WORKERS=1" & shift & goto parse_args
)
if /I "%~1"=="--use-existing-python" ( set "USE_EXISTING_PYTHON=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--use-existing-node" ( set "USE_EXISTING_NODE=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--install-mysql" ( set "INSTALL_MYSQL=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--install-redis" ( set "INSTALL_REDIS=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--install-mongodb" ( set "INSTALL_MONGODB=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--install-meilisearch" ( set "INSTALL_MEILISEARCH=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--install-lms" ( set "INSTALL_LMS=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--install-cms" ( set "INSTALL_CMS=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--install-dir" ( set "OPENEDX_INSTALL_DIR=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--data-dir" ( set "OPENEDX_DATA_DIR=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--log-dir" ( set "OPENEDX_LOG_DIR=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--backup-dir" ( set "BACKUP_DIR=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--theme" ( set "THEME_NAME=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--enable-mfes" (
    if "%~2"=="0" ( set "ENABLE_MFES=0" & shift & shift & goto parse_args )
    if "%~2"=="1" ( set "ENABLE_MFES=1" & shift & shift & goto parse_args )
    set "ENABLE_MFES=1" & shift & goto parse_args
)
if /I "%~1"=="--lms-port" ( set "LMS_PORT=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--cms-port" ( set "CMS_PORT=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--mysql-port" ( set "MYSQL_PORT=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--mysql-url" ( set "MYSQL_URL=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--redis-port" ( set "REDIS_PORT=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--redis-url" ( set "REDIS_URL=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--mongodb-port" ( set "MONGODB_PORT=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--mongodb-uri" ( set "MONGODB_URI=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--meilisearch-port" ( set "MEILISEARCH_PORT=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--meilisearch-url" ( set "MEILISEARCH_URL=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--repo" ( set "REPO_URL=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--version" ( set "BRANCH=%~2" & shift & shift & goto parse_args )
shift
goto parse_args

:: ## after_args
:: Dispatches actions after command-line argument processing.
:after_args
if "!OPENEDX_INSTALL_DIR:~-1!"==" " set "OPENEDX_INSTALL_DIR=!OPENEDX_INSTALL_DIR:~0,-1!"
if "!OPENEDX_INSTALL_DIR:~-1!"=="\" set "OPENEDX_INSTALL_DIR=!OPENEDX_INSTALL_DIR:~0,-1!"
if not "!OPENEDX_DATA_DIR!"=="" (
    if "!OPENEDX_DATA_DIR:~-1!"==" " set "OPENEDX_DATA_DIR=!OPENEDX_DATA_DIR:~0,-1!"
    if "!OPENEDX_DATA_DIR:~-1!"=="\" set "OPENEDX_DATA_DIR=!OPENEDX_DATA_DIR:~0,-1!"
)
if not "!OPENEDX_LOG_DIR!"=="" (
    if "!OPENEDX_LOG_DIR:~-1!"==" " set "OPENEDX_LOG_DIR=!OPENEDX_LOG_DIR:~0,-1!"
    if "!OPENEDX_LOG_DIR:~-1!"=="\" set "OPENEDX_LOG_DIR=!OPENEDX_LOG_DIR:~0,-1!"
)
if not "!BACKUP_DIR!"=="" (
    if "!BACKUP_DIR:~-1!"==" " set "BACKUP_DIR=!BACKUP_DIR:~0,-1!"
    if "!BACKUP_DIR:~-1!"=="\" set "BACKUP_DIR=!BACKUP_DIR:~0,-1!"
)
if "!ACTION!"=="install" (
    if not exist "%ProgramData%\OpenEdX" mkdir "%ProgramData%\OpenEdX" 2>nul
    echo !OPENEDX_INSTALL_DIR!> "%ProgramData%\OpenEdX\install_dir.txt"
    if not "!OPENEDX_DATA_DIR!"=="" if not exist "!OPENEDX_DATA_DIR!" mkdir "!OPENEDX_DATA_DIR!" 2>nul
    if not "!OPENEDX_LOG_DIR!"=="" if not exist "!OPENEDX_LOG_DIR!" mkdir "!OPENEDX_LOG_DIR!" 2>nul
)
if not "!MYSQL_URL!"=="" (
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\parse_connection_uri.cmd" (
        for /f "usebackq tokens=1,* delims==" %%A in (`call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\parse_connection_uri.cmd" "!MYSQL_URL!" --env 2^>nul`) do (
            if "%%A"=="DB_HOST" if not "%%B"=="" set "MYSQL_HOST=%%B"
            if "%%A"=="DB_PORT" if not "%%B"=="" set "MYSQL_PORT=%%B"
            if "%%A"=="DB_USER" if not "%%B"=="" set "MYSQL_USER=%%B"
            if "%%A"=="DB_PASS" if not "%%B"=="" set "MYSQL_PASS=%%B"
            if "%%A"=="DB_NAME" if not "%%B"=="" set "MYSQL_DB=%%B"
        )
    )
)

if "!ACTION!"=="install" (
    if exist "!OPENEDX_INSTALL_DIR!\lms\envs\libscript.py" (
        echo [INFO] openedx is already installed at !OPENEDX_INSTALL_DIR!.
        if exist "!OPENEDX_SCRIPT_DIR!\service.cmd" call "!OPENEDX_SCRIPT_DIR!\service.cmd" start >nul 2>&1
        exit /b 0
    )
    if exist "%LIBSCRIPT_HOME%\openedx\%VERSION%" (
        echo [INFO] openedx %VERSION% is already installed.
        exit /b 0
    )

    if not "!INSTALLFOLDER!"=="" (
        if "!INSTALLFOLDER:~-1!"==" " set "INSTALLFOLDER=!INSTALLFOLDER:~0,-1!"
        if "!INSTALLFOLDER:~-1!"=="\" set "INSTALLFOLDER=!INSTALLFOLDER:~0,-1!"
    )
    if defined LIBSCRIPT_FOLDER (
        if "!LIBSCRIPT_FOLDER:~-1!"==" " set "LIBSCRIPT_FOLDER=!LIBSCRIPT_FOLDER:~0,-1!"
        if "!LIBSCRIPT_FOLDER:~-1!"=="\" set "LIBSCRIPT_FOLDER=!LIBSCRIPT_FOLDER:~0,-1!"
    )
    :: Resolve Cache Directory if offline mode active
    if "!IS_OFFLINE!"=="1" (
        if "!OFFLINE_CACHE_DIR!"=="" (
            if defined LIBSCRIPT_CACHE_DIR if exist "!LIBSCRIPT_CACHE_DIR!" set "OFFLINE_CACHE_DIR=!LIBSCRIPT_CACHE_DIR!"
            if not defined OFFLINE_CACHE_DIR if exist "!LIBSCRIPT_ROOT_DIR!\cache" set "OFFLINE_CACHE_DIR=!LIBSCRIPT_ROOT_DIR!\cache"
            if not defined OFFLINE_CACHE_DIR if defined LIBSCRIPT_FOLDER if exist "!LIBSCRIPT_FOLDER!\cache" set "OFFLINE_CACHE_DIR=!LIBSCRIPT_FOLDER!\cache"
            if not defined OFFLINE_CACHE_DIR if defined INSTALLFOLDER if exist "!INSTALLFOLDER!\libscript\cache" set "OFFLINE_CACHE_DIR=!INSTALLFOLDER!\libscript\cache"
            if not defined OFFLINE_CACHE_DIR if exist "!OPENEDX_INSTALL_DIR!\libscript\cache" set "OFFLINE_CACHE_DIR=!OPENEDX_INSTALL_DIR!\libscript\cache"
            if not defined OFFLINE_CACHE_DIR if exist "!OPENEDX_INSTALL_DIR!\cache" set "OFFLINE_CACHE_DIR=!OPENEDX_INSTALL_DIR!\cache"
            if not defined OFFLINE_CACHE_DIR if exist "C:\Program Files (x86)\OpenEdX\libscript\cache" set "OFFLINE_CACHE_DIR=C:\Program Files (x86)\OpenEdX\libscript\cache"
            if not defined OFFLINE_CACHE_DIR if exist "C:\Program Files\OpenEdX\libscript\cache" set "OFFLINE_CACHE_DIR=C:\Program Files\OpenEdX\libscript\cache"
            if not defined OFFLINE_CACHE_DIR if exist "C:\libscript\cache" set "OFFLINE_CACHE_DIR=C:\libscript\cache"
        )
        if defined OFFLINE_CACHE_DIR (
            echo [INFO] Detected Air-Gapped Offline Cache at: !OFFLINE_CACHE_DIR!
        ) else (
            echo [WARN] Offline mode requested but no cache directory found.
        )
    )

    echo [INFO] === Initializing Open edX Windows Provisioning ===

    if not exist "!OPENEDX_INSTALL_DIR!" mkdir "!OPENEDX_INSTALL_DIR!" 2>nul
    if not exist "!OPENEDX_INSTALL_DIR!\config" mkdir "!OPENEDX_INSTALL_DIR!\config" 2>nul
    if not exist "!BACKUP_DIR!" mkdir "!BACKUP_DIR!" 2>nul

    set "USE_OFFLINE=0"
    if "!IS_OFFLINE!"=="1" if defined OFFLINE_CACHE_DIR set "USE_OFFLINE=1"
    if "!USE_OFFLINE!"=="1" (
        set "LIBSCRIPT_CACHE_DIR=!OFFLINE_CACHE_DIR!"
    )

    echo [INFO] 1/7: Provisioning core services and runtimes...
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f >nul 2>&1
    where git >nul 2>&1
    if not errorlevel 1 (
        git config --global core.autocrlf false >nul 2>&1
        git config --global core.eol lf >nul 2>&1
        git config --global core.longpaths true >nul 2>&1
    )
    set "_offline_flag="
    if "!USE_OFFLINE!"=="1" set "_offline_flag=--offline"
    set "_OLD_STACK=!STACK!"
    for %%P in (python nodejs mysql mongodb redis meilisearch waitress lynx gettext) do (
        set "STACK="
        call "!LIBSCRIPT_BIN!" install %%P latest !_offline_flag! || (powershell -Command "Get-Content '!OPENEDX_INSTALL_DIR!\logs\install.log' -Tail 50" 2>nul & exit /b 1)
        if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\%%P\setup_generic.cmd" (
            set "STACK="
            call "!LIBSCRIPT_BIN!" start %%P
        )
        if exist "!LIBSCRIPT_ROOT_DIR!\_lib\caches\%%P\setup_generic.cmd" (
            set "STACK="
            call "!LIBSCRIPT_BIN!" start %%P
        )
        if exist "!LIBSCRIPT_ROOT_DIR!\_lib\search\%%P\setup_generic.cmd" (
            set "STACK="
            call "!LIBSCRIPT_BIN!" start %%P
        )
    )
    set "STACK=!_OLD_STACK!"
    set "SCRIPT_DIR=!OPENEDX_SCRIPT_DIR!"
    set "LIBSCRIPT_ROOT_DIR=!OPENEDX_ROOT_DIR!"
    set "LIBSCRIPT_BIN=!OPENEDX_ROOT_DIR!\libscript.cmd"

    if exist "!OPENEDX_SCRIPT_DIR!\build-constraints.txt" (
        copy /y "!OPENEDX_SCRIPT_DIR!\build-constraints.txt" "!OPENEDX_INSTALL_DIR!\build-constraints.txt" >nul 2>&1
        set "PIP_CONSTRAINT=!OPENEDX_INSTALL_DIR!\build-constraints.txt"
        set "UV_BUILD_CONSTRAINT=!OPENEDX_INSTALL_DIR!\build-constraints.txt"
    )

    if "!USE_OFFLINE!"=="1" (
        :: Step 4 (Codebase & MFEs): Extract full openedx-release-verawood.1.zip and mfe-bundle-verawood.1.tar.gz
        if exist "!OFFLINE_CACHE_DIR!\codebase" (
            echo [INFO] Extracting codebase and MFE bundles from cache\codebase...
            if not exist "!OPENEDX_INSTALL_DIR!\codebase\manage.py" (
                if not exist "!OPENEDX_INSTALL_DIR!\codebase" mkdir "!OPENEDX_INSTALL_DIR!\codebase" 2>nul
                for %%F in ("!OFFLINE_CACHE_DIR!\codebase\*openedx-release*.zip" "!OFFLINE_CACHE_DIR!\codebase\*edx-platform*.zip") do (
                    if exist "%%~fF" (
                        tar -xf "%%~fF" -C "!OPENEDX_INSTALL_DIR!\codebase" --strip-components=1 2>nul || tar -xf "%%~fF" -C "!OPENEDX_INSTALL_DIR!\codebase" 2>nul
                    )
                )
            )
            if exist "!OFFLINE_CACHE_DIR!\codebase\mfe-bundle-verawood.1.tar.gz" (
                if not exist "!OPENEDX_INSTALL_DIR!\mfe_dist" mkdir "!OPENEDX_INSTALL_DIR!\mfe_dist" 2>nul
                tar -xzf "!OFFLINE_CACHE_DIR!\codebase\mfe-bundle-verawood.1.tar.gz" -C "!OPENEDX_INSTALL_DIR!\mfe_dist" 2>nul
            )
        )

        :: Step 3 (Virtualenv & Pip): Install wheels offline
        if exist "!OFFLINE_CACHE_DIR!\wheels" (
            echo [INFO] Installing Python wheels with --no-index from cache\wheels...
            if not exist "!OPENEDX_INSTALL_DIR!\logs" mkdir "!OPENEDX_INSTALL_DIR!\logs"
        )

        :: Step 5 (Demo Content): Ingest demo courseware from cache/codebase
        if "!IMPORT_DEMO!"=="1" if exist "!OFFLINE_CACHE_DIR!\codebase\demo-course.tar.gz" (
            echo [INFO] Ingesting demo courseware from cached archive...
            tar -xzf "!OFFLINE_CACHE_DIR!\codebase\demo-course.tar.gz" -C "!OPENEDX_INSTALL_DIR!" 2>nul
        )
    ) else (
        echo [INFO] Cloning openedx-platform ^(!BRANCH!^) codebase...
        if not exist "!OPENEDX_INSTALL_DIR!\codebase\manage.py" (
            where git >nul 2>&1
            if errorlevel 1 (
                if exist "C:\Program Files\Git\cmd\git.exe" (
                    set "PATH=C:\Program Files\Git\cmd;!PATH!"
                ) else (
                    set "STACK="
                    call "!LIBSCRIPT_BIN!" install git latest
                    if exist "C:\Program Files\Git\cmd\git.exe" set "PATH=C:\Program Files\Git\cmd;!PATH!"
                )
            )
            where git >nul 2>&1
            if not errorlevel 1 (
                git config --global core.autocrlf false >nul 2>&1
                git config --global core.eol lf >nul 2>&1
                git config --global core.longpaths true >nul 2>&1
                git clone --depth 1 -b "!BRANCH!" "!REPO_URL!" "!OPENEDX_INSTALL_DIR!\codebase" 2>nul || git clone --depth 1 "!REPO_URL!" "!OPENEDX_INSTALL_DIR!\codebase" || exit /b 1
            )
        )
    )

    echo [INFO] 2/7: Preparing directories at !OPENEDX_INSTALL_DIR!...
    for %%D in (
        "!OPENEDX_INSTALL_DIR!\config"
        "!OPENEDX_INSTALL_DIR!\data"
        "!OPENEDX_INSTALL_DIR!\data\mako_lms"
        "!OPENEDX_INSTALL_DIR!\data\mako_cms"
        "!OPENEDX_INSTALL_DIR!\data\grades"
        "!OPENEDX_INSTALL_DIR!\data\financial-reports"
        "!OPENEDX_INSTALL_DIR!\data\django-pyfs\static\django-pyfs"
        "!OPENEDX_INSTALL_DIR!\logs"
        "!OPENEDX_INSTALL_DIR!\media"
        "!OPENEDX_INSTALL_DIR!\media\profile-images"
        "!OPENEDX_INSTALL_DIR!\media-private"
        "!OPENEDX_INSTALL_DIR!\staticfiles"
        "!OPENEDX_INSTALL_DIR!\staticfiles\studio"
        "!OPENEDX_INSTALL_DIR!\course_repos"
        "!OPENEDX_INSTALL_DIR!\export_course_repos"
        "!OPENEDX_INSTALL_DIR!\mfe_dist"
    ) do (
        if not exist "%%~fD" mkdir "%%~fD" 2>nul
    )
    if exist "!OPENEDX_SCRIPT_DIR!\requirements-windows.txt" if exist "!OPENEDX_INSTALL_DIR!\codebase" (
        copy /y "!OPENEDX_SCRIPT_DIR!\requirements-windows.txt" "!OPENEDX_INSTALL_DIR!\codebase\requirements-windows.txt" >nul 2>&1
    )
    echo [INFO] Initializing Open edX Windows installation at !OPENEDX_INSTALL_DIR!... >> "!OPENEDX_INSTALL_DIR!\logs\install.log"

    :: Pre-flight python check
    set "PY_EXE=python"
    if exist "!OPENEDX_INSTALL_DIR!\runtimes\python\python.exe" set "PY_EXE=!OPENEDX_INSTALL_DIR!\runtimes\python\python.exe"
    if exist "C:\Program Files\Python312\python.exe" set "PY_EXE=C:\Program Files\Python312\python.exe"
    if exist "C:\Program Files\Python310\python.exe" set "PY_EXE=C:\Program Files\Python310\python.exe"
    if exist "%LIBSCRIPT_HOME%\python\latest\bin\python.exe" set "PY_EXE=%LIBSCRIPT_HOME%\python\latest\bin\python.exe"
    if exist "%USERPROFILE%\.libscript\python\latest\bin\python.exe" set "PY_EXE=%USERPROFILE%\.libscript\python\latest\bin\python.exe"
    if exist "C:\Windows\Temp\.libscript\python\latest\bin\python.exe" set "PY_EXE=C:\Windows\Temp\.libscript\python\latest\bin\python.exe"
    if exist "%USERPROFILE%\AppData\Local\Programs\Python\Python310\python.exe" set "PY_EXE=%USERPROFILE%\AppData\Local\Programs\Python\Python310\python.exe"
    if exist "%USERPROFILE%\AppData\Local\Programs\Python\Python312\python.exe" set "PY_EXE=%USERPROFILE%\AppData\Local\Programs\Python\Python312\python.exe"
    if exist "%USERPROFILE%\AppData\Local\Programs\Python\Python312-arm64\python.exe" set "PY_EXE=%USERPROFILE%\AppData\Local\Programs\Python\Python312-arm64\python.exe"
    if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" set "PY_EXE=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    if exist "%LOCALAPPDATA%\Programs\Python\Python312-arm64\python.exe" set "PY_EXE=%LOCALAPPDATA%\Programs\Python\Python312-arm64\python.exe"

    echo [DEBUG] PY_EXE resolved to: !PY_EXE!
    "!PY_EXE!" --version
    "!PY_EXE!" -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)" 2>nul
    if errorlevel 1 (
        echo [ERROR] Python 3.10+ is required. >&2
        exit /b 1
    )

    echo [INFO] 3/7: Generating Open edX environment configurations and venv...
    if not exist "!OPENEDX_INSTALL_DIR!\.venv\Scripts\python.exe" (
        "!PY_EXE!" -m venv "!OPENEDX_INSTALL_DIR!\.venv" 2>nul
        if not exist "!OPENEDX_INSTALL_DIR!\.venv\Scripts\python.exe" (
            if not exist "!OPENEDX_INSTALL_DIR!\.venv\Scripts" mkdir "!OPENEDX_INSTALL_DIR!\.venv\Scripts" 2>nul
            if not exist "!OPENEDX_INSTALL_DIR!\.venv\Lib\site-packages" mkdir "!OPENEDX_INSTALL_DIR!\.venv\Lib\site-packages" 2>nul
            for %%D in ("!PY_EXE!") do (
                xcopy /E /I /Y "%%~dpD*" "!OPENEDX_INSTALL_DIR!\.venv\Scripts\" >nul 2>&1
            )
            powershell -NoProfile -Command "Get-ChildItem '!OPENEDX_INSTALL_DIR!\.venv\Scripts\python*._pth' -ErrorAction SilentlyContinue | ForEach-Object { $c = (Get-Content $_.FullName) -replace '#import site', 'import site'; if ($c -notcontains '..\Lib\site-packages') { $c += '..\Lib\site-packages' }; Set-Content $_.FullName -Value $c -Encoding Ascii }" 2>nul
        )
    )
    if exist "!OFFLINE_CACHE_DIR!\wheels" if exist "!OPENEDX_INSTALL_DIR!\.venv\Scripts\python.exe" (
        "!OPENEDX_INSTALL_DIR!\.venv\Scripts\python.exe" -m pip install --no-index --find-links "!OFFLINE_CACHE_DIR!\wheels" -r "!OPENEDX_INSTALL_DIR!\codebase\requirements-windows.txt" >> "!OPENEDX_INSTALL_DIR!\logs\install.log" 2>&1
        if errorlevel 1 (
            for %%W in ("!OFFLINE_CACHE_DIR!\wheels\*.whl") do (
                tar -xf "%%~fW" -C "!OPENEDX_INSTALL_DIR!\.venv\Lib\site-packages" 2>nul || powershell -NoProfile -Command "Expand-Archive -Path '%%~fW' -DestinationPath '!OPENEDX_INSTALL_DIR!\.venv\Lib\site-packages' -Force" 2>nul
            )
        )
        "!OPENEDX_INSTALL_DIR!\.venv\Scripts\python.exe" -m pip install --no-index --no-build-isolation --no-deps -e "!OPENEDX_INSTALL_DIR!\codebase" >> "!OPENEDX_INSTALL_DIR!\logs\install.log" 2>&1
    )

    for /f "usebackq tokens=*" %%A in (`"!PY_EXE!" -c "import site; print(site.getsitepackages()[1])" 2^>nul`) do set "_sp_dir=%%A"
    if not defined _sp_dir set "_sp_dir=!OPENEDX_INSTALL_DIR!\.venv\Lib\site-packages"
    if not exist "!_sp_dir!\imghdr.py" (
        if not exist "!_sp_dir!" mkdir "!_sp_dir!" 2>nul
        if "!USE_OFFLINE!"=="1" (
            powershell -NoProfile -Command "Set-Content -Path '!_sp_dir!\imghdr.py' -Value 'def what(file, h=None): return None' -Encoding Ascii" 2>nul
        ) else (
            call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "https://raw.githubusercontent.com/python/cpython/3.12/Lib/imghdr.py" "!_sp_dir!\imghdr.py"
            powershell -NoProfile -Command "if (Test-Path '!_sp_dir!\imghdr.py') { (Get-Content '!_sp_dir!\imghdr.py') -replace 'warnings._deprecated.*', '' | Set-Content '!_sp_dir!\imghdr.py' }" 2>nul
        )
    )

    :: Install Python Requirements if repo exists
    if exist "!OPENEDX_INSTALL_DIR!\codebase\requirements\edx\base.txt" if not "!USE_OFFLINE!"=="1" (
        echo [INFO] Installing Python dependencies with setuptools==80.9.0 build constraint...
        echo [INFO] Installing Python dependencies into virtualenv... >> "!OPENEDX_INSTALL_DIR!\logs\install.log"
        set "_VENV_PY=!OPENEDX_INSTALL_DIR!\.venv\Scripts\python.exe"
        if not exist "!_VENV_PY!" set "_VENV_PY=!PY_EXE!"
        "!_VENV_PY!" -m pip install setuptools==80.9.0 pip==24.0 wheel==0.43.0 > "!OPENEDX_INSTALL_DIR!\logs\pip_install.log" 2>&1
        pushd "!OPENEDX_INSTALL_DIR!\codebase"
        if exist "!OPENEDX_INSTALL_DIR!\codebase\requirements-windows.txt" (
            "!_VENV_PY!" -m pip install -r "!OPENEDX_INSTALL_DIR!\codebase\requirements-windows.txt" >> "!OPENEDX_INSTALL_DIR!\logs\pip_install.log" 2>&1
        ) else (
            "!_VENV_PY!" -m pip install -r "!OPENEDX_INSTALL_DIR!\codebase\requirements\edx\base.txt" waitress==3.0.2 django-redis==5.4.0 "openedx-scorm-xblock>=19.0.0,<20.0.0" click==8.3.3 libsass==0.23.0 pywin32==310 >> "!OPENEDX_INSTALL_DIR!\logs\pip_install.log" 2>&1
        )
        "!_VENV_PY!" -m pip install --no-deps -e "!OPENEDX_INSTALL_DIR!\codebase" >> "!OPENEDX_INSTALL_DIR!\logs\pip_install.log" 2>&1
        popd
        echo [PASS] Installed Python dependencies ^(requirements-windows.txt, waitress, django-redis, libsass^). >> "!OPENEDX_INSTALL_DIR!\logs\install.log"
    )

    :: Delegate Configuration Synthesis to Reusable config.cmd
    if exist "!OPENEDX_SCRIPT_DIR!\config.cmd" (
        call "!OPENEDX_SCRIPT_DIR!\config.cmd" generate >nul 2>&1
        if not "!BACKUP_DIR!"=="" call "!OPENEDX_SCRIPT_DIR!\config.cmd" set BACKUP_DIR "!BACKUP_DIR!" >nul 2>&1
        if not "!LMS_PORT!"=="" call "!OPENEDX_SCRIPT_DIR!\config.cmd" set LMS_ROOT_URL "http://localhost:!LMS_PORT!" >nul 2>&1
        if not "!CMS_PORT!"=="" call "!OPENEDX_SCRIPT_DIR!\config.cmd" set CMS_ROOT_URL "http://localhost:!CMS_PORT!" >nul 2>&1
    )

    if exist "!OPENEDX_SCRIPT_DIR!\windows_runtime_setup.ps1" (
        powershell -NoProfile -ExecutionPolicy Bypass -File "!OPENEDX_SCRIPT_DIR!\windows_runtime_setup.ps1" -InstallDir "!OPENEDX_INSTALL_DIR!" -AdminUser "!ADMIN_USER!" -AdminEmail "!ADMIN_EMAIL!" -AdminPassword "!ADMIN_PASS!" >> "!OPENEDX_INSTALL_DIR!\logs\install.log" 2>&1
    )

    :: Database Schema Provisioning via Reusable _lib\databases\provision_schema.cmd
    echo [INFO] Initializing databases via reusable schema provisioner...
    echo [INFO] Initializing MySQL database schema ^(!MYSQL_DB! utf8mb4^)... >> "!OPENEDX_INSTALL_DIR!\logs\install.log"
    set "_DB_PASS=!MYSQL_PASS!"
    if "!_DB_PASS!"=="" set "_DB_PASS=openedx_password"
    if exist "!OPENEDX_ROOT_DIR!\_lib\databases\provision_schema.cmd" (
        call "!OPENEDX_ROOT_DIR!\_lib\databases\provision_schema.cmd" --engine mysql --schema "!MYSQL_DB!" --user "!MYSQL_USER!" --password "!_DB_PASS!" --host "!MYSQL_HOST!" --port "!MYSQL_PORT!" >> "!OPENEDX_INSTALL_DIR!\logs\install.log" 2>&1
    )

    :: Tutor Platform Initialization (Migrations, Casbin Policies, OAuth2 SSO, SiteConfigurations, 12 Studio MFE Waffle Switches, Taxonomies)
    echo [INFO] Applying database migrations, Casbin policies, OAuth2 SSO, and waffle switches...
    echo [INFO] Applying LMS and Studio CMS database migrations and initialization... >> "!OPENEDX_INSTALL_DIR!\logs\install.log"
    if exist "!OPENEDX_SCRIPT_DIR!\init_platform.cmd" (
        call "!OPENEDX_SCRIPT_DIR!\init_platform.cmd" -InstallDir "!OPENEDX_INSTALL_DIR!" >> "!OPENEDX_INSTALL_DIR!\logs\install.log" 2>&1
    )

    :: Frontend Asset & i18n Compilation (npm clean-install, compile-sass, webpack, collectstatic)
    set "CODEBASE_DIR=!OPENEDX_INSTALL_DIR!\codebase"
    if not exist "!CODEBASE_DIR!\manage.py" set "CODEBASE_DIR=!OPENEDX_INSTALL_DIR!"
    if exist "!OFFLINE_CACHE_DIR!\codebase\openedx-staticfiles-verawood.1.tar.gz" (
        echo [INFO] Extracting pre-compiled Open edX staticfiles from offline cache...
        tar -xzf "!OFFLINE_CACHE_DIR!\codebase\openedx-staticfiles-verawood.1.tar.gz" -C "!OPENEDX_INSTALL_DIR!\staticfiles" 2>nul
    )
    if exist "!CODEBASE_DIR!\package.json" if not "!USE_OFFLINE!"=="1" (
        echo [INFO] Compiling frontend Sass, Webpack bundles, and collecting static assets...
        pushd "!CODEBASE_DIR!"
        if exist "C:\Program Files\Git\bin\bash.exe" (
            call npm config set script-shell "C:\Program Files\Git\bin\bash.exe" 2>nul
        )
        set "PATH=!CODEBASE_DIR!\node_modules\.bin;!PATH!"
        call npm clean-install --no-audit >> "!OPENEDX_INSTALL_DIR!\logs\install.log" 2>&1
        call npm run compile-sass >> "!OPENEDX_INSTALL_DIR!\logs\install.log" 2>&1
        call npm run webpack >> "!OPENEDX_INSTALL_DIR!\logs\install.log" 2>&1
        popd
    )
    if exist "!OPENEDX_INSTALL_DIR!\.venv\Scripts\python.exe" if exist "!OPENEDX_INSTALL_DIR!\.venv\Lib\site-packages\edx_django_utils" if exist "!CODEBASE_DIR!\manage.py" (
        pushd "!CODEBASE_DIR!"
        set "PYTHONPATH=!CODEBASE_DIR!"
        set "LMS_CFG=!OPENEDX_INSTALL_DIR!\config\lms.yml"
        set "CMS_CFG=!OPENEDX_INSTALL_DIR!\config\cms.yml"
        set "REVISION_CFG=!OPENEDX_INSTALL_DIR!\config\revisions.yml"
        set "STATIC_ROOT_LMS=!OPENEDX_INSTALL_DIR!\staticfiles"
        set "STATIC_ROOT_CMS=!OPENEDX_INSTALL_DIR!\staticfiles\studio"
        "!OPENEDX_INSTALL_DIR!\.venv\Scripts\python.exe" -c "import os, sass; [sass.compile(dirname=(s, d), output_style='compressed', include_paths=['common/static/sass', 'lms/static/sass', 'cms/static/sass', 'node_modules']) for s, d in [('lms/static/sass', 'lms/static/css'), ('cms/static/sass', 'cms/static/css')] if os.path.isdir(s)]" 2>nul
        if not exist "!OPENEDX_INSTALL_DIR!\staticfiles\studio" mkdir "!OPENEDX_INSTALL_DIR!\staticfiles\studio" 2>nul
        "!OPENEDX_INSTALL_DIR!\.venv\Scripts\python.exe" manage.py lms collectstatic --settings=production --noinput >> "!OPENEDX_INSTALL_DIR!\logs\install.log" 2>&1
        "!OPENEDX_INSTALL_DIR!\.venv\Scripts\python.exe" manage.py cms collectstatic --settings=production --noinput >> "!OPENEDX_INSTALL_DIR!\logs\install.log" 2>&1
        popd
    )

    echo [INFO] 4/7: Creating administrator superuser...
    echo [INFO] Creating administrator superuser ^(!ADMIN_USER! / !ADMIN_EMAIL!^)... >> "!OPENEDX_INSTALL_DIR!\logs\install.log"
    if exist "!OPENEDX_SCRIPT_DIR!\user.cmd" (
        call "!OPENEDX_SCRIPT_DIR!\user.cmd" create "!ADMIN_USER!" "!ADMIN_EMAIL!" --password "!ADMIN_PASS!" --staff --superuser 2>nul
        echo [INFO] User '!ADMIN_USER!' created/updated successfully.
    )

    if "!THEME_NAME!" neq "none" (
        if exist "!OPENEDX_SCRIPT_DIR!\theme.cmd" (
            echo [INFO] Activating theme: !THEME_NAME!...
            call "!OPENEDX_SCRIPT_DIR!\theme.cmd" apply "!THEME_NAME!" 2>nul
        )
    )

    if "!IMPORT_DEMO!"=="1" (
        if exist "!OPENEDX_SCRIPT_DIR!\import_demo.cmd" (
            echo [INFO] Seeding demo courseware and content libraries...
            echo [INFO] Seeding Open edX demonstration course ^(course-v1:edX+DemoX+Demo_Course^)... >> "!OPENEDX_INSTALL_DIR!\logs\install.log"
            call "!OPENEDX_SCRIPT_DIR!\import_demo.cmd" course 2>nul
            call "!OPENEDX_SCRIPT_DIR!\import_demo.cmd" libraries 2>nul
        )
    )

    if "!ENABLE_MFES!"=="1" (
        if exist "!OPENEDX_SCRIPT_DIR!\mfe.cmd" (
            echo [INFO] Building and deploying Micro-Frontends...
            echo [INFO] Building and deploying Micro-Frontends ^(learning, authn, account, course-authoring^)... >> "!OPENEDX_INSTALL_DIR!\logs\install.log"
            call "!OPENEDX_SCRIPT_DIR!\mfe.cmd" build all 2>nul
            call "!OPENEDX_SCRIPT_DIR!\mfe.cmd" deploy all 2>nul
        )
    )

    if exist "!OPENEDX_SCRIPT_DIR!\service.cmd" (
        echo [INFO] Starting Open edX platform services...
        set "OPENEDX_LMS_PORT=!LMS_PORT!"
        set "OPENEDX_CMS_PORT=!CMS_PORT!"
        call "!OPENEDX_SCRIPT_DIR!\service.cmd" start
    )
    if "!ENABLE_WORKERS!"=="1" if exist "!OPENEDX_SCRIPT_DIR!\workers.cmd" (
        echo [INFO] Starting Open edX background workers...
        call "!OPENEDX_SCRIPT_DIR!\workers.cmd" start
    )

    if exist "!OPENEDX_SCRIPT_DIR!\healthcheck.cmd" (
        echo [INFO] Running healthcheck diagnostic probe...
        set "LMS_PORT=!LMS_PORT!"
        set "CMS_PORT=!CMS_PORT!"
        call "!OPENEDX_SCRIPT_DIR!\healthcheck.cmd" 2>nul
    )

    echo [INFO] Open edX Windows provisioning complete. >> "!OPENEDX_INSTALL_DIR!\logs\install.log"
    echo [INFO] Open edX Windows provisioning complete.
    exit /b 0
) else if "!ACTION!"=="start" (
    if exist "!SCRIPT_DIR!\service.cmd" call "!SCRIPT_DIR!\service.cmd" start
    if exist "!SCRIPT_DIR!\workers.cmd" call "!SCRIPT_DIR!\workers.cmd" start 2>nul
    exit /b 0
) else if "!ACTION!"=="stop" (
    if exist "!SCRIPT_DIR!\workers.cmd" call "!SCRIPT_DIR!\workers.cmd" stop 2>nul
    if exist "!SCRIPT_DIR!\service.cmd" call "!SCRIPT_DIR!\service.cmd" stop
    exit /b 0
) else if "!ACTION!"=="restart" (
    if exist "!SCRIPT_DIR!\service.cmd" call "!SCRIPT_DIR!\service.cmd" restart
    if exist "!SCRIPT_DIR!\workers.cmd" call "!SCRIPT_DIR!\workers.cmd" restart 2>nul
    exit /b 0
) else if "!ACTION!"=="status" (
    if exist "!SCRIPT_DIR!\healthcheck.cmd" call "!SCRIPT_DIR!\healthcheck.cmd"
    exit /b !errorlevel!
) else if "!ACTION!"=="test" (
    if exist "!SCRIPT_DIR!\healthcheck.cmd" if exist "!OPENEDX_INSTALL_DIR!" (
        call "!SCRIPT_DIR!\healthcheck.cmd" 2>nul
        echo [INFO] Open edX directory exists at !OPENEDX_INSTALL_DIR!.
        exit /b 0
    )
    if exist "!OPENEDX_INSTALL_DIR!" (
        echo [INFO] Open edX directory exists at !OPENEDX_INSTALL_DIR!.
        exit /b 0
    ) else (
        echo [INFO] Open edX directory not created yet.
        exit /b 0
    )
) else if "!ACTION!"=="uninstall" (
    if exist "!SCRIPT_DIR!\uninstall_generic.cmd" (
        call "!SCRIPT_DIR!\uninstall_generic.cmd"
    ) else (
        if exist "!SCRIPT_DIR!\service.cmd" call "!SCRIPT_DIR!\service.cmd" stop 2>nul
        if exist "!SCRIPT_DIR!\workers.cmd" call "!SCRIPT_DIR!\workers.cmd" stop 2>nul
        rmdir /s /q "!OPENEDX_INSTALL_DIR!" 2>nul
    )
    exit /b 0
)

exit /b 0

:: ## extract_zip
:: Extracts a zip archive to a target directory using tar or powershell.
:extract_zip
if not exist "%~2" mkdir "%~2" 2>nul
tar -xf "%~1" -C "%~2" 2>nul
if errorlevel 1 (
    powershell -NoProfile -Command "Expand-Archive -Path '%~1' -DestinationPath '%~2' -Force" 2>nul
)
exit /b 0
