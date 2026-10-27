@echo off
:: # component_core.cmd
::
:: ## Overview
:: Unified CLI routing and lifecycle management for Windows components.
:: Mirrors component_core.sh with full argument parsing, automated dependency
:: resolution, and Version Manager Contract verb support.
::
:: ## Usage
:: call "%~dp0\..\..\_common\component_core.cmd" %*

setlocal EnableDelayedExpansion
set "CALLER_FILE=!THIS_FILE!"
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

set "COMP_DIR="
if not "%CALLER_FILE%"=="" (
    for %%I in ("%CALLER_FILE%") do set "COMP_DIR=%%~dpI"
)
if "%COMP_DIR:~-1%"=="\" set "COMP_DIR=%COMP_DIR:~0,-1%"
if "!COMP_DIR!"=="" set "COMP_DIR=%CD%"
for %%I in ("!COMP_DIR!") do set "COMP_BASENAME=%%~nxI"
if not defined PACKAGE_NAME set "PACKAGE_NAME=%COMP_BASENAME%"

set "SCHEMA_FILE=!COMP_DIR!\vars.schema.json"
set "MANIFEST_FILE=!COMP_DIR!\manifest.json"
set "BASE_SCHEMA_FILE=!LIBSCRIPT_ROOT_DIR!\_lib\_common\base_vars.schema.json"
set "LOG_CMD=!LIBSCRIPT_ROOT_DIR!\_lib\_common\log.cmd"

set "ACTION=%~1"
set "REQ_PKG=%~2"
set "VERSION=%~3"

if "%ACTION%"=="" goto :show_help
if /i "%ACTION%"=="help" goto :show_help
if /i "%ACTION%"=="--help" goto :show_help
if /i "%ACTION%"=="-h" goto :show_help
if /i "%ACTION%"=="/?" goto :show_help
if /i "%ACTION%"=="-?" goto :show_help

if /i "%ACTION%"=="--version" (
    if defined LIBSCRIPT_VERSION (echo %LIBSCRIPT_VERSION%) else (echo dev)
    exit /b 0
)
if /i "%ACTION%"=="-v" (
    if defined LIBSCRIPT_VERSION (echo %LIBSCRIPT_VERSION%) else (echo dev)
    exit /b 0
)

set "RAW_ARGS=%*"
set "IS_CLOUD_VERB=0"
for %%V in (auth location group project network node dns firewall ssh backup restore diff list-managed storage dashboard cost usage logs-aggregate aws azure gcp hetzner proxmox digitalocean linode vultr cleanup setup deploy) do (
    if /i "%ACTION%"=="%%V" set "IS_CLOUD_VERB=1"
)
if "!IS_CLOUD_VERB!"=="1" (
    shift
    goto :routing
)

set "REQ_BASENAME=!REQ_PKG!"
for %%I in ("!REQ_PKG:/=\!") do set "REQ_BASENAME=%%~nxI"

if "!REQ_PKG!"=="" (
    set "REQ_PKG=!PACKAGE_NAME!"
    set "VERSION=latest"
    shift
) else if "!REQ_PKG:~0,1!"=="-" (
    set "REQ_PKG=!PACKAGE_NAME!"
    set "VERSION=latest"
    shift
) else if /i "!REQ_PKG!"=="!PACKAGE_NAME!" (
    if "!VERSION!"=="" (
        set "VERSION=latest"
        shift & shift
    ) else if "!VERSION:~0,1!"=="-" (
        set "VERSION=latest"
        shift & shift
    ) else (
        shift & shift & shift
    )
) else if /i "!REQ_PKG!"=="!COMP_BASENAME!" (
    if "!VERSION!"=="" (
        set "VERSION=latest"
        shift & shift
    ) else if "!VERSION:~0,1!"=="-" (
        set "VERSION=latest"
        shift & shift
    ) else (
        shift & shift & shift
    )
) else if /i "!REQ_BASENAME!"=="!PACKAGE_NAME!" (
    if "!VERSION!"=="" (
        set "VERSION=latest"
        shift & shift
    ) else if "!VERSION:~0,1!"=="-" (
        set "VERSION=latest"
        shift & shift
    ) else (
        shift & shift & shift
    )
) else if /i "!REQ_BASENAME!"=="!COMP_BASENAME!" (
    if "!VERSION!"=="" (
        set "VERSION=latest"
        shift & shift
    ) else if "!VERSION:~0,1!"=="-" (
        set "VERSION=latest"
        shift & shift
    ) else (
        shift & shift & shift
    )
) else (
    set "VERSION=!REQ_PKG!"
    set "REQ_PKG=!PACKAGE_NAME!"
    shift & shift
)

set "pkg_up=!PACKAGE_NAME!"
for %%A in ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z" "-=_") do set "pkg_up=!pkg_up:%%~A!"
if "!pkg_up!"=="7ZIP" set "pkg_up=SEVENZIP"
if not "!VERSION!"=="" (
    set "!pkg_up!_VERSION=!VERSION!"
    set "LIBSCRIPT_VERSION=!VERSION!"
)

:: ## parse_loop
:: Iterates through remaining CLI flags and exports dynamic configuration variables.
:parse_loop
set "arg=%~1"
if "!arg!"=="" goto :resolve_deps

if /i "!ACTION!"=="start"             goto :routing
if /i "!ACTION!"=="stop"              goto :routing
if /i "!ACTION!"=="restart"           goto :routing
if /i "!ACTION!"=="status"            goto :routing
if /i "!ACTION!"=="health"            goto :routing
if /i "!ACTION!"=="logs"              goto :routing
if /i "!ACTION!"=="up"                goto :routing
if /i "!ACTION!"=="down"              goto :routing
if /i "!ACTION!"=="install-service"   goto :routing
if /i "!ACTION!"=="uninstall-service" goto :routing
if /i "!ACTION!"=="run"               goto :routing
if /i "!ACTION!"=="env"               goto :routing
if /i "!ACTION!"=="exec"              goto :routing
if /i "!ACTION!"=="network"           goto :routing
if /i "!ACTION!"=="firewall"          goto :routing
if /i "!ACTION!"=="node"              goto :routing
if /i "!ACTION!"=="dns"               goto :routing
if /i "!ACTION!"=="ssh"               goto :routing
if /i "!ACTION!"=="cleanup"           goto :routing
if /i "!ACTION!"=="backup"            goto :routing
if /i "!ACTION!"=="restore"           goto :routing
if /i "!ACTION!"=="diff"              goto :routing

if /i "!arg!"=="--offline" (
    set "_next_off=%~2"
    if "!_next_off!"=="0" (
        set "LIBSCRIPT_OFFLINE=0"
        shift & shift
        goto :parse_loop
    )
    if "!_next_off!"=="1" (
        set "LIBSCRIPT_OFFLINE=1"
        shift & shift
        goto :parse_loop
    )
    set "LIBSCRIPT_OFFLINE=1"
    shift
    goto :parse_loop
)
if /i "!arg!"=="--offline=1" (
    set "LIBSCRIPT_OFFLINE=1"
    shift
    goto :parse_loop
)
if /i "!arg!"=="--offline=0" (
    set "LIBSCRIPT_OFFLINE=0"
    shift
    goto :parse_loop
)
if /i "!arg!"=="-o" (
    set "LIBSCRIPT_OFFLINE=1"
    shift
    goto :parse_loop
)
if /i "!arg!"=="--force-offline" (
    set "LIBSCRIPT_FORCE_OFFLINE=1"
    set "LIBSCRIPT_OFFLINE=1"
    shift
    goto :parse_loop
)
if /i "!arg!"=="--online" (
    set "LIBSCRIPT_OFFLINE=0"
    shift
    goto :parse_loop
)
if "!arg:~0,12!"=="--cache-dir=" (
    set "LIBSCRIPT_CACHE_DIR=!arg:~12!"
    shift
    goto :parse_loop
)
if /i "!arg!"=="--cache-dir" (
    set "LIBSCRIPT_CACHE_DIR=%~2"
    shift & shift
    goto :parse_loop
)
if "!arg:~0,15!"=="--download-dir=" (
    set "DOWNLOAD_DIR=!arg:~15!"
    set "LIBSCRIPT_DOWNLOAD_DIR=!arg:~15!"
    shift
    goto :parse_loop
)
if /i "!arg!"=="--download-dir" (
    set "DOWNLOAD_DIR=%~2"
    set "LIBSCRIPT_DOWNLOAD_DIR=%~2"
    shift & shift
    goto :parse_loop
)
if "!arg:~0,9!"=="--prefix=" (
    set "PREFIX=!arg:~9!"
    shift
    goto :parse_loop
)
if "!arg:~0,17!"=="--install-method=" (
    set "_im_val=!arg:~17!"
    set "LIBSCRIPT_DEFAULT_INSTALL_METHOD=!_im_val!"
    if not "!pkg_up!"=="" set "!pkg_up!_INSTALL_METHOD=!_im_val!"
    shift
    goto :parse_loop
)
if /i "!arg!"=="--from-source" (
    set "LIBSCRIPT_DEFAULT_INSTALL_METHOD=from-source"
    if not "!pkg_up!"=="" set "!pkg_up!_INSTALL_METHOD=from-source"
    shift
    goto :parse_loop
)
if "!arg:~0,10!"=="--pkg-mgr=" (
    set "_pm_val=!arg:~10!"
    set "LIBSCRIPT_PKG_MGR=!_pm_val!"
    if not "!pkg_up!"=="" (
        set "!pkg_up!_PKG_MGR=!_pm_val!"
        if not defined !pkg_up!_INSTALL_METHOD set "!pkg_up!_INSTALL_METHOD=system"
    )
    shift
    goto :parse_loop
)
if "!arg:~0,12!"=="--toolchain=" (
    set "_tc_val=!arg:~12!"
    set "LIBSCRIPT_BUILD_TOOLCHAIN=!_tc_val!"
    if not "!pkg_up!"=="" (
        set "!pkg_up!_BUILD_TOOLCHAIN=!_tc_val!"
        set "!pkg_up!_COMPILER=!_tc_val!"
    )
    shift
    goto :parse_loop
)
if "!arg:~0,16!"=="--with-compiler=" (
    set "_tc_val=!arg:~16!"
    set "LIBSCRIPT_BUILD_TOOLCHAIN=!_tc_val!"
    if not "!pkg_up!"=="" (
        set "!pkg_up!_BUILD_TOOLCHAIN=!_tc_val!"
        set "!pkg_up!_COMPILER=!_tc_val!"
    )
    shift
    goto :parse_loop
)
if "!arg:~0,12!"=="--custom-cc=" (
    set "_cc_val=!arg:~12!"
    set "CUSTOM_CC_BIN=!_cc_val!"
    set "LIBSCRIPT_CUSTOM_CC_BIN=!_cc_val!"
    set "LIBSCRIPT_BUILD_TOOLCHAIN=custom-cc"
    set "LIBSCRIPT_DEFAULT_INSTALL_METHOD=from-source"
    if not "!pkg_up!"=="" (
        set "!pkg_up!_BUILD_TOOLCHAIN=custom-cc"
        set "!pkg_up!_COMPILER=custom-cc"
        set "!pkg_up!_INSTALL_METHOD=from-source"
    )
    shift
    goto :parse_loop
)
if "!arg:~0,15!"=="--service-name=" (
    set "LIBSCRIPT_SERVICE_NAME=!arg:~15!"
    shift
    goto :parse_loop
)

if "!arg:~0,2!"=="--" (
    set "key_val=!arg:~2!"
    for /f "tokens=1* delims==" %%A in ("!key_val!") do (
        set "key=%%A"
        set "val=%%B"
    )
    if "!val!"=="" (
        set "_next_arg=%~2"
        set "_use_next=0"
        if not "!_next_arg!"=="" (
            if not "!_next_arg:~0,1!"=="-" set "_use_next=1"
        )
        if "!_use_next!"=="1" (
            set "val=!_next_arg!"
            shift
        ) else (
            set "val=true"
        )
    )
    set "key=!key:-=_!"
    set "!key!=!val!"
)

shift
goto :parse_loop

:: ## resolve_deps
:: Resolves and installs declared schema dependencies before executing setup or install.
:resolve_deps
goto :routing

:: ## routing
:: Dispatches the requested lifecycle verb to the matching component script or handler.
:routing
if defined PREFIX (
    set "INSTALLED_DIR=!PREFIX!"
) else if defined LIBSCRIPT_HOME (
    set "INSTALLED_DIR=!LIBSCRIPT_HOME!\!PACKAGE_NAME!\!VERSION!"
) else (
    set "INSTALLED_DIR=%USERPROFILE%\.libscript\!PACKAGE_NAME!\!VERSION!"
)

if /i "!ACTION!"=="info" (
    echo Component: !PACKAGE_NAME!
    echo Version: !VERSION!
    echo Install Path: !INSTALLED_DIR!
    if exist "!INSTALLED_DIR!" (
        echo Status: Installed
    ) else (
        echo Status: Not Installed
    )
    exit /b 0
)

if /i "!ACTION!"=="ls" (
    if defined LIBSCRIPT_HOME (
        set "PKG_ROOT=!LIBSCRIPT_HOME!\!PACKAGE_NAME!"
    ) else (
        set "PKG_ROOT=%USERPROFILE%\.libscript\!PACKAGE_NAME!"
    )
    if exist "!PKG_ROOT!" (
        dir /b /ad "!PKG_ROOT!" 2>nul
    )
    exit /b 0
)

if /i "!ACTION!"=="ls-remote" (
    if exist "%MANIFEST_FILE%" (
        where jq >nul 2>&1
        if !errorlevel! equ 0 (
            jq -r ".versions[]? // empty" "%MANIFEST_FILE%" 2>nul
            exit /b 0
        )
    )
    echo latest
    exit /b 0
)

if /i "!ACTION!"=="use" (
    if exist "!INSTALLED_DIR!\bin" (
        set "PATH=!INSTALLED_DIR!\bin;!PATH!"
        echo Using !PACKAGE_NAME! !VERSION! at !INSTALLED_DIR!
        exit /b 0
    )
    if exist "!COMP_DIR!\env.cmd" (
        call "!COMP_DIR!\env.cmd"
        exit /b !errorlevel!
    )
    exit /b 0
)

if /i "!ACTION!"=="which" (
    if exist "!INSTALLED_DIR!\bin\!PACKAGE_NAME!.exe" (
        echo !INSTALLED_DIR!\bin\!PACKAGE_NAME!.exe
        exit /b 0
    )
    where "!PACKAGE_NAME!" 2>nul
    exit /b !errorlevel!
)

if /i "!ACTION!"=="run" (
    if exist "!INSTALLED_DIR!\bin\!PACKAGE_NAME!.exe" (
        "!INSTALLED_DIR!\bin\!PACKAGE_NAME!.exe" %1 %2 %3 %4 %5 %6 %7 %8 %9
        exit /b !errorlevel!
    )
    echo [ERROR] !PACKAGE_NAME! version !VERSION! not installed at !INSTALLED_DIR! >&2
    exit /b 1
)

if /i "!ACTION!"=="exec" (
    if exist "!INSTALLED_DIR!\bin" set "PATH=!INSTALLED_DIR!\bin;!PATH!"
    %1 %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)

if /i "!ACTION!"=="env" (
    if not defined FORMAT set "FORMAT=cmd"
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" "!FORMAT!" "!INSTALLED_DIR!"
    exit /b !errorlevel!
)

if /i "!ACTION!"=="test" (
    if exist "!INSTALLED_DIR!\bin" set "PATH=!INSTALLED_DIR!\bin;!PATH!"
    if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links" set "PATH=%LOCALAPPDATA%\Microsoft\WinGet\Links;!PATH!"
    if exist "%ProgramFiles%\CMake\bin" set "PATH=%ProgramFiles%\CMake\bin;!PATH!"
    if exist "%ProgramFiles%\nodejs" set "PATH=%ProgramFiles%\nodejs;!PATH!"
    if exist "%LOCALAPPDATA%\Programs\Python\Python312" set "PATH=%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;!PATH!"
    if exist "%ProgramFiles%\Python312" set "PATH=%ProgramFiles%\Python312;%ProgramFiles%\Python312\Scripts;!PATH!"
    if exist "%USERPROFILE%\.cargo\bin" set "PATH=%USERPROFILE%\.cargo\bin;!PATH!"
    for /d %%P in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\MartinStorsjo.LLVM-MinGW*\llvm-mingw*\bin") do (
        if exist "%%~fP" set "PATH=%%~fP;!PATH!"
    )
    set "STACK="
    if exist "!COMP_DIR!\test.cmd" (
        call "!COMP_DIR!\test.cmd"
        exit /b !errorlevel!
    )
    if exist "!COMP_DIR!\test.ps1" (
        powershell -ExecutionPolicy Bypass -File "!COMP_DIR!\test.ps1"
        exit /b !errorlevel!
    )
    echo Error: test.cmd not found in !COMP_DIR! 1>&2
    exit /b 1
)

if /i "!ACTION!"=="uninstall" set "ACTION=remove"
if /i "!ACTION!"=="remove" (
    if exist "!COMP_DIR!\uninstall.cmd" (
        call "!COMP_DIR!\uninstall.cmd"
        exit /b !errorlevel!
    )
    if exist "!COMP_DIR!\uninstall_generic.cmd" (
        call "!COMP_DIR!\uninstall_generic.cmd"
        exit /b !errorlevel!
    )
    if exist "!COMP_DIR!\uninstall.ps1" (
        powershell -ExecutionPolicy Bypass -File "!COMP_DIR!\uninstall.ps1"
        exit /b !errorlevel!
    )
    if exist "!INSTALLED_DIR!" (
        rmdir /s /q "!INSTALLED_DIR!" 2>nul
    )
    exit /b 0
)

if /i "!ACTION!"=="start"             goto :service_action
if /i "!ACTION!"=="stop"              goto :service_action
if /i "!ACTION!"=="restart"           goto :service_action
if /i "!ACTION!"=="status"            goto :service_action
if /i "!ACTION!"=="health"            goto :service_action
if /i "!ACTION!"=="logs"              goto :service_action
if /i "!ACTION!"=="up"                goto :service_action
if /i "!ACTION!"=="down"              goto :service_action
if /i "!ACTION!"=="install-service"   goto :service_action
if /i "!ACTION!"=="uninstall-service" goto :service_action
goto :default_action

:: ## service_action
:: Routes service daemon verbs (start, stop, status, logs, install-service) to component scripts.
:service_action
if exist "!COMP_DIR!\!ACTION!.cmd" (
    call "!COMP_DIR!\!ACTION!.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)
if exist "!COMP_DIR!\service.cmd" (
    call "!COMP_DIR!\service.cmd" "!ACTION!" "!PACKAGE_NAME!" "!VERSION!"
    exit /b !errorlevel!
)
if exist "!COMP_DIR!\setup.cmd" (
    call "!COMP_DIR!\setup.cmd" "!ACTION!" %1 %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)
exit /b 0

:: ## default_action
:: Routes download, install, setup, or custom verbs to component scripts.
:default_action
set "STACK="
if /i not "!ACTION!"=="install" if /i not "!ACTION!"=="setup" (
    if exist "!COMP_DIR!\!ACTION!.cmd" (
        call "!COMP_DIR!\!ACTION!.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
        exit /b !errorlevel!
    )
)
if exist "!COMP_DIR!\setup.cmd" (
    if "!IS_CLOUD_VERB!"=="1" (
        call "!COMP_DIR!\setup.cmd" !RAW_ARGS!
        exit /b !errorlevel!
    )
    call "!COMP_DIR!\setup.cmd" "!ACTION!" %1 %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)
echo Error: setup.cmd not found in !COMP_DIR! 1>&2
exit /b 1

:: ## show_help
:: Displays standardized CLI usage, supported versions, and schema options.
:show_help
echo Usage: cli.cmd [COMMAND] [PACKAGE_NAME] [VERSION] [OPTIONS]
echo.
echo Commands:
echo   download, install, ls, ls-remote, use, start, stop, restart, status, health,
echo   logs, install-service, uninstall-service, uninstall, test, env, which, run, exec
echo.
if exist "%MANIFEST_FILE%" (
    where jq >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "delims=" %%A in ('jq -r "if .title and .description then .title + \": \" + .description elif .title then .title elif .description then .description else \"\" end" "%MANIFEST_FILE%"') do (
            if not "%%A"=="" echo   %%A
        )
        for /f "delims=" %%A in ('jq -r --arg p "Supported Versions: " --arg s ", " "if .versions then $p + (.versions | join($s)) else empty end" "%MANIFEST_FILE%"') do (
            if not "%%A"=="" echo   %%A
        )
    )
)
echo.
echo Available Options:
where jq >nul 2>&1
if !errorlevel! equ 0 (
    if exist "%SCHEMA_FILE%" (
        jq -n --slurpfile base "%BASE_SCHEMA_FILE%" --slurpfile comp "%SCHEMA_FILE%" "($base[0].properties // {}) * ($comp[0].properties // {}) | to_entries[] | \"  --\" + .key + \"=\" + (.value.default // \"none\") + \"\t\" + .value.description" 2>nul
    )
) else (
    echo   ^(jq is required for dynamic options list^)
)
exit /b 0
