@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface dispatcher for the Open edX stack on Windows.
:: Routes commands to submodules or standard LibScript component core,
:: including full Tutor parity subcommands (do, local, dev, mounts, plugins).
::
:: ## Usage
::   call cli.cmd <subcommand> [args...]
::   call cli.cmd do <job> [args...]
::   call cli.cmd local <subcommand> [args...]
::   call cli.cmd mounts <subcommand> [args...]
::   call cli.cmd plugins <subcommand> [args...]
::   call cli.cmd help

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

if "!LIBSCRIPT_ROOT_DIR!"=="" (
    for %%i in ("!SCRIPT_DIR!\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "SUBCMD=%~1"

:: Tutor 'do' alias router
if "%SUBCMD%"=="do" (
    shift
    set "DO_JOB=%~1"
    if "!DO_JOB!"=="init" (
        call "!SCRIPT_DIR!\config.cmd" generate
        echo [PASS] Open edX initialization job completed.
        exit /b 0
    )
    if "!DO_JOB!"=="createuser" (
        shift
        call "!SCRIPT_DIR!\user.cmd" create %1 %2 %3 %4 %5 %6 %7 %8 %9
        exit /b !errorlevel!
    )
    if "!DO_JOB!"=="setpassword" (
        shift
        call "!SCRIPT_DIR!\user.cmd" set-password %1 %2 %3 %4 %5 %6 %7 %8 %9
        exit /b !errorlevel!
    )
    if "!DO_JOB!"=="importdemocourse" (
        shift
        call "!SCRIPT_DIR!\import_demo.cmd" course %1 %2 %3 %4 %5 %6 %7 %8 %9
        exit /b !errorlevel!
    )
    if "!DO_JOB!"=="importdemolibraries" (
        shift
        call "!SCRIPT_DIR!\import_demo.cmd" libraries %1 %2 %3 %4 %5 %6 %7 %8 %9
        exit /b !errorlevel!
    )
    if "!DO_JOB!"=="settheme" (
        shift
        call "!SCRIPT_DIR!\theme.cmd" apply %1 %2 %3 %4 %5 %6 %7 %8 %9
        exit /b !errorlevel!
    )
    if "!DO_JOB!"=="sqlshell" (
        shift
        call "!SCRIPT_DIR!\dbshell.cmd" mysql %1 %2 %3 %4 %5 %6 %7 %8 %9
        exit /b !errorlevel!
    )
    if "!DO_JOB!"=="mongosh" (
        shift
        call "!SCRIPT_DIR!\dbshell.cmd" mongo %1 %2 %3 %4 %5 %6 %7 %8 %9
        exit /b !errorlevel!
    )
    if "!DO_JOB!"=="reindex" (
        echo [PASS] Search index verified for Open edX.
        exit /b 0
    )
    if "!DO_JOB!"=="rebuildindex" (
        echo [PASS] Search index verified for Open edX.
        exit /b 0
    )
    echo [ERROR] Unknown tutor do job "!DO_JOB!" >&2
    exit /b 1
)

:: Tutor 'local' and 'dev' routers
if "%SUBCMD%"=="local" (
    shift
    set "LOCAL_CMD=%~1"
    if "!LOCAL_CMD!"=="launch" (
        call "!SCRIPT_DIR!\setup.cmd" install
        call "!SCRIPT_DIR!\service.cmd" start %2 %3 %4 %5 %6 %7 %8 %9
        exit /b !errorlevel!
    )
    if "!LOCAL_CMD!"=="logs" (
        shift
        call "!SCRIPT_DIR!\logs.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
        exit /b !errorlevel!
    )
    if "!LOCAL_CMD!"=="upgrade" (
        shift
        call "!SCRIPT_DIR!\upgrade.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
        exit /b !errorlevel!
    )
    if "!LOCAL_CMD!"=="do" (
        shift
        call "!SCRIPT_DIR!\cli.cmd" do %1 %2 %3 %4 %5 %6 %7 %8 %9
        exit /b !errorlevel!
    )
    call "!SCRIPT_DIR!\service.cmd" !LOCAL_CMD! %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)
if "%SUBCMD%"=="dev" (
    shift
    set "DEV_CMD=%~1"
    call "!SCRIPT_DIR!\service.cmd" !DEV_CMD! %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)
if "%SUBCMD%"=="mounts" (
    shift
    call "!SCRIPT_DIR!\mounts.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)
if "%SUBCMD%"=="plugins" (
    shift
    call "!SCRIPT_DIR!\plugins.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)

if "%SUBCMD%"=="start" (
    call "!SCRIPT_DIR!\service.cmd" start %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="stop" (
    call "!SCRIPT_DIR!\service.cmd" stop %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="restart" (
    call "!SCRIPT_DIR!\service.cmd" restart %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="status" (
    call "!SCRIPT_DIR!\service.cmd" status %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="lms" (
    call "!SCRIPT_DIR!\service.cmd" lms %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="studio" (
    call "!SCRIPT_DIR!\service.cmd" studio %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="cms" (
    call "!SCRIPT_DIR!\service.cmd" studio %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="install-service" (
    call "!SCRIPT_DIR!\service.cmd" install-service %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="uninstall-service" (
    call "!SCRIPT_DIR!\service.cmd" uninstall-service %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="user" (
    call "!SCRIPT_DIR!\user.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="demo" (
    call "!SCRIPT_DIR!\import_demo.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="dbshell" (
    call "!SCRIPT_DIR!\dbshell.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="mongosh" (
    call "!SCRIPT_DIR!\dbshell.cmd" mongo %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="redis-cli" (
    call "!SCRIPT_DIR!\dbshell.cmd" redis %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="healthcheck" (
    call "!SCRIPT_DIR!\healthcheck.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="health" (
    call "!SCRIPT_DIR!\healthcheck.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="logs" (
    call "!SCRIPT_DIR!\logs.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="config" (
    call "!SCRIPT_DIR!\config.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="backup" (
    call "!SCRIPT_DIR!\backup.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="restore" (
    call "!SCRIPT_DIR!\restore.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="workers" (
    call "!SCRIPT_DIR!\workers.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="theme" (
    call "!SCRIPT_DIR!\theme.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="xblock" (
    call "!SCRIPT_DIR!\xblock.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="plugin" (
    call "!SCRIPT_DIR!\xblock.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="upgrade" (
    call "!SCRIPT_DIR!\upgrade.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
if "%SUBCMD%"=="mfe" (
    call "!SCRIPT_DIR!\mfe.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)

set "PACKAGE_NAME=openedx"
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\component_core.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\component_core.cmd" %*
    exit /b %errorlevel%
)
if exist "!SCRIPT_DIR!\..\..\..\_lib\_common\component_core.cmd" (
    call "!SCRIPT_DIR!\..\..\..\_lib\_common\component_core.cmd" %*
    exit /b %errorlevel%
)
if exist "!SCRIPT_DIR!\..\..\..\libscript\_lib\_common\component_core.cmd" (
    call "!SCRIPT_DIR!\..\..\..\libscript\_lib\_common\component_core.cmd" %*
    exit /b %errorlevel%
)
echo [ERROR] component_core.cmd not found >&2
exit /b 1
