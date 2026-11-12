@echo off
:: # component_core.cmd
:: ## Overview
:: Unified CLI routing and lifecycle management for Windows components. Mirrors component_core.sh with full argument parsing, automated dependency resolution, and Version Manager Contract verb support.
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

if /i "%ACTION%"==":libscript_Synchronize_Ingress" goto :dispatch_synchronize_ingress
if /i "%ACTION%"=="--synchronize-ingress" goto :dispatch_synchronize_ingress
if /i "%ACTION%"=="synchronize-ingress" goto :dispatch_synchronize_ingress
if /i "%ACTION%"==":libscript_Warmup_Ollama" goto :dispatch_warmup_ollama
if /i "%ACTION%"=="--warmup-ollama" goto :dispatch_warmup_ollama
if /i "%ACTION%"=="warmup-ollama" goto :dispatch_warmup_ollama

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
for %%V in (auth location group project compartment network node dns firewall ssh backup restore diff list-managed storage dashboard cost usage logs-aggregate aws azure gcp hetzner proxmox digitalocean linode vultr oci ovh cleanup setup deploy) do (
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
    for %%X in (exe cmd bat) do (
        if exist "!INSTALLED_DIR!\bin\!PACKAGE_NAME!.%%X" (
            echo !INSTALLED_DIR!\bin\!PACKAGE_NAME!.%%X
            exit /b 0
        )
    )
    for %%F in ("!INSTALLED_DIR!\bin\*.exe" "!INSTALLED_DIR!\bin\*.cmd" "!INSTALLED_DIR!\bin\*.bat") do (
        if exist "%%~fF" (
            echo %%~fF
            exit /b 0
        )
    )
    where "!PACKAGE_NAME!" 2>nul
    exit /b !errorlevel!
)

if /i "!ACTION!"=="run" (
    for %%X in (exe cmd bat) do (
        if exist "!INSTALLED_DIR!\bin\!PACKAGE_NAME!.%%X" (
            call "!INSTALLED_DIR!\bin\!PACKAGE_NAME!.%%X" %1 %2 %3 %4 %5 %6 %7 %8 %9
            exit /b !errorlevel!
        )
    )
    for %%F in ("!INSTALLED_DIR!\bin\*.exe" "!INSTALLED_DIR!\bin\*.cmd" "!INSTALLED_DIR!\bin\*.bat") do (
        if exist "%%~fF" (
            call "%%~fF" %1 %2 %3 %4 %5 %6 %7 %8 %9
            exit /b !errorlevel!
        )
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
    if exist "!INSTALLED_DIR!" set "PATH=!INSTALLED_DIR!;!PATH!"
    if exist "%USERPROFILE%\.local\bin" set "PATH=%USERPROFILE%\.local\bin;!PATH!"
    if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links" set "PATH=%LOCALAPPDATA%\Microsoft\WinGet\Links;!PATH!"
    if exist "C:\ProgramData\chocolatey\bin" set "PATH=C:\ProgramData\chocolatey\bin;!PATH!"
    if exist "%USERPROFILE%\scoop\shims" set "PATH=%USERPROFILE%\scoop\shims;!PATH!"
    if exist "%ProgramFiles%\7-Zip" set "PATH=%ProgramFiles%\7-Zip;!PATH!"
    if exist "%ProgramFiles%\qemu" set "PATH=%ProgramFiles%\qemu;!PATH!"
    if exist "%ProgramFiles%\Oracle\VirtualBox" set "PATH=%ProgramFiles%\Oracle\VirtualBox;!PATH!"
    if exist "%ProgramFiles%\Vagrant\bin" set "PATH=%ProgramFiles%\Vagrant\bin;!PATH!"
    if exist "C:\HashiCorp\Vagrant\bin" set "PATH=C:\HashiCorp\Vagrant\bin;!PATH!"
    if exist "%ProgramFiles%\Git\cmd" set "PATH=%ProgramFiles%\Git\cmd;!PATH!"
    if exist "%ProgramFiles%\LLVM\bin" set "PATH=%ProgramFiles%\LLVM\bin;!PATH!"
    if exist "%ProgramFiles%\Go\bin" set "PATH=%ProgramFiles%\Go\bin;!PATH!"
    if exist "%ProgramFiles%\dotnet" set "PATH=%ProgramFiles%\dotnet;!PATH!"
    if exist "%ProgramFiles%\Amazon\AWSCLIV2" set "PATH=%ProgramFiles%\Amazon\AWSCLIV2;!PATH!"
    if exist "%ProgramFiles%\Microsoft SDKs\Azure\CLI2\wbin" set "PATH=%ProgramFiles%\Microsoft SDKs\Azure\CLI2\wbin;!PATH!"
    if exist "%ProgramFiles(x86)%\Microsoft SDKs\Azure\CLI2\wbin" set "PATH=%ProgramFiles(x86)%\Microsoft SDKs\Azure\CLI2\wbin;!PATH!"
    if exist "%LOCALAPPDATA%\Google\Cloud SDK\google-cloud-sdk\bin" set "PATH=%LOCALAPPDATA%\Google\Cloud SDK\google-cloud-sdk\bin;!PATH!"
    if exist "%ProgramFiles(x86)%\Google\Cloud SDK\google-cloud-sdk\bin" set "PATH=%ProgramFiles(x86)%\Google\Cloud SDK\google-cloud-sdk\bin;!PATH!"
    if exist "%ProgramFiles%\Google\Cloud SDK\google-cloud-sdk\bin" set "PATH=%ProgramFiles%\Google\Cloud SDK\google-cloud-sdk\bin;!PATH!"
    if exist "%USERPROFILE%\.libscript\nodejs\latest" set "PATH=%USERPROFILE%\.libscript\nodejs\latest;!PATH!"
    if exist "%USERPROFILE%\.libscript\nodejs\default" set "PATH=%USERPROFILE%\.libscript\nodejs\default;!PATH!"
    if exist "C:\msys64\clangarm64\bin" set "PATH=C:\msys64\clangarm64\bin;!PATH!"
    if exist "C:\msys64\ucrt64\bin" set "PATH=C:\msys64\ucrt64\bin;!PATH!"
    if exist "C:\msys64\mingw64\bin" set "PATH=C:\msys64\mingw64\bin;!PATH!"
    if exist "C:\msys64\usr\bin" set "PATH=C:\msys64\usr\bin;!PATH!"
    if exist "C:\ProgramData\chocolatey\lib\elixir\tools\bin" set "PATH=C:\ProgramData\chocolatey\lib\elixir\tools\bin;!PATH!"
    for /d %%E in ("%ProgramFiles%\erl*") do (
        if exist "%%~fE\bin" set "PATH=%%~fE\bin;!PATH!"
    )
    for /d %%T in ("C:\tools\*") do (
        if exist "%%~fT\bin" (
            set "PATH=%%~fT\bin;!PATH!"
        ) else if exist "%%~fT" (
            set "PATH=%%~fT;!PATH!"
        )
    )
    if exist "%ProgramFiles%\CMake\bin" set "PATH=%ProgramFiles%\CMake\bin;!PATH!"
    if exist "%ProgramFiles%\nodejs" set "PATH=%ProgramFiles%\nodejs;!PATH!"
    for /d %%P in ("C:\Python*" "%ProgramFiles%\Python*" "%LOCALAPPDATA%\Programs\Python\Python*") do (
        if exist "%%~fP\Scripts" set "PATH=%%~fP\Scripts;!PATH!"
        if exist "%%~fP\python.exe" set "PATH=%%~fP;!PATH!"
    )
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

:: ## dispatch_synchronize_ingress
:: Runs :libscript_Synchronize_Ingress and exports NETCTL_PROXY_* to the caller scope.
:dispatch_synchronize_ingress
call :libscript_Synchronize_Ingress "%~2" "%~3" "%~4" "%~5"
endlocal & (
    set "NETCTL_PROXY_CONNECT_TIMEOUT=%NETCTL_PROXY_CONNECT_TIMEOUT%"
    set "NETCTL_PROXY_SEND_TIMEOUT=%NETCTL_PROXY_SEND_TIMEOUT%"
    set "NETCTL_PROXY_READ_TIMEOUT=%NETCTL_PROXY_READ_TIMEOUT%"
    set "NETCTL_PROXY_BUFFERING=%NETCTL_PROXY_BUFFERING%"
)
exit /b 0

:: ## dispatch_warmup_ollama
:: Runs :libscript_Warmup_Ollama and exports OLLAMA_KEEP_ALIVE and OLLAMA_NUM_GPU to the caller scope.
:dispatch_warmup_ollama
call :libscript_Warmup_Ollama "%~2"
endlocal & (
    set "OLLAMA_KEEP_ALIVE=%OLLAMA_KEEP_ALIVE%"
    set "OLLAMA_NUM_GPU=%OLLAMA_NUM_GPU%"
)
exit /b 0

:: ## libscript_Synchronize_Ingress
:: Extracts .ingress.proxy_connect_timeout, .ingress.proxy_send_timeout, .ingress.proxy_read_timeout, and .ingress.proxy_buffering from libscript.json, normalizes numeric seconds to '<N>s', exports NETCTL_PROXY_*, and invokes netctl.cmd with the corresponding --proxy-* flags.
:libscript_Synchronize_Ingress
set "_LSI_JSON=%~1"
if "!_LSI_JSON!"=="" set "_LSI_JSON=libscript.json"
if not exist "!_LSI_JSON!" exit /b 0
set "_LSI_CONN="
set "_LSI_SEND="
set "_LSI_READ="
set "_LSI_BUF="
where jq >nul 2>&1
if not errorlevel 1 (
    jq -e ".ingress != null" "!_LSI_JSON!" >nul 2>&1
    if errorlevel 1 exit /b 0
    for /f "delims=" %%P in ('jq -r ".ingress.proxy_connect_timeout // empty" "!_LSI_JSON!" 2^>nul') do if not "%%P"=="" if not "%%P"=="null" set "_LSI_CONN=%%P"
    for /f "delims=" %%P in ('jq -r ".ingress.proxy_send_timeout // empty" "!_LSI_JSON!" 2^>nul') do if not "%%P"=="" if not "%%P"=="null" set "_LSI_SEND=%%P"
    for /f "delims=" %%P in ('jq -r ".ingress.proxy_read_timeout // empty" "!_LSI_JSON!" 2^>nul') do if not "%%P"=="" if not "%%P"=="null" set "_LSI_READ=%%P"
    for /f "delims=" %%P in ('jq -r ".ingress.proxy_buffering // empty" "!_LSI_JSON!" 2^>nul') do if not "%%P"=="" if not "%%P"=="null" set "_LSI_BUF=%%P"
)
if "!_LSI_CONN!"=="" set "_LSI_CONN=%NETCTL_PROXY_CONNECT_TIMEOUT%"
if "!_LSI_CONN!"=="" set "_LSI_CONN=60s"
echo "!_LSI_CONN!" | findstr /R "^[0-9][0-9]*$" >nul 2>&1
if not errorlevel 1 set "_LSI_CONN=!_LSI_CONN!s"

if "!_LSI_SEND!"=="" set "_LSI_SEND=%NETCTL_PROXY_SEND_TIMEOUT%"
if "!_LSI_SEND!"=="" set "_LSI_SEND=300s"
echo "!_LSI_SEND!" | findstr /R "^[0-9][0-9]*$" >nul 2>&1
if not errorlevel 1 set "_LSI_SEND=!_LSI_SEND!s"

if "!_LSI_READ!"=="" set "_LSI_READ=%NETCTL_PROXY_READ_TIMEOUT%"
if "!_LSI_READ!"=="" set "_LSI_READ=300s"
echo "!_LSI_READ!" | findstr /R "^[0-9][0-9]*$" >nul 2>&1
if not errorlevel 1 set "_LSI_READ=!_LSI_READ!s"

if "!_LSI_BUF!"=="" set "_LSI_BUF=%NETCTL_PROXY_BUFFERING%"
if "!_LSI_BUF!"=="" set "_LSI_BUF=off"
if /i "!_LSI_BUF!"=="true" set "_LSI_BUF=on"
if /i "!_LSI_BUF!"=="1" set "_LSI_BUF=on"
if /i "!_LSI_BUF!"=="false" set "_LSI_BUF=off"
if /i "!_LSI_BUF!"=="0" set "_LSI_BUF=off"

set "NETCTL_PROXY_CONNECT_TIMEOUT=!_LSI_CONN!"
set "NETCTL_PROXY_SEND_TIMEOUT=!_LSI_SEND!"
set "NETCTL_PROXY_READ_TIMEOUT=!_LSI_READ!"
set "NETCTL_PROXY_BUFFERING=!_LSI_BUF!"

if "%LIBSCRIPT_DRY_RUN%"=="1" if "%~2"=="" exit /b 0

set "_LSI_NETCTL=!LIBSCRIPT_ROOT_DIR!\_lib\networking\netctl\netctl.cmd"
if not exist "!_LSI_NETCTL!" set "_LSI_NETCTL=!LIBSCRIPT_ROOT_DIR!\_lib\networking\netctl\cli.cmd"
set "_LSI_ARGS=%~2 %~3 %~4 %~5"
set "_LSI_TRIM=!_LSI_ARGS: =!"
if "!_LSI_TRIM!"=="" set "_LSI_ARGS=--reload"
set "STACK="
call "!_LSI_NETCTL!" apply "!_LSI_JSON!" --proxy-connect-timeout "!NETCTL_PROXY_CONNECT_TIMEOUT!" --proxy-send-timeout "!NETCTL_PROXY_SEND_TIMEOUT!" --proxy-read-timeout "!NETCTL_PROXY_READ_TIMEOUT!" --proxy-buffering "!NETCTL_PROXY_BUFFERING!" !_LSI_ARGS!
exit /b !ERRORLEVEL!

:: ## libscript_Warmup_Ollama
:: Pre-warms gemma:2b in Ollama with keep_alive: "30m" and OLLAMA_NUM_GPU=0 on Windows.
:libscript_Warmup_Ollama
set "_LWO_MOD=%~1"
if "!_LWO_MOD!"=="" set "_LWO_MOD=%OLLAMA_DEFAULT_MODEL%"
if "!_LWO_MOD!"=="" set "_LWO_MOD=gemma:2b"
set "_LWO_KA=%OLLAMA_KEEP_ALIVE%"
if "!_LWO_KA!"=="" set "_LWO_KA=30m"
set "OLLAMA_KEEP_ALIVE=!_LWO_KA!"
if "%OLLAMA_NUM_GPU%"=="" set "OLLAMA_NUM_GPU=0"
if "%LIBSCRIPT_DRY_RUN%"=="1" exit /b 0
where curl.exe >nul 2>&1
if errorlevel 1 exit /b 0
set "_LWO_URL=%OLLAMA_HOST%"
if "!_LWO_URL!"=="" set "_LWO_URL=http://127.0.0.1:11434"
if "!_LWO_URL:~-1!"=="/" set "_LWO_URL=!_LWO_URL:~0,-1!"
if /i "!_LWO_URL:~-3!"=="/v1" set "_LWO_URL=!_LWO_URL:~0,-3!"
:: libscript-allow-raw-curl
curl.exe -sS --connect-timeout 5 --max-time 120 -H "Content-Type: application/json" -d "{\"model\":\"!_LWO_MOD!\",\"prompt\":\"warmup\",\"stream\":false,\"keep_alive\":\"!_LWO_KA!\",\"options\":{\"num_predict\":1,\"num_ctx\":512,\"num_gpu\":0}}" "!_LWO_URL!/api/generate" >nul 2>&1
exit /b 0
