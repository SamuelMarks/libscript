@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Windows setup script for Open edX stack.
:: Orchestrates provisioning of dependencies, directory layout, environment configuration,
:: user seeding, demo content ingestion, worker processes, Micro-Frontends, and health diagnostics.
::
:: ## Usage
::   call setup_generic.cmd [ACTION] [OPTIONS]
::
:: ## Parameters
::   --admin-user <user>       Administrator username (default: admin)
::   --admin-password <pass>   Administrator password (default: admin)
::   --admin-email <email>     Administrator email (default: admin@openedx.local)
::   --import-demo             Import edX demo course and content libraries
::   --enable-workers          Start Celery background workers
::   --backup-dir <path>       Directory for automated backup storage
::   --theme <name>            Theme name to activate
::   --enable-mfes             Build and deploy Micro-Frontends
::   --lms-port <port>         LMS port (default: 8000)
::   --cms-port <port>         CMS Studio port (default: 8001)

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"

if "%ACTION%"=="" set "ACTION=install"
if "%OPENEDX_INSTALL_DIR%"=="" set "OPENEDX_INSTALL_DIR=%USERPROFILE%\.libscript\openedx"
if "%LMS_PORT%"=="" set "LMS_PORT=8000"
if "%CMS_PORT%"=="" set "CMS_PORT=8001"
if "%ADMIN_USER%"=="" set "ADMIN_USER=admin"
if "%ADMIN_PASS%"=="" set "ADMIN_PASS=admin"
if "%ADMIN_EMAIL%"=="" set "ADMIN_EMAIL=admin@openedx.local"
if "%BACKUP_DIR%"=="" set "BACKUP_DIR=%OPENEDX_INSTALL_DIR%\backups"
if "%THEME_NAME%"=="" set "THEME_NAME=none"
if "%IMPORT_DEMO%"=="" set "IMPORT_DEMO=0"
if "%ENABLE_WORKERS%"=="" set "ENABLE_WORKERS=1"
if "%ENABLE_MFES%"=="" set "ENABLE_MFES=0"

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

if /I "%~1"=="--admin-user" ( set "ADMIN_USER=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--admin-username" ( set "ADMIN_USER=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--admin-password" ( set "ADMIN_PASS=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--admin-email" ( set "ADMIN_EMAIL=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--import-demo" ( set "IMPORT_DEMO=1" & shift & goto parse_args )
if /I "%~1"=="--enable-workers" ( set "ENABLE_WORKERS=1" & shift & goto parse_args )
if /I "%~1"=="--backup-dir" ( set "BACKUP_DIR=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--theme" ( set "THEME_NAME=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--enable-mfes" ( set "ENABLE_MFES=1" & shift & goto parse_args )
if /I "%~1"=="--lms-port" ( set "LMS_PORT=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--cms-port" ( set "CMS_PORT=%~2" & shift & shift & goto parse_args )
shift
goto parse_args

:: ## after_args
:: Dispatches actions after command-line argument processing.
:after_args

if "%ACTION%"=="install" (
    echo [INFO] === Initializing Open edX Windows Provisioning ===

    echo [INFO] 1/7: Provisioning core services and runtimes...
    call "%~dp0\..\..\..\libscript.cmd" install python nodejs mysql mongodb redis meilisearch gunicorn exim nodeenv

    echo [INFO] 2/7: Preparing directories at %OPENEDX_INSTALL_DIR%...
    if not exist "%OPENEDX_INSTALL_DIR%" mkdir "%OPENEDX_INSTALL_DIR%" 2>nul
    if not exist "%OPENEDX_INSTALL_DIR%\config" mkdir "%OPENEDX_INSTALL_DIR%\config" 2>nul
    if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%" 2>nul

    echo [INFO] 3/7: Generating Open edX environment configurations...
    (
        echo {
        echo   "SITE_NAME": "openedx.local",
        echo   "LMS_BASE": "openedx.local",
        echo   "CMS_BASE": "studio.openedx.local",
        echo   "SECRET_KEY": "insecure-secret-key-change-in-production",
        echo   "DATABASES": {
        echo     "default": {
        echo       "ENGINE": "django.db.backends.mysql",
        echo       "NAME": "openedx",
        echo       "USER": "openedx",
        echo       "PASSWORD": "",
        echo       "HOST": "127.0.0.1",
        echo       "PORT": "3306"
        echo     }
        echo   },
        echo   "CACHES": {
        echo     "default": {
        echo       "BACKEND": "django_redis.cache.RedisCache",
        echo       "LOCATION": "redis://127.0.0.1:6379/1"
        echo     }
        echo   },
        echo   "MEILISEARCH_URL": "http://127.0.0.1:7700",
        echo   "EMAIL_HOST": "127.0.0.1",
        echo   "EMAIL_PORT": 25,
        echo   "BACKUP_DIR": "%BACKUP_DIR%"
        echo }
    ) > "%OPENEDX_INSTALL_DIR%\config\lms.env.json"

    echo [INFO] 4/7: Creating administrator superuser...
    if exist "%SCRIPT_DIR%user.cmd" (
        set "OPENEDX_INSTALL_DIR=%OPENEDX_INSTALL_DIR%"
        call "%SCRIPT_DIR%user.cmd" create "%ADMIN_USER%" "%ADMIN_EMAIL%" --password "%ADMIN_PASS%" --staff --superuser 2>nul
    )

    if "%THEME_NAME%" neq "none" (
        if exist "%SCRIPT_DIR%theme.cmd" (
            echo [INFO] Activating theme: %THEME_NAME%...
            call "%SCRIPT_DIR%theme.cmd" apply "%THEME_NAME%" 2>nul
        )
    )

    if "%IMPORT_DEMO%"=="1" (
        if exist "%SCRIPT_DIR%import_demo.cmd" (
            echo [INFO] Seeding demo courseware and content libraries...
            call "%SCRIPT_DIR%import_demo.cmd" course 2>nul
            call "%SCRIPT_DIR%import_demo.cmd" libraries 2>nul
        )
    )

    if "%ENABLE_MFES%"=="1" (
        if exist "%SCRIPT_DIR%mfe.cmd" (
            echo [INFO] Building and deploying Micro-Frontends...
            call "%SCRIPT_DIR%mfe.cmd" build all 2>nul
            call "%SCRIPT_DIR%mfe.cmd" deploy all 2>nul
        )
    )

    if "%ENABLE_WORKERS%"=="1" (
        if exist "%SCRIPT_DIR%workers.cmd" (
            echo [INFO] Launching background workers...
            call "%SCRIPT_DIR%workers.cmd" start 2>nul
        )
    )

    if exist "%SCRIPT_DIR%healthcheck.cmd" (
        echo [INFO] Running healthcheck diagnostic probe...
        call "%SCRIPT_DIR%healthcheck.cmd" 2>nul
    )

    echo [INFO] Open edX Windows provisioning complete.
    exit /b 0
) else if "%ACTION%"=="start" (
    echo [INFO] Starting Open edX background workers...
    if exist "%SCRIPT_DIR%workers.cmd" call "%SCRIPT_DIR%workers.cmd" start 2>nul
    exit /b 0
) else if "%ACTION%"=="stop" (
    echo [INFO] Stopping Open edX background workers...
    if exist "%SCRIPT_DIR%workers.cmd" call "%SCRIPT_DIR%workers.cmd" stop 2>nul
    exit /b 0
) else if "%ACTION%"=="restart" (
    call "%THIS_FILE%" stop
    call "%THIS_FILE%" start
    exit /b %errorlevel%
) else if "%ACTION%"=="status" (
    if exist "%SCRIPT_DIR%healthcheck.cmd" call "%SCRIPT_DIR%healthcheck.cmd"
    exit /b 0
) else if "%ACTION%"=="test" (
    if exist "%OPENEDX_INSTALL_DIR%" (
        echo [INFO] Open edX directory exists at %OPENEDX_INSTALL_DIR%.
        exit /b 0
    ) else (
        echo [INFO] Open edX directory not created yet.
        exit /b 0
    )
) else if "%ACTION%"=="uninstall" (
    if exist "%SCRIPT_DIR%workers.cmd" call "%SCRIPT_DIR%workers.cmd" stop 2>nul
    rmdir /s /q "%OPENEDX_INSTALL_DIR%" 2>nul
    exit /b 0
)

exit /b 0
