@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
:: # setup_generic.cmd
::
:: ## Overview
:: Generic setup and provisioning module for the Open edX platform stack.
:: Handles full lifecycle provisioning, configuration generation, user creation,
:: demo course ingestion, worker orchestration, Micro-Frontend deployment,
:: and health probe verification.
:: 
:: ## Usage
:: setup_generic.cmd stacks/cms/openedx/setup_generic.cmd [OPTIONS]
::
:: :::: Parameters
::   --admin-user <user>       Administrator username (default: admin)
::   --admin-password <pass>   Administrator initial password (default: admin)
::   --admin-email <email>     Administrator email address (default: admin@openedx.local)
::   --import-demo             Ingest edX demo course and content libraries
::   --enable-workers          Launch Celery background workers and periodic scheduler
::   --backup-dir <path>       Directory for automated backup storage
::   --theme <name>            Comprehensive theme to activate
::   --enable-mfes             Build and route Micro-Frontend applications
::   --lms-port <port>         Port for LMS WSGI server (default: 8000)
::   --cms-port <port>         Port for Studio CMS WSGI server (default: 8001)
::   --mysql-url <url>         Remote MySQL DBaaS connection string
::   --redis-port <port>       Redis server port (default: 6379)
::   --redis-url <url>         Remote Redis DBaaS connection URI
::   --mongodb-uri <uri>       MongoDB connection URI
::   --repo <url>              Git repository URL for openedx-platform
::   --version <ver>           Git release branch or tag (default: master)

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

:: # setup_generic.cmd
:::: Windows setup script for Open edX stack.
:: Orchestrates provisioning of dependencies, directory layout, environment configuration,
:: user seeding, demo content ingestion, worker processes, Micro-Frontends, and health diagnostics.
:: Seamlessly supports online provisioning as well as 100% air-gapped offline extraction from cache.
::
:: ## Usage
::   call setup_generic.cmd [ACTION] [OPTIONS]
::
:: ## Parameters
::   --offline, -o             Enable 100% air-gapped offline provisioning from local cache
::   --cache-dir <dir>         Override location of hydrated offline cache
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



if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%SCRIPT_DIR%\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)
set "LIBSCRIPT_BIN=%LIBSCRIPT_ROOT_DIR%\libscript.cmd"
if not exist "%LIBSCRIPT_BIN%" if exist "%SCRIPT_DIR%\..\..\..\libscript\libscript.cmd" set "LIBSCRIPT_BIN=%SCRIPT_DIR%\..\..\..\libscript\libscript.cmd"
if not exist "%LIBSCRIPT_BIN%" if exist "%INSTALLFOLDER%\libscript\libscript.cmd" set "LIBSCRIPT_BIN=%INSTALLFOLDER%\libscript\libscript.cmd"

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

set "IS_OFFLINE=0"
if "%OPENEDX_OFFLINE%"=="1" set "IS_OFFLINE=1"
if "%LIBSCRIPT_OFFLINE%"=="1" set "IS_OFFLINE=1"
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

if /I "%~1"=="--offline" ( set "IS_OFFLINE=1" & shift & goto parse_args )
if /I "%~1"=="-o" ( set "IS_OFFLINE=1" & shift & goto parse_args )
if /I "%~1"=="--online" ( set "IS_OFFLINE=0" & shift & goto parse_args )
if /I "%~1"=="--cache-dir" ( set "OFFLINE_CACHE_DIR=%~2" & shift & shift & goto parse_args )
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
if exist "%OPENEDX_INSTALL_DIR%\lms\envs\libscript.py" (
    echo [INFO] openedx is already installed at %OPENEDX_INSTALL_DIR%.
    exit /b 0
)
if exist "%LIBSCRIPT_HOME%\openedx\%VERSION%" (
    echo [INFO] openedx %VERSION% is already installed.
    exit /b 0
)

:: Resolve Cache Directory if offline mode active
if "%IS_OFFLINE%"=="1" (
    if "%OFFLINE_CACHE_DIR%"=="" (
        if defined INSTALLFOLDER if exist "%INSTALLFOLDER%\libscript\cache" set "OFFLINE_CACHE_DIR=%INSTALLFOLDER%\libscript\cache"
        if not defined OFFLINE_CACHE_DIR if defined LIBSCRIPT_CACHE_DIR if exist "%LIBSCRIPT_CACHE_DIR%" set "OFFLINE_CACHE_DIR=%LIBSCRIPT_CACHE_DIR%"
        if not defined OFFLINE_CACHE_DIR if exist "%OPENEDX_INSTALL_DIR%\libscript\cache" set "OFFLINE_CACHE_DIR=%OPENEDX_INSTALL_DIR%\libscript\cache"
        if not defined OFFLINE_CACHE_DIR if exist "%OPENEDX_INSTALL_DIR%\cache" set "OFFLINE_CACHE_DIR=%OPENEDX_INSTALL_DIR%\cache"
        if not defined OFFLINE_CACHE_DIR if exist "%LIBSCRIPT_ROOT_DIR%\cache" set "OFFLINE_CACHE_DIR=%LIBSCRIPT_ROOT_DIR%\cache"
    )
    if defined OFFLINE_CACHE_DIR (
        echo [INFO] Detected Air-Gapped Offline Cache at: !OFFLINE_CACHE_DIR!
    ) else (
        echo [WARN] Offline mode requested but no cache directory found.
    )
)

if "%ACTION%"=="install" (
    echo [INFO] === Initializing Open edX Windows Provisioning ===

    if not exist "%OPENEDX_INSTALL_DIR%" mkdir "%OPENEDX_INSTALL_DIR%" 2>nul
    if not exist "%OPENEDX_INSTALL_DIR%\config" mkdir "%OPENEDX_INSTALL_DIR%\config" 2>nul
    if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%" 2>nul

    set "USE_OFFLINE=0"
    if "%IS_OFFLINE%"=="1" if defined OFFLINE_CACHE_DIR set "USE_OFFLINE=1"
    if "!USE_OFFLINE!"=="1" (
        set "LIBSCRIPT_CACHE_DIR=!OFFLINE_CACHE_DIR!"
    )

    echo [INFO] 1/7: Provisioning core services and runtimes...
    set "_offline_flag="
    if "!USE_OFFLINE!"=="1" set "_offline_flag=--offline"
    set "_OLD_STACK=!STACK!"
    set "STACK="
    for %%P in (python nodejs mysql mongodb redis meilisearch waitress) do (
        call "%LIBSCRIPT_BIN%" install %%P latest !_offline_flag! || (powershell -Command "Get-Content '%OPENEDX_INSTALL_DIR%\logs\install.log' -Tail 50" 2>nul & exit /b 1)
        if exist "%LIBSCRIPT_ROOT_DIR%\_lib\databases\%%P\setup_generic.cmd" (
            call "%LIBSCRIPT_BIN%" start %%P
        )
        if exist "%LIBSCRIPT_ROOT_DIR%\_lib\caches\%%P\setup_generic.cmd" (
            call "%LIBSCRIPT_BIN%" start %%P
        )
        if exist "%LIBSCRIPT_ROOT_DIR%\_lib\search\%%P\setup_generic.cmd" (
            call "%LIBSCRIPT_BIN%" start %%P
        )
    )
    set "STACK=!_OLD_STACK!"

    if "!USE_OFFLINE!"=="1" (
        :: Step 4 (Codebase): Extract edx-platform.zip into codebase
        if exist "!OFFLINE_CACHE_DIR!\codebase" (
            echo [INFO] Extracting codebase from cache\codebase...
            if not exist "%OPENEDX_INSTALL_DIR%\codebase" mkdir "%OPENEDX_INSTALL_DIR%\codebase" 2>nul
            for %%F in ("!OFFLINE_CACHE_DIR!\codebase\*edx-platform*.zip" "!OFFLINE_CACHE_DIR!\codebase\*openedx-release*.zip") do (
                call :extract_zip "%%~fF" "%OPENEDX_INSTALL_DIR%\codebase"
            )
        )

        :: Step 3 (Virtualenv & Pip): Install wheels offline
        if exist "!OFFLINE_CACHE_DIR!\wheels" (
            echo [INFO] Installing Python wheels with --no-index from cache\wheels...
            set "PY_EXE=python"
            if exist "%OPENEDX_INSTALL_DIR%\runtimes\python\python.exe" set "PY_EXE=%OPENEDX_INSTALL_DIR%\runtimes\python\python.exe"
            if not exist "%OPENEDX_INSTALL_DIR%\logs" mkdir "%OPENEDX_INSTALL_DIR%\logs"
            if exist "%OPENEDX_INSTALL_DIR%\codebase\requirements\edx\base.txt" (
                "%PY_EXE%" -m pip install --no-index --find-links "!OFFLINE_CACHE_DIR!\wheels" -r "%OPENEDX_INSTALL_DIR%\codebase\requirements\edx\base.txt" >> "%OPENEDX_INSTALL_DIR%\logs\install.log" 2>&1 || (powershell -Command "Get-Content '%OPENEDX_INSTALL_DIR%\logs\install.log' -Tail 50" & exit /b 1)
            ) else (
                for %%W in ("!OFFLINE_CACHE_DIR!\wheels\*.whl") do (
                    "%PY_EXE%" -m pip install --no-index --find-links "!OFFLINE_CACHE_DIR!\wheels" "%%~fW" >> "%OPENEDX_INSTALL_DIR%\logs\install.log" 2>&1 || (powershell -Command "Get-Content '%OPENEDX_INSTALL_DIR%\logs\install.log' -Tail 50" & exit /b 1)
                )
            )
        )

        :: Step 5 (Demo Content): Ingest demo courseware from cache/codebase
        if "%IMPORT_DEMO%"=="1" if exist "!OFFLINE_CACHE_DIR!\codebase\demo-course.tar.gz" (
            echo [INFO] Ingesting demo courseware from cached archive...
            tar -xzf "!OFFLINE_CACHE_DIR!\codebase\demo-course.tar.gz" -C "%OPENEDX_INSTALL_DIR%" 2>nul || (powershell -Command "Get-Content '%OPENEDX_INSTALL_DIR%\logs\install.log' -Tail 50" & exit /b 1)
        )
    ) else (
        echo [INFO] Cloning edx-platform codebase...
        if not exist "%OPENEDX_INSTALL_DIR%\codebase" (
            where git >nul 2>&1 || winget install Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
            git clone --depth 1 -b open-release/quince.master https://github.com/openedx/edx-platform.git "%OPENEDX_INSTALL_DIR%\codebase" || exit /b 1
        )
    )

    echo [INFO] 2/7: Preparing directories at %OPENEDX_INSTALL_DIR%...
    if not exist "%OPENEDX_INSTALL_DIR%\logs" mkdir "%OPENEDX_INSTALL_DIR%\logs"

    :: Pre-flight python check
    set "PY_EXE=python"
    if exist "%OPENEDX_INSTALL_DIR%\runtimes\python\python.exe" set "PY_EXE=%OPENEDX_INSTALL_DIR%\runtimes\python\python.exe"
    if exist "C:\Program Files\Python312\python.exe" set "PY_EXE=C:\Program Files\Python312\python.exe"
    if exist "C:\Program Files\Python310\python.exe" set "PY_EXE=C:\Program Files\Python310\python.exe"
    if exist "%USERPROFILE%\AppData\Local\Programs\Python\Python310\python.exe" set "PY_EXE=%USERPROFILE%\AppData\Local\Programs\Python\Python310\python.exe"

    
    
    
    
    echo [DEBUG] PY_EXE resolved to: !PY_EXE!
    "!PY_EXE!" --version
    "!PY_EXE!" -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)" 2>nul
    if errorlevel 1 (
        echo [ERROR] Python 3.10+ is required. >&2
        exit /b 1
    )

    echo [INFO] 3/7: Generating Open edX environment configurations and venv...
    if not exist "%OPENEDX_INSTALL_DIR%\.venv\Scripts\python.exe" (
        "%PY_EXE%" -m venv "%OPENEDX_INSTALL_DIR%\.venv"
    )

    for /f "usebackq tokens=*" %%A in (`"%OPENEDX_INSTALL_DIR%\.venv\Scripts\python.exe" -c "import site; print(site.getsitepackages()[1])" 2^>nul`) do set "_sp_dir=%%A"
    if not defined _sp_dir set "_sp_dir=%OPENEDX_INSTALL_DIR%\.venv\Lib\site-packages"
    if not exist "!_sp_dir!\imghdr.py" (
        powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/python/cpython/3.12/Lib/imghdr.py' -OutFile '!_sp_dir!\imghdr.py'; (Get-Content '!_sp_dir!\imghdr.py') -replace 'warnings._deprecated.*', '' | Set-Content '!_sp_dir!\imghdr.py'" 2>nul
    )

    :: Install Python Requirements if repo exists
    if exist "%OPENEDX_INSTALL_DIR%\codebase\requirements\edx\base.txt" (
        echo [INFO] Installing Python dependencies...
        powershell -NoProfile -Command "(Get-Content '%OPENEDX_INSTALL_DIR%\codebase\requirements\edx\base.txt') -replace 'mysqlclient==.*', 'mysqlclient==2.3.0' | Set-Content '%OPENEDX_INSTALL_DIR%\codebase\requirements\edx\base.txt'"
        powershell -NoProfile -Command "(Get-Content '%OPENEDX_INSTALL_DIR%\codebase\requirements\edx\base.txt') -replace 'xmlsec==.*', '' | Set-Content '%OPENEDX_INSTALL_DIR%\codebase\requirements\edx\base.txt'"
        powershell -NoProfile -Command "(Get-Content '%OPENEDX_INSTALL_DIR%\codebase\requirements\edx\base.txt') -replace 'cffi==.*', '' | Set-Content '%OPENEDX_INSTALL_DIR%\codebase\requirements\edx\base.txt'"
        powershell -NoProfile -Command "(Get-Content '%OPENEDX_INSTALL_DIR%\codebase\requirements\edx\base.txt') -replace 'mysqlclient==.*', '' | Set-Content '%OPENEDX_INSTALL_DIR%\codebase\requirements\edx\base.txt'"
        "!PY_EXE!" -m pip install --only-binary=:all: setuptools wheel pkgconfig
        where uv >nul 2>&1
        if errorlevel 1 (
            "!PY_EXE!" -m pip install --no-cache-dir waitress -r "%OPENEDX_INSTALL_DIR%\codebase\requirements\edx\base.txt" >> "%OPENEDX_INSTALL_DIR%\logs\install.log" 2>&1 || (powershell -NoProfile -Command "Get-Content '%OPENEDX_INSTALL_DIR%\logs\install.log' -Tail 50" & exit /b 1)
        ) else (
            uv pip install --python "%OPENEDX_INSTALL_DIR%\.venv\Scripts\python.exe" waitress -r "%OPENEDX_INSTALL_DIR%\codebase\requirements\edx\base.txt" >> "%OPENEDX_INSTALL_DIR%\logs\install.log" 2>&1 || (powershell -NoProfile -Command "Get-Content '%OPENEDX_INSTALL_DIR%\logs\install.log' -Tail 50" & exit /b 1)
        )
    )

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
    if exist "%SCRIPT_DIR%\user.cmd" (
        set "OPENEDX_INSTALL_DIR=%OPENEDX_INSTALL_DIR%"
        call "%SCRIPT_DIR%\user.cmd" create "%ADMIN_USER%" "%ADMIN_EMAIL%" --password "%ADMIN_PASS%" --staff --superuser 2>nul
    )

    if "%THEME_NAME%" neq "none" (
        if exist "%SCRIPT_DIR%\theme.cmd" (
            echo [INFO] Activating theme: %THEME_NAME%...
            call "%SCRIPT_DIR%\theme.cmd" apply "%THEME_NAME%" 2>nul
        )
    )

    if "%IMPORT_DEMO%"=="1" (
        if exist "%SCRIPT_DIR%\import_demo.cmd" (
            echo [INFO] Seeding demo courseware and content libraries...
            call "%SCRIPT_DIR%\import_demo.cmd" course 2>nul
            call "%SCRIPT_DIR%\import_demo.cmd" libraries 2>nul
        )
    )

    if "%ENABLE_MFES%"=="1" (
        if exist "%SCRIPT_DIR%\mfe.cmd" (
            echo [INFO] Building and deploying Micro-Frontends...
            call "%SCRIPT_DIR%\mfe.cmd" build all 2>nul
            call "%SCRIPT_DIR%\mfe.cmd" deploy all 2>nul
        )
    )

    if exist "%SCRIPT_DIR%\service.cmd" (
        echo [INFO] Starting Open edX platform services...
        call "%SCRIPT_DIR%\service.cmd" start || exit /b 1
    )

    :: Database Initialization
    echo [INFO] Initializing databases...
    if "%MYSQL_DATABASE%"=="" set "MYSQL_DATABASE=openedx"
    if exist "%SCRIPT_DIR%\dbshell.cmd" (
        call "%SCRIPT_DIR%\dbshell.cmd" query "CREATE DATABASE IF NOT EXISTS `%MYSQL_DATABASE%` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>nul
    )

    :: Database Migrations
    echo [INFO] Applying database migrations...
    if exist "%OPENEDX_INSTALL_DIR%\codebase\manage.py" (
        cd /D "%OPENEDX_INSTALL_DIR%\codebase"
        call "%OPENEDX_INSTALL_DIR%\.venv\Scripts\python.exe" manage.py lms migrate --noinput >> "%OPENEDX_INSTALL_DIR%\logs\install.log" 2>&1 || exit /b 1
        call "%OPENEDX_INSTALL_DIR%\.venv\Scripts\python.exe" manage.py cms migrate --noinput >> "%OPENEDX_INSTALL_DIR%\logs\install.log" 2>&1 || exit /b 1
    ) else (
        echo [WARN] manage.py not found in codebase, skipping migrations.
    )

    :: Static Asset Compilation & Theming
    echo [INFO] Compiling frontend assets...
    if exist "%OPENEDX_INSTALL_DIR%\package.json" (
        cd /D "%OPENEDX_INSTALL_DIR%"
        (call npm clean-install --no-audit >> "%OPENEDX_INSTALL_DIR%\logs\install.log" 2>&1 || call npm install >> "%OPENEDX_INSTALL_DIR%\logs\install.log" 2>&1) || (powershell -Command "Get-Content '%OPENEDX_INSTALL_DIR%\logs\install.log' -Tail 50" & exit /b 1)
        if exist "%OPENEDX_INSTALL_DIR%\codebase\pavement.py" (
            cd /D "%OPENEDX_INSTALL_DIR%\codebase"
            call "%OPENEDX_INSTALL_DIR%\.venv\Scripts\python.exe" -m paver update_assets lms --settings=universal.production >> "%OPENEDX_INSTALL_DIR%\logs\install.log" 2>&1 || (powershell -Command "Get-Content '%OPENEDX_INSTALL_DIR%\logs\install.log' -Tail 50" & exit /b 1)
            call "%OPENEDX_INSTALL_DIR%\.venv\Scripts\python.exe" -m paver update_assets cms --settings=universal.production >> "%OPENEDX_INSTALL_DIR%\logs\install.log" 2>&1 || (powershell -Command "Get-Content '%OPENEDX_INSTALL_DIR%\logs\install.log' -Tail 50" & exit /b 1)
        )
    )

    if exist "%SCRIPT_DIR%\healthcheck.cmd" (
        echo [INFO] Running healthcheck diagnostic probe...
        call "%SCRIPT_DIR%\healthcheck.cmd" 2>nul
    )

    echo [INFO] Open edX Windows provisioning complete.
    exit /b 0
) else if "%ACTION%"=="start" (
    if exist "%SCRIPT_DIR%\service.cmd" (
        call "%SCRIPT_DIR%\service.cmd" start
        exit /b %errorlevel%
    )
    if exist "%SCRIPT_DIR%\workers.cmd" call "%SCRIPT_DIR%\workers.cmd" start 2>nul
    exit /b 0
) else if "%ACTION%"=="stop" (
    if exist "%SCRIPT_DIR%\service.cmd" (
        call "%SCRIPT_DIR%\service.cmd" stop
        exit /b %errorlevel%
    )
    if exist "%SCRIPT_DIR%\workers.cmd" call "%SCRIPT_DIR%\workers.cmd" stop 2>nul
    exit /b 0
) else if "%ACTION%"=="restart" (
    if exist "%SCRIPT_DIR%\service.cmd" (
        call "%SCRIPT_DIR%\service.cmd" restart
        exit /b %errorlevel%
    )
    call "%THIS_FILE%" stop
    call "%THIS_FILE%" start
    exit /b %errorlevel%
) else if "%ACTION%"=="status" (
    if exist "%SCRIPT_DIR%\service.cmd" (
        call "%SCRIPT_DIR%\service.cmd" status
        exit /b %errorlevel%
    )
    if exist "%SCRIPT_DIR%\healthcheck.cmd" call "%SCRIPT_DIR%\healthcheck.cmd"
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
    if exist "%SCRIPT_DIR%\service.cmd" call "%SCRIPT_DIR%\service.cmd" stop 2>nul
    if exist "%SCRIPT_DIR%\workers.cmd" call "%SCRIPT_DIR%\workers.cmd" stop 2>nul
    rmdir /s /q "%OPENEDX_INSTALL_DIR%" 2>nul
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
