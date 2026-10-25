@echo off
:: # libscript.cmd
::
:: ## Overview
:: Main entry point for the libscript framework.
:: 
:: ## Usage
:: Execute this script to access global libscript functionality.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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

:: Source logging (must be after SCRIPT_DIR)
set "LOG_CMD=!SCRIPT_DIR!\_lib\_common\log.cmd"

:: Pre-scan arguments for global offline and cache flags
for %%A in (%*) do (
    if /i "%%~A"=="--offline" set "LIBSCRIPT_OFFLINE=1"
    if /i "%%~A"=="-o" set "LIBSCRIPT_OFFLINE=1"
    if /i "%%~A"=="--force-offline" (
        set "LIBSCRIPT_FORCE_OFFLINE=1"
        set "LIBSCRIPT_OFFLINE=1"
    )
    if /i "%%~A"=="--online" set "LIBSCRIPT_OFFLINE=0"
)

:: Global Option Parsing
:: ## opt_loop
:: Performs the opt_loop operation and updates component state.
:opt_loop
set "arg=%~1"
if "!arg!"=="" goto :run_cmd
set "is_opt=0"
if /i "!arg!"=="--offline" (
    set "LIBSCRIPT_OFFLINE=1"
    set "is_opt=1"
)
if /i "!arg!"=="-o" (
    set "LIBSCRIPT_OFFLINE=1"
    set "is_opt=1"
)
if /i "!arg!"=="--force-offline" (
    set "LIBSCRIPT_FORCE_OFFLINE=1"
    set "LIBSCRIPT_OFFLINE=1"
    set "is_opt=1"
)
if /i "!arg!"=="--online" (
    set "LIBSCRIPT_OFFLINE=0"
    set "is_opt=1"
)
if "!arg:~0,12!"=="--cache-dir=" (
    set "LIBSCRIPT_CACHE_DIR=!arg:~12!"
    set "is_opt=1"
)
if /i "!arg!"=="--cache-dir" (
    set "LIBSCRIPT_CACHE_DIR=%~2"
    shift
    set "is_opt=1"
)
if "!arg:~0,15!"=="--download-dir=" (
    set "DOWNLOAD_DIR=!arg:~15!"
    set "LIBSCRIPT_DOWNLOAD_DIR=!arg:~15!"
    set "is_opt=1"
)
if /i "!arg!"=="--download-dir" (
    set "DOWNLOAD_DIR=%~2"
    set "LIBSCRIPT_DOWNLOAD_DIR=%~2"
    shift
    set "is_opt=1"
)
if "!arg:~0,9!"=="--prefix=" (
    set "PREFIX=!arg:~9!"
    set "is_opt=1"
)
if "!arg:~0,13!"=="--log-format=" (
    set "LIBSCRIPT_LOG_FORMAT=!arg:~13!"
    set "is_opt=1"
)
if "!arg:~0,12!"=="--log-level=" (
    set "LIBSCRIPT_LOG_LEVEL=!arg:~12!"
    set "is_opt=1"
)
if "!arg:~0,11!"=="--log-file=" (
    set "LIBSCRIPT_LOG_FILE=!arg:~11!"
    set "is_opt=1"
)
if "!arg:~0,10!"=="--secrets=" (
    set "LIBSCRIPT_SECRETS=!arg:~10!"
    set "is_opt=1"
)

if "!is_opt!"=="1" (
    shift
    goto :opt_loop
)

:: ## run_cmd
:: Performs the run_cmd operation and updates component state.
:run_cmd
set "cmd=%~1"
if "%cmd%"=="" goto show_help
if /i "%cmd%"=="help" goto show_help
if /i "%cmd%"=="--help" goto show_help
if /i "%cmd%"=="-h" goto show_help
if /i "%cmd%"=="/?" goto show_help
if /i "%cmd%"=="-?" goto show_help

if /i "%cmd%"=="--version" (
    if defined LIBSCRIPT_VERSION (
        echo %LIBSCRIPT_VERSION%
    ) else (
        echo dev
    )
    exit /b 0
)
if /i "%cmd%"=="-v" (
    if defined LIBSCRIPT_VERSION (
        echo %LIBSCRIPT_VERSION%
    ) else (
        echo dev
    )
    exit /b 0
)

:: Delegate commands to sub-scripts
if /i "%cmd%"=="list" ( call "!SCRIPT_DIR!\cli\commands\core\list.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="search" ( call "!SCRIPT_DIR!\cli\commands\core\search.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="provision" ( call "!SCRIPT_DIR!\cli\commands\cloud\provision.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="deprovision" ( call "!SCRIPT_DIR!\cli\commands\cloud\deprovision.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="netctl" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\networking\netctl\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)
if /i "%cmd%"=="deploy-remote" ( call "!SCRIPT_DIR!\cli\commands\cloud\deploy-remote.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="package-as" ( call "!SCRIPT_DIR!\cli\commands\packaging\package-as.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="install-deps" ( call "!SCRIPT_DIR!\cli\commands\deps\install.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="db-search" ( call "!SCRIPT_DIR!\cli\commands\registry\search.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="update-db" ( call "!SCRIPT_DIR!\cli\commands\registry\update.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="semver" ( call "!SCRIPT_DIR!\cli\commands\core\semver.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="config" ( call "!SCRIPT_DIR!\cli\commands\config\config.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="repogen" ( call "!SCRIPT_DIR!\_lib\orchestration\repogen\repogen.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="distro" ( call "!SCRIPT_DIR!\_lib\orchestration\distro\distro.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="payload" ( call "!SCRIPT_DIR!\payloads\engine.cmd" %2 %3 %4 %5 %6 %7 %8 %9 & exit /b !errorlevel! )
if /i "%cmd%"=="topology" ( call "!SCRIPT_DIR!\topologies\engine.cmd" %2 %3 %4 %5 %6 %7 %8 %9 & exit /b !errorlevel! )
if /i "%cmd%"=="trait" ( call "!SCRIPT_DIR!\traits\engine.cmd" %2 %3 %4 %5 %6 %7 %8 %9 & exit /b !errorlevel! )
if /i "%cmd%"=="cloud" ( call "!SCRIPT_DIR!\_lib\cloud\core\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9 & exit /b !errorlevel! )
if /i "%cmd%"=="train" ( call "!SCRIPT_DIR!\cli\commands\ml\actions.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="infer" ( call "!SCRIPT_DIR!\cli\commands\ml\actions.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="serve-ml" ( call "!SCRIPT_DIR!\cli\commands\ml\actions.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="eval-ml" ( call "!SCRIPT_DIR!\cli\commands\ml\actions.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="env" (
    if /i "%~2"=="--manifest" (
        set "_env_manifest=%~3"
        if "!_env_manifest!"=="" set "_env_manifest=libscript.json"
        call "!SCRIPT_DIR!\_lib\_common\env_printer.cmd" --manifest "!_env_manifest!" "%~4"
        exit /b !errorlevel!
    )
    if "%~2"=="" (
        call "!SCRIPT_DIR!\_lib\_common\env_printer.cmd" --manifest "libscript.json" "cmd"
        exit /b !errorlevel!
    )
)

if /i "%cmd%"=="start" set "is_docker_cmd=1"
if /i "%cmd%"=="stop" set "is_docker_cmd=1"
if /i "%cmd%"=="status" set "is_docker_cmd=1"
if /i "%cmd%"=="logs" set "is_docker_cmd=1"
if /i "%cmd%"=="health" set "is_docker_cmd=1"
if /i "%cmd%"=="restart" set "is_docker_cmd=1"
if /i "%cmd%"=="up" set "is_docker_cmd=1"
if /i "%cmd%"=="down" set "is_docker_cmd=1"
if /i "%cmd%"=="deprovision-db" set "is_docker_cmd=1"
if /i "%cmd%"=="export-state" set "is_docker_cmd=1"
if /i "%cmd%"=="import-state" set "is_docker_cmd=1"
if /i "%cmd%"=="prepare-storage" set "is_docker_cmd=1"
if /i "%cmd%"=="uninstall-service" (
    if "%~2"=="" set "is_docker_cmd=1"
    if /i "%~2"=="libscript.json" set "is_docker_cmd=1"
    echo %~2 | findstr /i "\.json$" >nul && set "is_docker_cmd=1"
)

if "!is_docker_cmd!"=="1" (
    if not "%LIBSCRIPT_INTERNAL_START%"=="1" (
        call "!SCRIPT_DIR!\cli\commands\services\actions.cmd" %*
        exit /b !errorlevel!
    )
)

set "is_action=0"
set "req_version=0"
if /i "%cmd%"=="use" ( set "is_action=1" & set "req_version=1" )
if /i "%cmd%"=="install" ( set "is_action=1" )
if /i "%cmd%"=="download" ( set "is_action=1" )
if /i "%cmd%"=="install-service" ( set "is_action=1" )
if /i "%cmd%"=="uninstall-service" ( set "is_action=1" )

if /i "%cmd%"=="remove" set "is_action=1"
if /i "%cmd%"=="uninstall" set "is_action=1"
if /i "%cmd%"=="status" set "is_action=1"
if /i "%cmd%"=="health" set "is_action=1"
if /i "%cmd%"=="start" set "is_action=1"
if /i "%cmd%"=="stop" set "is_action=1"
if /i "%cmd%"=="restart" set "is_action=1"
if /i "%cmd%"=="logs" set "is_action=1"
if /i "%cmd%"=="up" set "is_action=1"
if /i "%cmd%"=="down" set "is_action=1"
if /i "%cmd%"=="test" set "is_action=1"
if /i "%cmd%"=="run" ( set "is_action=1" & set "req_version=1" )
if /i "%cmd%"=="which" ( set "is_action=1" & set "req_version=1" )
if /i "%cmd%"=="exec" ( set "is_action=1" & set "req_version=1" )
if /i "%cmd%"=="env" ( set "is_action=1" & set "req_version=1" )
if /i "%cmd%"=="serve" ( set "is_action=1" & set "req_version=1" )
if /i "%cmd%"=="route" ( set "is_action=1" & set "req_version=1" )
if /i "%cmd%"=="ls" set "is_action=1"
if /i "%cmd%"=="ls-remote" set "is_action=1"
if /i "%cmd%"=="list-managed" ( set "action_pkg=cloud" & goto match_component )
if /i "%cmd%"=="backup" ( set "action_pkg=cloud" & goto match_component )
if /i "%cmd%"=="restore" ( set "action_pkg=cloud" & goto match_component )
if /i "%cmd%"=="diff" ( set "action_pkg=cloud" & goto match_component )


if "%is_action%"=="1" (
    if "%~2"=="" (
        echo Error: package_name is required for %cmd% 1>&2
        exit /b 1
    )
    if "!req_version!"=="1" (
        if "%~3"=="" (
            echo Error: version is required for %cmd% 1>&2
            exit /b 1
        )
    )
    set "action_pkg=%~2"
    goto match_component
) else (
    set "action_pkg=%cmd%"
    goto match_component
)

:: ## match_component
:: Performs the match_component operation and updates component state.
:match_component
set "target="
set "action_pkg_norm=!action_pkg:\=/!"
if /i "!action_pkg_norm!"=="cloud-providers/gcp/cli" set "action_pkg_norm=_lib/cloud-providers/gcp-cli"
if /i "!action_pkg_norm!"=="gcp/cli" set "action_pkg_norm=_lib/cloud-providers/gcp-cli"
if /i "!action_pkg_norm!"=="cloud-providers/gcp/tpu-vm" set "action_pkg_norm=_lib/cloud-providers/gcp-tpu-vm"
if /i "!action_pkg_norm!"=="gcp/tpu-vm" set "action_pkg_norm=_lib/cloud-providers/gcp-tpu-vm"
if /i "!action_pkg_norm!"=="cloud-providers/gcp/gpu-vm" set "action_pkg_norm=_lib/cloud-providers/gcp-gpu-vm"
if /i "!action_pkg_norm!"=="gcp/gpu-vm" set "action_pkg_norm=_lib/cloud-providers/gcp-gpu-vm"
if /i "!action_pkg_norm!"=="cloud-providers/gcp/filestore" set "action_pkg_norm=_lib/cloud-providers/gcp-filestore"
if /i "!action_pkg_norm!"=="gcp/filestore" set "action_pkg_norm=_lib/cloud-providers/gcp-filestore"
if /i "!action_pkg_norm!"=="cloud-providers/gcp/gke-tpu-cluster" set "action_pkg_norm=topologies/gke-tpu-cluster"
if /i "!action_pkg_norm!"=="gcp/gke-tpu-cluster" set "action_pkg_norm=topologies/gke-tpu-cluster"
if /i "!action_pkg_norm!"=="gke-tpu-cluster" set "action_pkg_norm=topologies/gke-tpu-cluster"
if /i "!action_pkg_norm!"=="cloud/storage" set "action_pkg_norm=_lib/cloud/storage"
if /i "!action_pkg_norm!"=="cloud/cdn" set "action_pkg_norm=_lib/cloud/cdn"
if /i "!action_pkg_norm!"=="cloud/cert" set "action_pkg_norm=_lib/cloud/cert"
if /i "!action_pkg_norm!"=="cloud/volume" set "action_pkg_norm=_lib/cloud/volume"
if /i "!action_pkg_norm!"=="cloud/cloudinit" set "action_pkg_norm=_lib/cloud/cloudinit"
if /i "!action_pkg_norm!"=="stacks/ml-training/tpu-vm-eval-node" set "action_pkg_norm=_lib/ml-training"
if /i "!action_pkg_norm!"=="ml-training/tpu-vm-eval-node" set "action_pkg_norm=_lib/ml-training"
if /i "!action_pkg_norm!"=="tpu-vm-eval-node" set "action_pkg_norm=_lib/ml-training"
if /i "!action_pkg_norm!"=="stacks/ml-training/gke-xpk-training" set "action_pkg_norm=_lib/orchestration/gke-xpk-training"
if /i "!action_pkg_norm!"=="ml-training/gke-xpk-training" set "action_pkg_norm=_lib/orchestration/gke-xpk-training"
if /i "!action_pkg_norm!"=="gke-xpk-training" set "action_pkg_norm=_lib/orchestration/gke-xpk-training"
if /i "!action_pkg_norm!"=="stacks/ai-serving/tpu-vm-vllm" set "action_pkg_norm=_lib/ai-serving"
if /i "!action_pkg_norm!"=="ai-serving/tpu-vm-vllm" set "action_pkg_norm=_lib/ai-serving"
if /i "!action_pkg_norm!"=="tpu-vm-vllm" set "action_pkg_norm=_lib/ai-serving"
if /i "!action_pkg_norm!"=="stacks/ai-serving/gke-xpk-inference" set "action_pkg_norm=_lib/ai-serving/gke-xpk-inference"
if /i "!action_pkg_norm!"=="ai-serving/gke-xpk-inference" set "action_pkg_norm=_lib/ai-serving/gke-xpk-inference"
if /i "!action_pkg_norm!"=="gke-xpk-inference" set "action_pkg_norm=_lib/ai-serving/gke-xpk-inference"
if /i "!action_pkg_norm!"=="stacks/cms/openedx" set "action_pkg_norm=_lib/web-apps/openedx"
if /i "!action_pkg_norm!"=="stacks/cms/wordpress" set "action_pkg_norm=_lib/web-apps/wordpress"
if /i "!action_pkg_norm!"=="stacks/cms/drupal" set "action_pkg_norm=_lib/web-apps/drupal"
if /i "!action_pkg_norm!"=="stacks/cms/joomla" set "action_pkg_norm=_lib/web-apps/joomla"
if /i "!action_pkg_norm!"=="stacks/ecommerce/woocommerce" set "action_pkg_norm=_lib/web-apps/woocommerce"
if /i "!action_pkg_norm!"=="stacks/ecommerce/magento" set "action_pkg_norm=_lib/web-apps/magento"
if /i "!action_pkg_norm!"=="stacks/ecommerce/prestashop" set "action_pkg_norm=_lib/web-apps/prestashop"
if /i "!action_pkg_norm!"=="stacks/collaboration/nextcloud" set "action_pkg_norm=_lib/web-apps/nextcloud"
if /i "!action_pkg_norm!"=="stacks/crawlers/firecrawl" set "action_pkg_norm=_lib/web-apps/firecrawl"
if /i "!action_pkg_norm!"=="stacks/data-science/jupyterhub" set "action_pkg_norm=_lib/web-apps/jupyterhub"
if /i "!action_pkg_norm!"=="stacks/erp/odoo" set "action_pkg_norm=_lib/web-apps/odoo"
if /i "!action_pkg_norm!"=="stacks/forums/phpbb" set "action_pkg_norm=_lib/web-apps/phpbb"
if /i "!action_pkg_norm!"=="stacks/networking/openvpn" set "action_pkg_norm=_lib/networking/openvpn"
if /i "!action_pkg_norm!"=="stacks/scaffolds/serve-actix-diesel-auth-scaffold" set "action_pkg_norm=_lib/web-apps/serve-actix-diesel-auth-scaffold"
if /i "!action_pkg_norm!"=="stacks/task-queues/celery" set "action_pkg_norm=_lib/web-apps/celery"
if /i "!action_pkg_norm!"=="stacks/virtualization/bento-builder" set "action_pkg_norm=_lib/virtualization/bento-builder"

set "action_pkg=!action_pkg_norm:/=\!"
if /i "!action_pkg!"=="cloud" (
    set "target=!SCRIPT_DIR!\_lib\cloud\core"
    goto run_target
)
if exist "!SCRIPT_DIR!\!action_pkg!\cli.cmd" (
    set "target=!SCRIPT_DIR!\!action_pkg!"
    goto run_target
)
if exist "!SCRIPT_DIR!\_lib\!action_pkg!\cli.cmd" (
    set "target=!SCRIPT_DIR!\_lib\!action_pkg!"
    goto run_target
)
if exist "!SCRIPT_DIR!\topologies\!action_pkg!\cli.cmd" (
    set "target=!SCRIPT_DIR!\topologies\!action_pkg!"
    goto run_target
)
if exist "!SCRIPT_DIR!\payloads\!action_pkg!\cli.cmd" (
    set "target=!SCRIPT_DIR!\payloads\!action_pkg!"
    goto run_target
)
if exist "!SCRIPT_DIR!\_lib\_common\!action_pkg!\cli.cmd" (
    set "target=!SCRIPT_DIR!\_lib\_common\!action_pkg!"
    goto run_target
)

:: Direct category search: _lib\<cat>\<pkg>\cli.cmd or topologies\<pkg>\cli.cmd or payloads\<cat>\<pkg>\cli.cmd
for /d %%C in ("!SCRIPT_DIR!\_lib\*" "!SCRIPT_DIR!\topologies\*" "!SCRIPT_DIR!\payloads\*") do (
    if exist "%%C\!action_pkg!\cli.cmd" (
        set "target=%%C\!action_pkg!"
        goto run_target
    )
)

set "match_count=0"
set "last_match="

for /d %%C in ("!SCRIPT_DIR!\_lib\*" "!SCRIPT_DIR!\topologies\*" "!SCRIPT_DIR!\payloads\*") do (
    if exist "%%C\cli.cmd" (
        set "cname=%%~nxC"
        if "!cname!"=="!action_pkg!" (
            set "target=%%C"
            goto run_target
        )
        echo "!cname!" | findstr /i "!action_pkg!" >nul 2>&1
        if not errorlevel 1 (
            set /a match_count+=1
            set "last_match=%%C"
        )
    )
    for /d %%D in ("%%C\*") do (
        if exist "%%D\cli.cmd" (
            set "cname=%%~nxD"
            if "!cname!"=="!action_pkg!" (
                set "target=%%D"
                goto run_target
            )
            echo "!cname!" | findstr /i "!action_pkg!" >nul 2>&1
            if not errorlevel 1 (
                set /a match_count+=1
                set "last_match=%%D"
            )
        )
    )
)

if !match_count! equ 1 (
    set "target=!last_match!"
    goto run_target
)

if !match_count! equ 0 (
    echo Error: Unknown component '!action_pkg!'. >&2
    exit /b 1
)

echo Error: Component '!action_pkg!' is ambiguous. Matches: >&2
for /d %%C in ("!SCRIPT_DIR!\_lib\*") do (
    for /d %%D in ("%%C\*") do (
        if exist "%%D\cli.cmd" (
            set "cname=%%~nxD"
            echo "!cname!" | findstr /i "!action_pkg!" >nul 2>&1
            if not errorlevel 1 (
                echo   %%~nxC\!cname! >&2
            )
        )
    )
)
exit /b 1

:: ## run_target
:: Performs the run_target operation and updates component state.
:run_target
if exist "!target!\cli.cmd" (
    if "%is_action%"=="0" (
        if not "%action_pkg%"=="cloud" (
            call "!target!\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
            exit /b !errorlevel!
        )
    )
    call "!target!\cli.cmd" %*
    exit /b !errorlevel!
) else (
    echo Error: Local CLI not found in "!target!" >&2
    exit /b 1
)

:: ## show_help
:: Displays command-line usage instructions and available options.
:show_help
echo LibScript Global CLI
echo ====================
echo.
echo Usage: %~nx0 [COMMAND] [PACKAGE_NAME] [VERSION]
echo.
echo Commands:
echo   list                                      List all available components
echo   search ^<query^>                            Search available components by name or description
echo   install-deps [file]                       Install all dependencies defined in a JSON file (default: libscript.json)
echo   package-as ^<format^> [args...]             Package libscript usage (e.g., docker, docker_compose)
echo   install ^<package_name^> ^<version^>
echo   use ^<package_name^> ^<version^>
echo   download ^<package_name^> ^<version^>
echo   provision ^<provider^> ...                  Provision a cloud environment
echo   deprovision ^<provider^> ...                Deprovision a cloud environment
echo   deploy-remote ^<user@host^>                 Idempotently deploy multiple apps to a remote host
echo   remove ^<package_name^> [version]
echo   uninstall ^<package_name^> [version]
echo   install-service ^<package_name^> ^<version^>
echo   run ^<package_name^> ^<version^> [args...]
echo   which ^<package_name^> ^<version^>
echo   exec ^<package_name^> ^<version^> ^<cmd^> [args...]
echo   env ^<package_name^> ^<version^>
echo   ls ^<package_name^>
echo   ls-remote ^<package_name^> [version]
echo   uninstall-service ^<package_name^> ^<version^>
echo   status ^<package_name^> [version]
echo   test ^<package_name^> [version]
echo.
echo Options:
echo   --help, -h, /?, -?          Show this help text
echo   --version, -v               Show version
echo   --offline, -o               Enable offline execution mode (prohibits remote network requests)
echo   --force-offline             Strictly abort execution if network calls are attempted
echo   --online                    Explicitly enable online execution mode
echo   --cache-dir=^<dir^>           Set local artifact cache directory (LIBSCRIPT_CACHE_DIR)
echo   --download-dir=^<dir^>        Set temporary download staging directory (DOWNLOAD_DIR)
echo   --prefix=^<dir^>              Set local installation prefix
echo   --log-format=^<text^|json^>      Set log output format
echo   --log-level=^<0-4^>             Set minimum log level (0=DEBUG, 1=INFO, etc)
echo   --log-file=^<path^>             Set a file to mirror all logs to
echo   --secrets=^<dir^|url^>         Save generated secrets to a directory or OpenBao/Vault URL
echo.
exit /b 0
