@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface router for the WordPress 7.1.2 platform on Windows.
:: Dispatches subcommands to core lifecycle handlers or dedicated feature modules:
:: user, config, dbshell, healthcheck, backup, restore, service, cron, upgrade, and wp.
::
:: ## Usage
::   call cli.cmd <subcommand> [args...]
::   call cli.cmd help

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

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%SCRIPT_DIR%\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "CMD=%~1"
if "%CMD%"=="" goto show_help
if "%CMD%"=="help" goto show_help
if "%CMD%"=="--help" goto show_help
if "%CMD%"=="-h" goto show_help

shift
if /I "%CMD%"=="start" goto do_service
if /I "%CMD%"=="stop" goto do_service
if /I "%CMD%"=="restart" goto do_service
if /I "%CMD%"=="status" goto do_service
if /I "%CMD%"=="service" goto do_service
if /I "%CMD%"=="user" goto do_user
if /I "%CMD%"=="config" goto do_config
if /I "%CMD%"=="dbshell" goto do_dbshell
if /I "%CMD%"=="sql" goto do_dbshell
if /I "%CMD%"=="query" goto do_dbshell
if /I "%CMD%"=="healthcheck" goto do_healthcheck
if /I "%CMD%"=="health" goto do_healthcheck
if /I "%CMD%"=="backup" goto do_backup
if /I "%CMD%"=="restore" goto do_restore
if /I "%CMD%"=="cron" goto do_cron
if /I "%CMD%"=="upgrade" goto do_upgrade
if /I "%CMD%"=="wp" goto do_wp

echo [ERROR] Unknown subcommand: %CMD% >&2
goto show_help

:: ## do_service
:: Executes do_service functionality.
:do_service
call "%SCRIPT_DIR%\service.cmd" %CMD% %*
exit /b %ERRORLEVEL%

:: ## do_user
:: Executes do_user functionality.
:do_user
call "%SCRIPT_DIR%\user.cmd" %*
exit /b %ERRORLEVEL%

:: ## do_config
:: Executes do_config functionality.
:do_config
call "%SCRIPT_DIR%\config.cmd" %*
exit /b %ERRORLEVEL%

:: ## do_dbshell
:: Executes do_dbshell functionality.
:do_dbshell
call "%SCRIPT_DIR%\dbshell.cmd" %*
exit /b %ERRORLEVEL%

:: ## do_healthcheck
:: Executes do_healthcheck functionality.
:do_healthcheck
call "%SCRIPT_DIR%\healthcheck.cmd" %*
exit /b %ERRORLEVEL%

:: ## do_backup
:: Executes do_backup functionality.
:do_backup
call "%SCRIPT_DIR%\backup.cmd" %*
exit /b %ERRORLEVEL%

:: ## do_restore
:: Executes do_restore functionality.
:do_restore
call "%SCRIPT_DIR%\restore.cmd" %*
exit /b %ERRORLEVEL%

:: ## do_cron
:: Executes do_cron functionality.
:do_cron
call "%SCRIPT_DIR%\cron.cmd" %*
exit /b %ERRORLEVEL%

:: ## do_upgrade
:: Executes do_upgrade functionality.
:do_upgrade
call "%SCRIPT_DIR%\upgrade.cmd" %*
exit /b %ERRORLEVEL%

:: ## do_wp
:: Executes do_wp functionality.
:do_wp
where wp >nul 2>&1
if not errorlevel 1 (
    wp %*
    exit /b %ERRORLEVEL%
)
if exist "%LIBSCRIPT_ROOT_DIR%\cache\wp-cli.phar" (
    php "%LIBSCRIPT_ROOT_DIR%\cache\wp-cli.phar" %*
    exit /b %ERRORLEVEL%
)
echo [ERROR] WP-CLI executable or phar not found. >&2
exit /b 1

:: ## show_help
:: Executes show_help functionality.
:show_help
echo WordPress 7.1.2 Management Console on Windows
echo.
echo Usage:
echo   call cli.cmd ^<subcommand^> [args...]
echo.
echo Subcommands:
echo   user        WordPress user administration (create, list, set-password, delete)
echo   config      Read and modify wp-config.php and stack environment configuration
echo   dbshell     Interactive MySQL database shell and query executor
echo   healthcheck Run comprehensive system diagnostics and connectivity tests
echo   backup      Create full-state snapshot archives of database, uploads, and config
echo   restore     Restore WordPress database and files from snapshot archive
echo   service     Manage web server and background services
echo   cron        Manage and trigger scheduled WP-Cron background tasks
echo   upgrade     Execute safe WordPress release upgrade pipeline
echo   wp          Execute raw WP-CLI commands against WordPress document root
exit /b 0
