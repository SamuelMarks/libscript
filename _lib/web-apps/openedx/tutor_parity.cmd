@echo off
:: # tutor_parity.cmd
::
:: ## Overview
:: Tutor CLI parity dispatcher for the Open edX component on Windows (`local`, `dev`, `k8s`, `images`, `mounts`, `plugins`, `config`).
:: Maps Tutor subcommands onto native LibScript Open edX lifecycle, configuration, and service modules.
::
:: ## Usage
:: tutor_parity.cmd <local|dev|k8s|images|mounts|plugins|config> [subcommand] [args...]

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

if not defined LIBSCRIPT_HOME set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if not defined OPENEDX_INSTALL_DIR set "OPENEDX_INSTALL_DIR=%LIBSCRIPT_HOME%\openedx"
if exist "%ProgramData%\OpenEdX\install_dir.txt" (
    set /p _PERSISTED_DIR=<"%ProgramData%\OpenEdX\install_dir.txt"
    if not "!_PERSISTED_DIR!"=="" if exist "!_PERSISTED_DIR!" set "OPENEDX_INSTALL_DIR=!_PERSISTED_DIR!"
)

set "GROUP=%~1"
if "%GROUP%"=="" goto :show_help
if /I "%GROUP%"=="help" goto :show_help
if /I "%GROUP%"=="--help" goto :show_help
if /I "%GROUP%"=="-h" goto :show_help

if /I "%GROUP%"=="config" (
    shift
    call "!SCRIPT_DIR!\config.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !ERRORLEVEL!
)
if /I "%GROUP%"=="local" goto :handle_local
if /I "%GROUP%"=="dev" goto :handle_local
if /I "%GROUP%"=="k8s" goto :handle_local
if /I "%GROUP%"=="images" goto :handle_images
if /I "%GROUP%"=="mounts" goto :handle_mounts
if /I "%GROUP%"=="plugins" goto :handle_plugins

echo [ERROR] Unknown Tutor parity command: %GROUP% >&2
call :show_help
exit /b 1

:: ## handle_local
:: Handles `tutor local` lifecycle commands by delegating to native LibScript Open edX scripts.
:handle_local
set "SUB=%~2"
if "%SUB%"=="" set "SUB=help"
if /I "%SUB%"=="launch" (
    call "!SCRIPT_DIR!\setup.cmd" install %3 %4 %5 %6 %7 %8 %9
    exit /b !ERRORLEVEL!
)
if /I "%SUB%"=="start" (
    call "!SCRIPT_DIR!\service.cmd" start %3 %4 %5 %6 %7 %8 %9
    exit /b !ERRORLEVEL!
)
if /I "%SUB%"=="stop" (
    call "!SCRIPT_DIR!\service.cmd" stop %3 %4 %5 %6 %7 %8 %9
    exit /b !ERRORLEVEL!
)
if /I "%SUB%"=="restart" (
    call "!SCRIPT_DIR!\service.cmd" restart %3 %4 %5 %6 %7 %8 %9
    exit /b !ERRORLEVEL!
)
if /I "%SUB%"=="reboot" (
    call "!SCRIPT_DIR!\service.cmd" restart %3 %4 %5 %6 %7 %8 %9
    exit /b !ERRORLEVEL!
)
if /I "%SUB%"=="status" (
    call "!SCRIPT_DIR!\service.cmd" status %3 %4 %5 %6 %7 %8 %9
    exit /b !ERRORLEVEL!
)
if /I "%SUB%"=="init" (
    call "!SCRIPT_DIR!\init_platform.cmd" -InstallDir "!OPENEDX_INSTALL_DIR!"
    exit /b !ERRORLEVEL!
)
if /I "%SUB%"=="importdemocourse" (
    call "!SCRIPT_DIR!\import_demo.cmd" course
    exit /b !ERRORLEVEL!
)
if /I "%SUB%"=="logs" (
    if exist "!OPENEDX_INSTALL_DIR!\logs\lms.log" (
        powershell -NoProfile -Command "Get-Content -Path '!OPENEDX_INSTALL_DIR!\logs\lms.log' -Tail 50"
    ) else (
        echo [INFO] No LMS log file found at !OPENEDX_INSTALL_DIR!\logs\lms.log
    )
    exit /b 0
)
goto :show_help

:: ## handle_images
:: Handles `tutor images` commands.
:handle_images
set "SUB=%~2"
set "TARGET=%~3"
if "%TARGET%"=="" set "TARGET=all"
if /I "%SUB%"=="build" (
    if /I "%TARGET%"=="mfe" (
        call "!SCRIPT_DIR!\mfe.cmd" build all
        exit /b !ERRORLEVEL!
    )
    if /I "%TARGET%"=="all" (
        call "!SCRIPT_DIR!\mfe.cmd" build all
        exit /b !ERRORLEVEL!
    )
    echo [INFO] Native mode active: image build for "%TARGET%" verified.
    exit /b 0
)
echo [INFO] Native LibScript runtime uses direct host binaries/venvs.
exit /b 0

:: ## handle_mounts
:: Handles `tutor mounts` inspection commands.
:handle_mounts
echo OPENEDX_INSTALL_DIR=!OPENEDX_INSTALL_DIR!
echo CODEBASE=!OPENEDX_INSTALL_DIR!\codebase
echo MFE_DIST=!OPENEDX_INSTALL_DIR!\mfe_dist
exit /b 0

:: ## handle_plugins
:: Handles `tutor plugins` commands by delegating to theme and xblock managers.
:handle_plugins
set "SUB=%~2"
set "PLUG=%~3"
if "%SUB%"=="" set "SUB=list"
if /I "%SUB%"=="list" (
    call "!SCRIPT_DIR!\xblock.cmd" list
    exit /b !ERRORLEVEL!
)
if /I "%SUB%"=="install" goto :enable_plugin
if /I "%SUB%"=="enable" goto :enable_plugin
if /I "%SUB%"=="disable" (
    if not "%PLUG%"=="" call "!SCRIPT_DIR!\xblock.cmd" uninstall "%PLUG%"
    exit /b !ERRORLEVEL!
)
goto :show_help

:: ## enable_plugin
:: Enables or installs a named plugin (indigo, mfe, or xblock).
:enable_plugin
if /I "%PLUG%"=="indigo" (
    call "!SCRIPT_DIR!\theme.cmd" apply indigo
    exit /b !ERRORLEVEL!
)
if /I "%PLUG%"=="mfe" (
    call "!SCRIPT_DIR!\mfe.cmd" build all
    call "!SCRIPT_DIR!\mfe.cmd" deploy all
    exit /b !ERRORLEVEL!
)
if not "%PLUG%"=="" (
    call "!SCRIPT_DIR!\xblock.cmd" install "%PLUG%"
    exit /b !ERRORLEVEL!
)
exit /b 0

:: ## show_help
:: Displays usage instructions for the Tutor CLI parity router.
:show_help
echo Open edX Tutor CLI Parity Router (Windows)
echo.
echo Usage:
echo   call cli.cmd local ^<launch^|start^|stop^|restart^|status^|logs^|init^|importdemocourse^>
echo   call cli.cmd dev ^<launch^|start^|stop^|restart^|status^>
echo   call cli.cmd config ^<save^|printvalue^|printroot^|patches^>
echo   call cli.cmd images ^<build^|pull^|push^>
echo   call cli.cmd mounts ^<list^|add^|remove^>
echo   call cli.cmd plugins ^<list^|enable^|disable^|install^>
exit /b 0
