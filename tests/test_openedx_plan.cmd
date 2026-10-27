@echo off
:: # test_openedx_plan.cmd
:: ## Overview
:: Orchestrates the Open edX Test Plan as defined in TEST_OPENEDX_PLAN.md.
:: This batch script is idempotent and corresponds to the POSIX shell script version.
::
:: ## Usage
:: tests\test_openedx_plan.cmd [-o target_os] [step]
:: Examples:
::   tests\test_openedx_plan.cmd 0            :: Run Step 0 on debian-13
::   tests\test_openedx_plan.cmd -o macos-14-arm64 1  :: Run Step 1 on macos

setlocal EnableDelayedExpansion

set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /I /C:":%THIS_FILE%:" >nul 2^>^&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" ^>^&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
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
:: Strip trailing backslash
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: Resolve repository root
set "LIBSCRIPT_ROOT_DIR="
set "d=%SCRIPT_DIR%"
:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "%d%\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=%d%"
    goto :found_root
)
for %%a in ("%d%") do set "parent=%%~dpa"
set "parent=%parent:~0,-1%"
if "%d%"=="%parent%" (
    echo [ERROR] libscript.cmd not found in any parent directory. 1>&2
    exit /b 1
)
set "d=%parent%"
goto :find_root
:: ## found_root
:: Performs the found_root operation and updates component state.
:found_root

set "TARGET_OS=debian-13"
set "STEP=0"

:: ## parse_args
:: Parses command-line arguments and populates configuration variables.
:parse_args
if "%~1"=="" goto :end_args
if "%~1"=="-o" (
    set "TARGET_OS=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--os" (
    set "TARGET_OS=%~2"
    shift
    shift
    goto :parse_args
)
:: Check if argument is a number 0-9
echo %~1| findstr /r "^[0-9]$" >nul
if not errorlevel 1 (
    set "STEP=%~1"
    shift
    goto :parse_args
)
echo [ERROR] Unknown option %~1 1>&2
exit /b 1
:: ## end_args
:: Performs the end_args operation and updates component state.
:end_args

set "VAGRANT_DIR=%LIBSCRIPT_ROOT_DIR%\vagrant\%TARGET_OS%"
set "LIBSCRIPT_TEST_TARGET=openedx"

if "%STEP%"=="0" (
    call :run_step_0
    exit /b %ERRORLEVEL%
) else if "%STEP%"=="1" (
    call :run_step_1
    exit /b %ERRORLEVEL%
) else if "%STEP%"=="2" (
    call :run_step_2
    exit /b %ERRORLEVEL%
) else if "%STEP%"=="3" (
    call :run_step_3
    exit /b %ERRORLEVEL%
) else (
    echo [ERROR] Unknown step: %STEP% 1>&2
    exit /b 1
)

:: ## run_step_0
:: Executes Step 0 of the Open edX test plan: Provision local Vagrant machine
:: and run basic sanity checks (SSH accessibility).
:run_step_0
echo === Step 0: Test locally on Vagrant (%TARGET_OS%) ===

if not exist "%VAGRANT_DIR%" (
    echo [ERROR] Vagrant directory %VAGRANT_DIR% not found. 1>&2
    exit /b 1
)

cd /d "%VAGRANT_DIR%"

echo [INFO] Bringing up Vagrant machine (%TARGET_OS%) without provisioner...
:: Idempotent: vagrant up is safe to run if the machine is already running
vagrant status | findstr /c:"running (" >nul
if errorlevel 1 (
    vagrant up --no-provision
    if errorlevel 1 (
        echo [ERROR] Failed to bring up Vagrant machine 1>&2
        exit /b 1
    )
) else (
    echo [INFO] Vagrant machine is already running.
)

echo [INFO] Running basic sanity checks (SSH)...
vagrant ssh -c "hostname"
if errorlevel 1 (
    echo [ERROR] Failed to SSH into the Vagrant machine. 1>&2
    exit /b 1
)

echo [PASS] Vagrant machine is provisioned and accessible.
exit /b 0

:: ## run_step_1
:: Executes Step 1 of the Open edX test plan: Rsync libscript over and install Open edX.
:run_step_1
echo === Step 1: Install Open edX via SSH (%TARGET_OS%) ===

cd /d "%VAGRANT_DIR%"

echo [INFO] Syncing libscript payload to target machine via Vagrant rsync...
vagrant rsync
if errorlevel 1 (
    echo [ERROR] Failed to rsync libscript payload. 1>&2
    exit /b 1
)

echo [INFO] Executing Open edX installation script on target machine...
echo !TARGET_OS! | findstr /b /i "windows" >nul
if not errorlevel 1 (
    vagrant ssh -c "cmd.exe /c \"C:\libscript\libscript.cmd install openedx\""
) else (
    vagrant ssh -c "sudo /opt/repos/libscript/libscript.sh install openedx"
)
if errorlevel 1 (
    echo [ERROR] Installation failed. 1>&2
    exit /b 1
)
echo [PASS] Installation complete.
exit /b 0

:: ## run_step_2
:: Executes Step 2 of the Open edX test plan: Show status & Component-Level Debugging.
:run_step_2
echo === Step 2: Show status ^& Component-Level Debugging (%TARGET_OS%) ===

cd /d "%VAGRANT_DIR%"

echo !TARGET_OS! | findstr /b /i "windows" >nul
if not errorlevel 1 (
    echo [INFO] Checking Toolchains (Python ^& Node.js)...
    vagrant ssh -c "powershell -Command \"python --version; node --version\""

    echo [INFO] Checking Databases (MongoDB ^& MySQL)...
    vagrant ssh -c "cmd.exe /c \"call C:\libscript\_lib\databases\mongodb\status.cmd & call C:\libscript\_lib\databases\mysql\status.cmd\""

    echo [INFO] Checking Message Brokers ^& Caching (RabbitMQ ^& Redis)...
    vagrant ssh -c "cmd.exe /c \"call C:\libscript\_lib\message-brokers\rabbitmq\status.cmd & call C:\libscript\_lib\caches\redis\status.cmd & call C:\libscript\_lib\caches\memcached\status.cmd\""

    echo [INFO] Checking Application Services (LMS ^& CMS)...
    vagrant ssh -c "cmd.exe /c \"call C:\libscript\_lib\web-apps\openedx\cli.cmd status\""

    echo [INFO] Checking General System Health...
    vagrant ssh -c "powershell -Command \"Get-PSDrive -PSProvider FileSystem; hostname\""
) else (
    echo [INFO] Checking Toolchains (Python ^& Node.js)...
    vagrant ssh -c "python3 --version && node --version || true"

    echo [INFO] Checking Databases (MongoDB ^& MySQL)...
    vagrant ssh -c "sudo /opt/repos/libscript/_lib/databases/mongodb/status.sh || true"
    vagrant ssh -c "sudo /opt/repos/libscript/_lib/databases/mysql/status.sh || true"

    echo [INFO] Checking Message Brokers ^& Caching (RabbitMQ ^& Redis)...
    vagrant ssh -c "sudo /opt/repos/libscript/_lib/message-brokers/rabbitmq/status.sh || true"
    vagrant ssh -c "sudo /opt/repos/libscript/_lib/caches/redis/status.sh || true"
    vagrant ssh -c "sudo /opt/repos/libscript/_lib/caches/memcached/status.sh || true"

    echo [INFO] Checking Application Services (LMS ^& CMS)...
    vagrant ssh -c "sudo /opt/repos/libscript/_lib/web-apps/openedx/cli.sh status || sudo systemctl status openedx-lms || sudo rc-service openedx-lms status || sudo service openedx-lms status || true"

    echo [INFO] Checking General System Health...
    vagrant ssh -c "df -h && free -m && uptime || true"
)

echo [PASS] Component debugging status checks completed.
exit /b 0

:: ## run_step_3
:: Executes Step 3 of the Open edX test plan: Show logs.
:run_step_3
echo === Step 3: Show logs (%TARGET_OS%) ===

cd /d "%VAGRANT_DIR%"

echo !TARGET_OS! | findstr /b /i "windows" >nul
if not errorlevel 1 (
    echo [INFO] Checking Databases (MongoDB ^& MySQL)...
    vagrant ssh -c "cmd.exe /c \"call C:\libscript\_lib\databases\mongodb\logs.cmd & call C:\libscript\_lib\databases\mysql\logs.cmd\""

    echo [INFO] Checking Message Brokers ^& Caching (RabbitMQ ^& Redis)...
    vagrant ssh -c "cmd.exe /c \"call C:\libscript\_lib\message-brokers\rabbitmq\logs.cmd & call C:\libscript\_lib\caches\redis\logs.cmd & call C:\libscript\_lib\caches\memcached\logs.cmd\""

    echo [INFO] Checking Application Services (LMS ^& CMS)...
    vagrant ssh -c "cmd.exe /c \"call C:\libscript\_lib\web-apps\openedx\logs.cmd\""
) else (
    echo [INFO] Checking Databases (MongoDB ^& MySQL)...
    vagrant ssh -c "sudo /opt/repos/libscript/_lib/databases/mongodb/logs.sh || true"
    vagrant ssh -c "sudo /opt/repos/libscript/_lib/databases/mysql/logs.sh || true"

    echo [INFO] Checking Message Brokers ^& Caching (RabbitMQ ^& Redis)...
    vagrant ssh -c "sudo /opt/repos/libscript/_lib/message-brokers/rabbitmq/logs.sh || true"
    vagrant ssh -c "sudo /opt/repos/libscript/_lib/caches/redis/logs.sh || true"
    vagrant ssh -c "sudo /opt/repos/libscript/_lib/caches/memcached/logs.sh || true"

    echo [INFO] Checking Application Services (LMS ^& CMS)...
    vagrant ssh -c "sudo /opt/repos/libscript/_lib/web-apps/openedx/logs.sh || sudo journalctl -u openedx-lms --no-pager -n 50 || sudo tail -n 50 /var/log/openedx-lms.log || sudo tail -n 50 /var/svc/log/application-openedx-lms:default.log || true"
)

echo [PASS] Log inspection completed.
exit /b 0
