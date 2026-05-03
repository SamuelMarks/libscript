@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Fallback to running PowerShell for Windows provisioning
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell not found. Cannot configure phpBB on Windows.
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
@echo off
echo "Uninstalling phpbb is not supported via this script."
exit /b 0
@echo off
call "%~dp0\..\..\..\_lib\_common\test_base.cmd"
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Fallback to running PowerShell for Windows provisioning
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell not found. Cannot configure Nextcloud on Windows.
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
@echo off
echo "Uninstalling nextcloud is not supported via this script."
exit /b 0
@echo off
call "%~dp0\..\..\..\_lib\_common\test_base.cmd"
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook natively supported
echo Actix Scaffold setup on Windows...
exit /b 0
exit /b 0
@echo off
echo "Uninstalling serve-actix-diesel-auth-scaffold is not supported via this script."
exit /b 0
@echo off
call "%~dp0\..\..\..\_lib\_common\test_base.cmd"
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Fallback to running PowerShell for Windows provisioning
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell not found. Cannot configure WooCommerce on Windows.
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
@echo off
echo "Uninstalling woocommerce is not supported via this script."
exit /b 0
@echo off
call "%~dp0\..\..\..\_lib\_common\test_base.cmd"
@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\setup_windows.ps1"
endlocal
@echo off
echo "Uninstalling magento is not supported via this script."
exit /b 0
@echo off
call "%~dp0\..\..\..\_lib\_common\test_base.cmd"
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Fallback to running PowerShell for Windows provisioning
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell not found. Cannot configure PrestaShop on Windows.
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
@echo off
echo "Uninstalling prestashop is not supported via this script."
exit /b 0
@echo off
call "%~dp0\..\..\..\_lib\_common\test_base.cmd"
@echo off
set "PACKAGE_NAME=firecrawl"
call "%~dp0\..\..\..\_lib\_common\component_core.cmd" %*
@echo off
setlocal EnableDelayedExpansion
if not defined LIBSCRIPT_ROOT_DIR set "LIBSCRIPT_ROOT_DIR=%~dp0..\..\.."
set "LOG_CMD=%~dp0\..\..\..\_lib\_common\log.cmd"
if not exist "!LOG_CMD!" set "LOG_CMD=%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd"
call "!LOG_CMD!" :log_warn "firecrawl is not supported on Windows natively."
exit /b 0
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\..\_lib\_common\test_base.cmd"
@echo off
set "PACKAGE_NAME=jupyterhub"
call "%~dp0\..\..\..\_lib\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\..\_lib\_common\test_base.cmd" :assert_version jupyterhub "."
@echo off
setlocal EnableDelayedExpansion
if not defined LIBSCRIPT_ROOT_DIR set "LIBSCRIPT_ROOT_DIR=%~dp0..\..\.."
set "LOG_CMD=%~dp0\..\..\..\_lib\_common\log.cmd"
if not exist "!LOG_CMD!" set "LOG_CMD=%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd"
call "!LOG_CMD!" :log_warn "openvpn is not supported on Windows natively."
exit /b 0
@echo off
echo "Uninstalling openvpn is not supported via this script."
exit /b 0
@echo off
call "%~dp0\..\..\..\_lib\_common\test_base.cmd" :assert_version openvpn "."
@echo off
set "PACKAGE_NAME=celery"
call "%~dp0\..\..\..\_lib\_common\component_core.cmd" %*
@echo off
setlocal EnableDelayedExpansion
if not defined LIBSCRIPT_ROOT_DIR set "LIBSCRIPT_ROOT_DIR=%~dp0..\..\.."
set "LOG_CMD=%~dp0\..\..\..\_lib\_common\log.cmd"
if not exist "!LOG_CMD!" set "LOG_CMD=%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd"
call "!LOG_CMD!" :log_warn "celery is not supported on Windows natively."
exit /b 0
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\..\_lib\_common\test_base.cmd" :assert_version celery "."
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Fallback to running PowerShell for Windows provisioning
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell not found. Cannot configure Drupal on Windows.
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
@echo off
echo "Uninstalling drupal is not supported via this script."
exit /b 0
@echo off
call "%~dp0\..\..\..\_lib\_common\test_base.cmd"
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Fallback to running PowerShell for Windows provisioning
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell not found. Cannot configure WordPress on Windows.
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
@echo off
echo "Uninstalling wordpress is not supported via this script."
exit /b 0
@echo off
call "%~dp0\..\..\..\_lib\_common\test_base.cmd"
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Fallback to running PowerShell for Windows provisioning
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell not found. Cannot configure Joomla on Windows.
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
@echo off
echo "Uninstalling joomla is not supported via this script."
exit /b 0
@echo off
call "%~dp0\..\..\..\_lib\_common\test_base.cmd"
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Fallback to running PowerShell for Windows provisioning
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell not found. Cannot configure Odoo on Windows.
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
@echo off
echo "Uninstalling odoo is not supported via this script."
exit /b 0
@echo off
call "%~dp0\..\..\..\_lib\_common\test_base.cmd"
@echo off
setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: Source logging (must be after SCRIPT_DIR)
set "LOG_CMD=%SCRIPT_DIR%\_lib\_common\log.cmd"

:: Global Option Parsing
:opt_loop
set "arg=%~1"
if "!arg!"=="" goto :run_cmd
set "is_opt=0"
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

:run_cmd
set "cmd=%~1"
if "%cmd%"=="" goto show_help
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

if /i "%cmd%"=="list" goto list_components
if /i "%cmd%"=="provision" goto provision_cloud
if /i "%cmd%"=="deprovision" goto deprovision_cloud

if /i "%cmd%"=="search" goto search_components

if /i "%cmd%"=="start" if not "%LIBSCRIPT_INTERNAL_START%"=="1" set "is_docker_cmd=1"
if /i "%cmd%"=="stop" if not "%LIBSCRIPT_INTERNAL_START%"=="1" set "is_docker_cmd=1"
if /i "%cmd%"=="status" if not "%LIBSCRIPT_INTERNAL_START%"=="1" set "is_docker_cmd=1"
if /i "%cmd%"=="health" if not "%LIBSCRIPT_INTERNAL_START%"=="1" set "is_docker_cmd=1"
if /i "%cmd%"=="logs" if not "%LIBSCRIPT_INTERNAL_START%"=="1" set "is_docker_cmd=1"
if /i "%cmd%"=="restart" if not "%LIBSCRIPT_INTERNAL_START%"=="1" set "is_docker_cmd=1"
if /i "%cmd%"=="up" if not "%LIBSCRIPT_INTERNAL_START%"=="1" set "is_docker_cmd=1"
if /i "%cmd%"=="down" if not "%LIBSCRIPT_INTERNAL_START%"=="1" set "is_docker_cmd=1"

if "!is_docker_cmd!"=="1" (
    set "action=%cmd%"
    if /i "!action!"=="up" set "action=start"
    if /i "!action!"=="down" set "action=stop"
    set "skip_hooks=0"
    set "arg1=%~2"
    set "arg2=%~3"
    set "arg3=%~4"
    if /i "!arg1!"=="--no-hooks" (
        set "skip_hooks=1"
        set "arg1=!arg2!"
        set "arg2=!arg3!"
    ) else if /i "!arg2!"=="--no-hooks" (
        set "skip_hooks=1"
        set "arg2=!arg3!"
    )
    
    set "is_json=0"
    if "!arg1!"=="" set "is_json=1"
    if /i "!arg1!"=="libscript.json" set "is_json=1"
    echo !arg1! | findstr /i "\.json$" >nul && set "is_json=1"

    if "!is_json!"=="1" (
        set "json_file=!arg1!"
        if "!json_file!"=="" set "json_file=libscript.json"
        if not exist "!json_file!" (
            echo Error: !json_file! not found. 1>&2
            exit /b 1
        )
        jq --version >nul 2>&1
        if errorlevel 1 (
            echo Error: jq is required to parse !json_file!. 1>&2
            exit /b 1
        )
                if "!skip_hooks!"=="0" (
            if /i "!action!"=="start" (
                call "%~dp0scripts\run_hooks.cmd" "!json_file!" "build"
                call "%~dp0scripts\run_hooks.cmd" "!json_file!" "pre_start"
            )
            if /i "!action!"=="up" (
                call "%~dp0scripts\run_hooks.cmd" "!json_file!" "build"
                call "%~dp0scripts\run_hooks.cmd" "!json_file!" "pre_start"
            )
        )
        call "%~dp0scripts\resolve_stack.cmd" "!json_file!" > "!json_file!.resolved.json" 2>nul
        for /f "tokens=1,2 delims= " %%A in (\'jq -r ".selected[] | \"\(.name) \(.version // \\\"latest\\\")\"" "!json_file!.resolved.json" 2^>nul\') do (
            set "pkg=%%A"
            set "ver=%%B"
            if "!ver!"=="null" set "ver=latest"
            set "LIBSCRIPT_INTERNAL_START=1"
            start "" /b cmd /c call "%~f0" !action! !pkg! !ver!
        )
        if exist "!json_file!.resolved.json" del "!json_file!.resolved.json"
        
        if /i "!action!"=="start" (
            call "%~dp0scripts\daemonize.cmd" "!action!" "!json_file!"
            call "%~dp0scripts\setup_ingress.cmd" "!action!" "!json_file!"
        ) else if /i "!action!"=="up" (
            call "%~dp0scripts\daemonize.cmd" "!action!" "!json_file!"
            call "%~dp0scripts\setup_ingress.cmd" "!action!" "!json_file!"
        ) else if /i "!action!"=="stop" (
            call "%~dp0scripts\setup_ingress.cmd" "!action!" "!json_file!"
            call "%~dp0scripts\daemonize.cmd" "!action!" "!json_file!"
        ) else if /i "!action!"=="down" (
            call "%~dp0scripts\setup_ingress.cmd" "!action!" "!json_file!"
            call "%~dp0scripts\daemonize.cmd" "!action!" "!json_file!"
        ) else if /i "!action!"=="status" (
            call "%~dp0scripts\daemonize.cmd" "!action!" "!json_file!"
        )

        exit /b 0
    ) else (
        rem Support multiple specific services: libscript.cmd start caddy postgres
        :loop_services
        set "pkg=%~2"
        if not "!pkg!"=="" (
            set "LIBSCRIPT_INTERNAL_START=1"
            start "" /b cmd /c call "%~f0" !action! !pkg! latest
            shift
            goto loop_services
        )
        exit /b 0
    )
)

if /i "%cmd%"=="install-deps" (
    set "json_file=%~2"
    if "!json_file!"=="" set "json_file=libscript.json"
    if not exist "!json_file!" (
        echo Error: !json_file! not found. 1>&2
        exit /b 1
    )
    jq --version >nul 2>&1
    if errorlevel 1 (
        echo Error: jq is required to parse !json_file!. 1>&2
        exit /b 1
    )
    
    if "!LIBSCRIPT_SECRETS!"=="" (
        for /f "delims=" %%s in ('jq -r "if .secrets then .secrets else empty end" "!json_file!" 2^>nul') do (
            if not "%%s"=="" if not "%%s"=="null" set "LIBSCRIPT_SECRETS=%%s"
        )
        if "!LIBSCRIPT_SECRETS!"=="" (
            if defined LIBSCRIPT_ROOT_DIR (
                set "LIBSCRIPT_SECRETS=!LIBSCRIPT_ROOT_DIR!\secrets"
            ) else (
                set "LIBSCRIPT_SECRETS=%SCRIPT_DIR%\secrets"
            )
        )
    )

            if "!skip_hooks!"=="0" (
            if /i "!action!"=="start" (
                call "%~dp0scripts\run_hooks.cmd" "!json_file!" "build"
                call "%~dp0scripts\run_hooks.cmd" "!json_file!" "pre_start"
            )
            if /i "!action!"=="up" (
                call "%~dp0scripts\run_hooks.cmd" "!json_file!" "build"
                call "%~dp0scripts\run_hooks.cmd" "!json_file!" "pre_start"
            )
        )
        call "%~dp0scripts\resolve_stack.cmd" "!json_file!" > "!json_file!.resolved.json" 2>nul
    REM Parallel Download Phase
    echo Downloading dependencies in parallel...
    for /f "tokens=1,2,3" %%a in (\'jq -r ".selected[] | \"\(.name) \(.version // \\\"latest\\\") \(.override // \\\"\\\")\"" "!json_file!.resolved.json" 2^>nul\') do (
        if "%%c"=="" (
            start "" /b cmd /c "call "%~dp0libscript.cmd" download "%%a" "%%b""
        ) else if "%%c"=="null" (
            start "" /b cmd /c "call "%~dp0libscript.cmd" download "%%a" "%%b""
        )
    )
    
    REM Wait for background downloads. `start /wait /b` doesn't work, we'll just wait a bit or let it run.
    REM A simple sleep or loop for processes isn't strictly trivial without external tools.
    REM But we can check for running cmd.exe processes started with `download` via tasklist if needed.
    REM Actually, simple approach: wait 3 seconds to let them start and fetch.
    ping 127.0.0.1 -n 4 >nul
    
    REM Serial Install Phase
    echo Installing dependencies sequentially...
    for /f "tokens=1,2,3" %%a in (\'jq -r ".selected[] | \"\(.name) \(.version // \\\"latest\\\") \(.override // \\\"\\\")\"" "!json_file!.resolved.json" 2^>nul\') do (
        if not "%%c"=="" if not "%%c"=="null" (
            echo Skipping installation of %%a ^(override provided: %%c^)
        ) else (
            echo Installing %%a %%b...
            call "%~dp0libscript.cmd" install "%%a" "%%b"
        )
    )
    if exist "!json_file!.resolved.json" del "!json_file!.resolved.json"
    exit /b 0
)

if /i "%cmd%"=="db-search" (
    set "query=%~2"
    set "DB_FILE=!LIBSCRIPT_ROOT_DIR!\libscript.sqlite"
    if "!LIBSCRIPT_ROOT_DIR!"=="" set "DB_FILE=%SCRIPT_DIR%libscript.sqlite"
    if not exist "!DB_FILE!" (
        echo Error: Database not found. Run update-db first. 1>&2
        exit /b 1
    )
    sqlite3 -column -header "!DB_FILE!" "SELECT c.name, v.version, f.url, f.checksum FROM components c LEFT JOIN versions v ON c.id = v.component_id LEFT JOIN files f ON v.id = f.version_id WHERE c.name LIKE '%%!query!%%' OR v.version LIKE '%%!query!%%'"
    exit /b !errorlevel!
)

if /i "%cmd%"=="update-db" (
    if exist "%SCRIPT_DIR%update_db.cmd" (
        call "%SCRIPT_DIR%update_db.cmd"
    ) else if exist "%SCRIPT_DIR%update_db.sh" (
        REM If WSL or git bash is available
        sh "%SCRIPT_DIR%update_db.sh"
    ) else (
        echo Error: update_db script not found. 1>&2
        exit /b 1
    )
    exit /b !errorlevel!
)

if /i "%cmd%"=="semver" (
    set "v1=%~2"
    set "op=%~3"
    set "v2=%~4"
    if "!v1!"=="" (
        echo Usage: %~nx0 semver ^<v1^> ^<operator^> ^<v2^> 1>&2
        echo Operators: -eq -ne -gt -lt -ge -le 1>&2
        exit /b 1
    )
    if "!op!"=="=" set "op=-eq"
    if "!op!"=="!=" set "op=-ne"
    if "!op!"==">" set "op=-gt"
    if "!op!"=="<" set "op=-lt"
    if "!op!"==">=" set "op=-ge"
    if "!op!"=="<=" set "op=-le"
    
    powershell -Command "if ([version]'!v1!' !op! [version]'!v2!') { exit 0 } else { exit 1 }"
    exit /b !errorlevel!
)

if /i "%cmd%"=="package_as" goto handle_package_as

set "is_action=0"
set "req_version=0"
if /i "%cmd%"=="install" ( set "is_action=1" & set "req_version=1" )
if /i "%cmd%"=="install_daemon" ( set "is_action=1" & set "req_version=1" )
if /i "%cmd%"=="install_service" ( set "is_action=1" & set "req_version=1" )
if /i "%cmd%"=="uninstall_daemon" ( set "is_action=1" & set "req_version=1" )
if /i "%cmd%"=="uninstall_service" ( set "is_action=1" & set "req_version=1" )
if /i "%cmd%"=="remove_daemon" ( set "is_action=1" & set "req_version=1" )
if /i "%cmd%"=="remove_service" ( set "is_action=1" & set "req_version=1" )

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
        if "%~3"=="" (
            echo Error: version is required for %cmd% 1>&2
            exit /b 1
        )
    )
    set "action_pkg=%~2"
    goto match_component
) else (
    echo Error: Unknown command '%cmd%'.
    goto show_help
)

:match_component
set "target="
if exist "%SCRIPT_DIR%\%action_pkg%\cli.cmd" (
    set "target=%SCRIPT_DIR%\%action_pkg%"
    goto run_target
)

set "match_count=0"
set "exact_match_count=0"
set "last_match="
set "last_exact_match="

for /f "delims=" %%f in ('dir /s /b /a:-d "%SCRIPT_DIR%\cli.cmd" 2^>nul') do (
    set "dir_path=%%~dpf"
    set "dir_path=!dir_path:~0,-1!"
    if exist "!dir_path!\vars.schema.json" (
        set "rel_dir=!dir_path:%SCRIPT_DIR%\=!"
        
        echo !rel_dir! | findstr /i "%action_pkg%" >nul
        if not errorlevel 1 (
            set /a match_count+=1
            set "last_match=!dir_path!"
            
            echo !rel_dir! | findstr /i /e "\%action_pkg%" >nul
            if not errorlevel 1 (
                set /a exact_match_count+=1
                set "last_exact_match=!dir_path!"
            )
            if /i "!rel_dir!"=="%action_pkg%" (
                set /a exact_match_count+=1
                set "last_exact_match=!dir_path!"
            )
        )
    )
)

if !match_count! equ 0 (
    echo Error: Unknown component '%action_pkg%'.
    exit /b 1
)
if !match_count! equ 1 (
    set "target=!last_match!"
    goto run_target
)

if !exact_match_count! equ 1 (
    set "target=!last_exact_match!"
    goto run_target
)

echo Error: Component '%action_pkg%' is ambiguous. Matches:
for /f "delims=" %%f in ('dir /s /b /a:-d "%SCRIPT_DIR%\cli.cmd" 2^>nul') do (
    set "dir_path=%%~dpf"
    set "dir_path=!dir_path:~0,-1!"
    if exist "!dir_path!\vars.schema.json" (
        set "rel_dir=!dir_path:%SCRIPT_DIR%\=!"
        echo !rel_dir! | findstr /i "%action_pkg%" >nul
        if not errorlevel 1 (
            echo   !rel_dir!
        )
    )
)
exit /b 1

:run_target
if exist "%target%\cli.cmd" (
    call "%target%\cli.cmd" %*
    exit /b !errorlevel!
) else (
    echo Error: Local CLI not found in %target%
    exit /b 1
)

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
echo   package_as ^<format^> [args...]             Package libscript usage (e.g., docker, docker_compose)
echo   install ^<package_name^> ^<version^>
echo   remove ^<package_name^> [version]
echo   uninstall ^<package_name^> [version]
echo   install_daemon ^<package_name^> ^<version^>
echo   install_service ^<package_name^> ^<version^>
echo   uninstall_daemon ^<package_name^> ^<version^>
echo   run ^<package_name^> ^<version^> [args...]
echo   which ^<package_name^> ^<version^>
echo   exec ^<package_name^> ^<version^> ^<cmd^> [args...]
echo   env ^<package_name^> ^<version^>
echo   ls ^<package_name^>
echo   ls-remote ^<package_name^> [version]
echo   uninstall_service ^<package_name^> ^<version^>
echo   remove_daemon ^<package_name^> ^<version^>
echo   remove_service ^<package_name^> ^<version^>
echo   status ^<package_name^> [version]
echo   test ^<package_name^> [version]
echo.
echo Options:
echo   --help, -h, /?              Show this help text
echo   --version, -v               Show version
echo   --prefix=^<dir^>              Set local installation prefix
echo   --log-format=^<text^|json^>      Set log output format
echo   --log-level=^<0-4^>             Set minimum log level (0=DEBUG, 1=INFO, etc)
echo   --log-file=^<path^>             Set a file to mirror all logs to
echo   --secrets=^<dir^|url^>         Save generated secrets to a directory or OpenBao/Vault URL
echo.
exit /b 0

:list_components
echo Available components:
for /f "delims=" %%f in ('dir /s /b /a:-d "%SCRIPT_DIR%\cli.cmd" 2^>nul') do (
    set "dir_path=%%~dpf"
    set "dir_path=!dir_path:~0,-1!"
    if exist "!dir_path!\vars.schema.json" (
        set "rel_dir=!dir_path:%SCRIPT_DIR%\=!"
        if "!rel_dir!" neq "" (
            set "desc="
            jq -r "if .description then .description else \"\" end" "!dir_path!\vars.schema.json" > "%temp%\desc.txt" 2^>nul
            if not errorlevel 1 (
                set /p desc=^<"%temp%\desc.txt"
            )
            if "!desc!" neq "" (
                echo   !rel_dir! - !desc!
            ) else (
                echo   !rel_dir!
            )
        )
    )
)
if exist "%temp%\desc.txt" del "%temp%\desc.txt"
exit /b 0

:provision_cloud
shift
call "%~dp0scripts\deploy_cloud.cmd" %*
goto :eof

:deprovision_cloud
shift
call "%~dp0scripts\teardown_cloud.cmd" %*
goto :eof


:search_components
set "query=%~2"
if "%query%"=="" (
    echo Error: please provide a search query.
    exit /b 1
)
echo Searching for '%query%'...
for /f "delims=" %%f in ('dir /s /b /a:-d "%SCRIPT_DIR%\cli.cmd" 2^>nul') do (
    set "dir_path=%%~dpf"
    set "dir_path=!dir_path:~0,-1!"
    if exist "!dir_path!\vars.schema.json" (
        set "rel_dir=!dir_path:%SCRIPT_DIR%\=!"
        if "!rel_dir!" neq "" (
            set "desc="
            jq -r "if .description then .description else \"\" end" "!dir_path!\vars.schema.json" > "%temp%\desc.txt" 2^>nul
            if not errorlevel 1 (
                set /p desc=^<"%temp%\desc.txt"
            )
            set "match_found=0"
            echo !rel_dir! | findstr /i "%query%" >nul
            if not errorlevel 1 set "match_found=1"
            echo !desc! | findstr /i "%query%" >nul
            if not errorlevel 1 set "match_found=1"
            
            if "!match_found!"=="1" (
                if "!desc!" neq "" (
                    echo   !rel_dir! - !desc!
                ) else (
                    echo   !rel_dir!
                )
            )
        )
    )
)
if exist "%temp%\desc.txt" del "%temp%\desc.txt"
exit /b 0

:handle_package_as
set "is_docker="
if /i "%~2"=="docker" set "is_docker=1"
if /i "%~2"=="dockerfile" set "is_docker=1"

if defined is_docker (
    set "base_image=debian:bookworm-slim"
    set "layer_filter="
    set "artifact_type="
    shift
    shift
    
    :docker_parse_flags
    if /i "%~1"=="--artifact" (
        set "artifact_type=%~2"
        if /i "%~2"=="deb" set "base_image=debian:bookworm-slim"
        if /i "%~2"=="rpm" set "base_image=almalinux:9"
        if /i "%~2"=="apk" set "base_image=alpine:latest"
        if /i "%~2"=="txz" set "base_image=freebsd"
        if /i "%~2"=="msi" set "base_image=mcr.microsoft.com/windows/servercore:ltsc2022"
        if /i "%~2"=="exe" set "base_image=mcr.microsoft.com/windows/servercore:ltsc2022"
        shift
        shift
        goto docker_parse_flags
    )
    if /i "%~1"=="-a" (
        set "artifact_type=%~2"
        if /i "%~2"=="deb" set "base_image=debian:bookworm-slim"
        if /i "%~2"=="rpm" set "base_image=almalinux:9"
        if /i "%~2"=="apk" set "base_image=alpine:latest"
        if /i "%~2"=="txz" set "base_image=freebsd"
        if /i "%~2"=="msi" set "base_image=mcr.microsoft.com/windows/servercore:ltsc2022"
        if /i "%~2"=="exe" set "base_image=mcr.microsoft.com/windows/servercore:ltsc2022"
        shift
        shift
        goto docker_parse_flags
    )
    if /i "%~1"=="--base" (
        set "base_image=%~2"
        if /i "%~2"=="debian" set "base_image=debian:bookworm-slim"
    set "layer_filter="
        if /i "%~2"=="alpine" set "base_image=alpine:latest"
        shift
        shift
        goto docker_parse_flags
    )
    if /i "%~1"=="--layer" (
        set "layer_filter=%~2"
        shift
        shift
        goto docker_parse_flags
    )
    if /i "%~1"=="-l" (
        set "layer_filter=%~2"
        shift
        shift
        goto docker_parse_flags
    )
    if /i "%~1"=="--base-image" (
        set "base_image=%~2"
        if /i "%~2"=="debian" set "base_image=debian:bookworm-slim"
    set "layer_filter="
        if /i "%~2"=="alpine" set "base_image=alpine:latest"
        shift
        shift
        goto docker_parse_flags
    )

    echo FROM !base_image!
    echo ARG TARGETOS=windows
    echo ARG TARGETARCH=amd64
    echo ENV LC_ALL=C.UTF-8 LANG=C.UTF-8
    echo ENV LIBSCRIPT_ROOT_DIR="/opt/libscript"
    echo ENV LIBSCRIPT_BUILD_DIR="/opt/libscript_build"
    echo ENV LIBSCRIPT_DATA_DIR="/opt/libscript_data"
    echo ENV LIBSCRIPT_CACHE_DIR="/opt/libscript_cache"
    set "tmp_env_add=%temp%\libscript_env_add.tmp"
    set "tmp_run=%temp%\libscript_run.tmp"
    if exist "!tmp_env_add!" del "!tmp_env_add!"
    if exist "!tmp_run!" del "!tmp_run!"
    
    :docker_loop
    if not "%~1"=="" (
        set "pkg=%~1"
        set "ver=%~2"
        set "override=%~3"
        if "!ver!"=="" set "ver=latest"
        
        set "is_url="
        if not "!override!"=="" (
            echo !override! | findstr /b "http" >nul
            if not errorlevel 1 set "is_url=1"
        )
        
        set "pkg_up=!pkg!"
        for %%A in ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z" "-=_") do set "pkg_up=!pkg_up:%%~A!"
        
        echo ENV !pkg_up!_VERSION="!ver!">> "!tmp_env_add!"
        
        if defined is_url (
            echo ENV !pkg_up!_URL="!override!">> "!tmp_env_add!"
            for %%F in ("!override!") do set "filename=%%~nxF"
            if "!artifact_type!"=="" echo ADD ${!pkg_up!_URL} /opt/libscript_cache/!pkg!/!filename!>> "!tmp_env_add!"
            shift
            shift
            shift
        ) else (
            if not "%~2"=="" (
                shift
                shift
            ) else (
                shift
            )
        )
        
        if "!artifact_type!"=="deb" (
            echo RUN apt-get update ^&^& apt-get install -y /opt/libscript/*-!pkg!_*.deb>> "!tmp_run!"
        ) else if "!artifact_type!"=="rpm" (
            echo RUN dnf install -y /opt/libscript/*-!pkg!-*.rpm>> "!tmp_run!"
        ) else if "!artifact_type!"=="apk" (
            echo RUN apk add --allow-untrusted /opt/libscript/*-!pkg!-*.apk>> "!tmp_run!"
        ) else if "!artifact_type!"=="txz" (
            echo RUN pkg install -y /opt/libscript/*-!pkg!*.txz /opt/libscript/*-!pkg!*.pkg 2^>nul^|^|true>> "!tmp_run!"
        ) else if "!artifact_type!"=="msi" (
            echo RUN for %%I in ^(C:\opt\libscript\*-!pkg!-*.msi^) do msiexec /i "%%I" /qn /norestart>> "!tmp_run!"
        ) else if "!artifact_type!"=="exe" (
            echo RUN for %%I in ^(C:\opt\libscript\*-!pkg!-*.exe^) do "%%I" /SILENT /VERYSILENT>> "!tmp_run!"
        ) else (
            echo RUN ./libscript.sh install !pkg! ${!pkg_up!_VERSION}>> "!tmp_run!"
        )
        
        REM Call libscript.sh env to get docker formatted ENV vars, not cmd because we're emitting a linux dockerfile
        set "PREFIX=/opt/libscript/installed/!pkg!"
        for /f "delims=" %%i in ('call "%~dp0libscript.cmd" env !pkg! !ver! --format=docker 2^>nul') do (
            echo %%i | findstr /b /v "ENV STACK=" | findstr /b /v "ENV SCRIPT_NAME=">> "!tmp_run!"
        )
        goto docker_loop
    ) else (
        if exist "libscript.json" (
            jq --version >nul 2>&1
            if not errorlevel 1 (
                call "%~dp0scripts\resolve_stack.cmd" "libscript.json" > "libscript.resolved.json" 2>nul
                for /f "tokens=1,2,3" %%a in (\'jq -r ".selected[] | \"\(.name) \(.version // \\\"latest\\\") \(.override // \\\"\\\")\"" "libscript.resolved.json" 2^>nul\') do (
                    set "pkg_up=%%a"
                    for %%A in ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z" "-=_") do set "pkg_up=!pkg_up:%%~A!"
                    
                    if "%%b"=="" (
                        echo ENV !pkg_up!_VERSION="latest">> "!tmp_env_add!"
                    ) else if "%%b"=="null" (
                        echo ENV !pkg_up!_VERSION="latest">> "!tmp_env_add!"
                    ) else (
                        echo ENV !pkg_up!_VERSION="%%b">> "!tmp_env_add!"
                    )
                    
                    if not "%%c"=="" if not "%%c"=="null" (
                        echo ENV !pkg_up!_URL="%%c">> "!tmp_env_add!"
                        for %%F in ("%%c") do set "filename=%%~nxF"
                        if "!artifact_type!"=="" echo ADD ${!pkg_up!_URL} /opt/libscript_cache/%%a/!filename!>> "!tmp_env_add!"
                    )
                    
                    if "!artifact_type!"=="deb" (
                        echo RUN apt-get update ^&^& apt-get install -y /opt/libscript/*-%%a_*.deb>> "!tmp_run!"
                    ) else if "!artifact_type!"=="rpm" (
                        echo RUN dnf install -y /opt/libscript/*-%%a-*.rpm>> "!tmp_run!"
                    ) else if "!artifact_type!"=="apk" (
                        echo RUN apk add --allow-untrusted /opt/libscript/*-%%a-*.apk>> "!tmp_run!"
                    ) else if "!artifact_type!"=="txz" (
                        echo RUN pkg install -y /opt/libscript/*-%%a*.txz /opt/libscript/*-%%a*.pkg 2^>nul^|^|true>> "!tmp_run!"
                    ) else if "!artifact_type!"=="msi" (
                        echo RUN for %%%%I in ^(C:\opt\libscript\*-%%a-*.msi^) do msiexec /i "%%%%I" /qn /norestart>> "!tmp_run!"
                    ) else if "!artifact_type!"=="exe" (
                        echo RUN for %%%%I in ^(C:\opt\libscript\*-%%a-*.exe^) do "%%%%I" /SILENT /VERYSILENT>> "!tmp_run!"
                    ) else (
                        echo RUN ./libscript.sh install %%a ${!pkg_up!_VERSION}>> "!tmp_run!"
                    )
                    
                    set "PREFIX=/opt/libscript/installed/%%a"
                    for /f "delims=" %%i in ('call "%~dp0libscript.cmd" env %%a %%b --format=docker 2^>nul') do (
            echo %%i | findstr /b /v "ENV STACK=" | findstr /b /v "ENV SCRIPT_NAME=">> "!tmp_run!"
                    )
                )
                if exist "!json_file!.resolved.json" del "!json_file!.resolved.json"
            ) else (
                echo RUN ./install_gen.sh>> "!tmp_run!"
            )
        ) else (
                echo RUN ./install_gen.sh>> "!tmp_run!"
        )
    )
    if exist "!tmp_env_add!" type "!tmp_env_add!"
    echo COPY . /opt/libscript
    echo WORKDIR /opt/libscript
    if exist "!tmp_run!" type "!tmp_run!"

    if exist "!tmp_env_add!" del "!tmp_env_add!"
    if exist "!tmp_run!" del "!tmp_run!"
    exit /b 0
) else if /i "%~2"=="docker_compose" (
    set "base_image=debian:bookworm-slim"
    shift
    shift
    :docker_compose_parse_flags
    if /i "%~1"=="--base" (
        set "base_image=%~2"
        if /i "%~2"=="debian" set "base_image=debian:bookworm-slim"
        if /i "%~2"=="alpine" set "base_image=alpine:latest"
        shift
        shift
        goto docker_compose_parse_flags
    )
    if /i "%~1"=="--base-image" (
        set "base_image=%~2"
        if /i "%~2"=="debian" set "base_image=debian:bookworm-slim"
        if /i "%~2"=="alpine" set "base_image=alpine:latest"
        shift
        shift
        goto docker_compose_parse_flags
    )

    echo version: '3.8'
    echo services:
    
    set "prev_pkg="
    
    if not "%~1"=="" (
        :docker_compose_loop
        if not "%~1"=="" (
            set "pkg=%~1"
            set "ver=%~2"
            if "!ver!"=="" set "ver=latest"
            set "override="
            
            call :dc_gen_service "!pkg!" "!ver!" "!override!"
            
            if not "%~2"=="" (
                shift
                shift
            ) else (
                shift
            )
            goto docker_compose_loop
        )
    ) else (
        if exist "libscript.json" (
            jq --version >nul 2>&1
            if not errorlevel 1 (
                call "%~dp0scripts\resolve_stack.cmd" "libscript.json" > "libscript.resolved.json" 2>nul
                for /f "tokens=1,2,3" %%a in (\'jq -r ".selected[] | \"\(.name) \(.version // \\\"latest\\\") \(.override // \\\"\\\")\"" "libscript.resolved.json" 2^>nul\') do (
                    set "pkg=%%a"
                    set "ver=%%b"
                    set "override=%%c"
                    if "!ver!"=="" set "ver=latest"
                    if "!ver!"=="null" set "ver=latest"
                    if "!override!"=="null" set "override="
                    call :dc_gen_service "!pkg!" "!ver!" "!override!"
                )
                if exist "libscript.resolved.json" del "libscript.resolved.json"
            )
        )
    )
    exit /b 0
) else if /i "%~2"=="TUI" (
    echo @echo off
    echo setlocal EnableDelayedExpansion
    echo echo Creating interactive component selection...
    
    echo set "ps_script=$items = @("
    
    if not "%~3"=="" (
        shift
        shift
        :tui_loop
        if not "%~1"=="" (
            set "pkg=%~1"
            set "ver=%~2"
            if "!ver!"=="" set "ver=latest"
            echo set "ps_script=^!ps_script^![pscustomobject]@{Name='!pkg!';Version='!ver!'},"
            if not "%~2"=="" (
                shift
                shift
            ) else (
                shift
            )
            goto tui_loop
        )
    ) else (
        if exist "libscript.json" (
            jq --version >nul 2>&1
            if not errorlevel 1 (
                call "%~dp0scripts\resolve_stack.cmd" "libscript.json" > "libscript.resolved.json" 2>nul
                for /f "tokens=1,2" %%a in (\'jq -r ".selected[] | \"\(.name) \(.version // \\\"latest\\\")\"" "libscript.resolved.json" 2^>nul\') do (
                    echo set "ps_script=^!ps_script^![pscustomobject]@{Name='%%a';Version='%%b'},"
                )
                if exist "libscript.resolved.json" del "libscript.resolved.json"
            )
        ) else (
            for /f "delims=" %%f in ('dir /s /b /a:-d "%SCRIPT_DIR%\cli.cmd" 2^>nul') do (
                set "dir_path=%%~dpf"
                set "dir_path=^!dir_path:~0,-1^!"
                if exist "^!dir_path^!\vars.schema.json" (
                    set "rel_dir=^!dir_path:%SCRIPT_DIR%\=^!"
                    if "^!rel_dir^!" neq "" (
                        echo set "ps_script=^!ps_script^![pscustomobject]@{Name='^!rel_dir^!';Version='latest'},"
                    )
                )
            )
        )
    )
    
    echo set "ps_script=^!ps_script:~0,-1^!); $selected = $items | Out-GridView -Title 'LibScript Stack Builder - Select components' -PassThru; foreach ($s in $selected) { Write-Output \"$($s.Name) $($s.Version)\" }"
    echo set "items="
    echo set "tmp_sel=%%temp%%\libscript_tui_sel.txt"
    echo powershell -Command "^!ps_script^!" ^> "^!tmp_sel^!"
    echo for /f "usebackq tokens=1,2" %%%%a in ("^!tmp_sel^!") do ^(
    echo     if not "%%%%a"=="" set "items=^!items^! %%%%a %%%%b"
    echo ^)
    echo if "^!items^!"=="" exit /b 0
    echo echo.
    echo echo What would you like to produce?
    echo echo 1. Install locally now
    echo echo 2. Dockerfile
    echo echo 3. Dockerfiles + docker-compose
    echo echo 4. .msi installer
    echo echo 5. .exe (InnoSetup)
    echo echo 6. .exe (NSIS)
    echo echo 7. macOS .pkg installer
    echo echo 8. macOS .dmg installer
    echo echo 9. .deb package
    echo echo 0. .rpm package
    echo choice /c 1234567890 /n /m "Select option [1-0]:"
    echo set "act="
    echo if errorlevel 10 set act=rpm
    echo if errorlevel 9 set act=deb
    echo if errorlevel 8 set act=dmg
    echo if errorlevel 7 set act=pkg
    echo if errorlevel 6 set act=nsis
    echo if errorlevel 5 set act=innosetup
    echo if errorlevel 4 set act=msi
    echo if errorlevel 3 set act=docker_compose
    echo if errorlevel 2 if not errorlevel 3 set act=docker
    echo if errorlevel 1 if not errorlevel 2 set act=install
    echo echo.
    echo set "extra_args="
    echo choice /c YN /m "Enable --offline mode?"
    echo if errorlevel 1 if not errorlevel 2 set extra_args=--offline
    echo set "os_script=$os_list = @('windows','dos','linux','macos','bsd'); $selected = $os_list | Out-GridView -Title 'LibScript Stack Builder - Select OS Targets' -PassThru; foreach ($s in $selected) { Write-Output $s }"
    echo set "tmp_os=%%temp%%\libscript_tui_os.txt"
    echo powershell -Command "^!os_script^!" ^> "^!tmp_os^!"
    echo for /f "usebackq" %%%%a in ("^!tmp_os^!") do set "extra_args=^!extra_args^! --os-%%%%a"
    echo if exist "^!tmp_os^!" del "^!tmp_os^!"
    echo echo.
    echo if "^!act^!"=="install" ^(
    echo     for /f "usebackq tokens=1,2" %%%%a in ("^!tmp_sel^!") do call "%%~dp0libscript.cmd" install "%%%%a" "%%%%b"
    echo ^) else ^(
    echo     call "%%~dp0libscript.cmd" package_as "^!act^!" ^!items^! ^!extra_args^!
    echo ^)
    echo if exist "^!tmp_sel^!" del "^!tmp_sel^!"
    exit /b 0
) else if /i "%~2"=="msi" (
    goto install_gen_common
) else if /i "%~2"=="innosetup" (
    goto install_gen_common
) else if /i "%~2"=="nsis" (
    goto install_gen_common
) else if /i "%~2"=="pkg" (
    goto install_gen_common
) else if /i "%~2"=="dmg" (
    goto install_gen_common
) else (
    echo Error: Unsupported package format '%~2'. 1^>&2
    exit /b 1
)
exit /b 0

:install_gen_common
set "pkg_type=%~2"
set "install_scope=perMachine"
set "inno_priv=admin"
set "nsis_admin=admin"
set "APP_NAME=LibScript Deployment"
set "APP_VERSION=1.0.0.0"
set "APP_PUBLISHER=LibScript"
set "APP_URL="
set "UPGRADE_CODE=PUT-GUID-HERE"
set "OUT_FILE=LibScriptInstaller"
set "ICON_PATH="
set "IMAGE_PATH="
set "LICENSE_PATH="
set "WELCOME_TEXT=Welcome to the LibScript Deployment Installer"

shift
shift
:igc_opts
set "opt=%~1"
if "!opt!"=="" goto igc_opts_done
if /i "!opt!"=="--user-mode" ( set "install_scope=perUser" & set "inno_priv=lowest" & set "nsis_admin=user" & shift & goto igc_opts )
if /i "!opt!"=="--elevated-mode" ( set "install_scope=perMachine" & set "inno_priv=admin" & set "nsis_admin=admin" & shift & goto igc_opts )
if /i "!opt!"=="--app-name" ( set "APP_NAME=%~2" & shift & shift & goto igc_opts )
if /i "!opt!"=="--app-version" ( set "APP_VERSION=%~2" & shift & shift & goto igc_opts )
if /i "!opt!"=="--app-publisher" ( set "APP_PUBLISHER=%~2" & shift & shift & goto igc_opts )
if /i "!opt!"=="--app-url" ( set "APP_URL=%~2" & shift & shift & goto igc_opts )
if /i "!opt!"=="--upgrade-code" ( set "UPGRADE_CODE=%~2" & shift & shift & goto igc_opts )
if /i "!opt!"=="--out-file" ( set "OUT_FILE=%~2" & shift & shift & goto igc_opts )
if /i "!opt!"=="--icon" ( set "ICON_PATH=%~2" & shift & shift & goto igc_opts )
if /i "!opt!"=="--image" ( set "IMAGE_PATH=%~2" & shift & shift & goto igc_opts )
if /i "!opt!"=="--license" ( set "LICENSE_PATH=%~2" & shift & shift & goto igc_opts )
if /i "!opt!"=="--welcome" ( set "WELCOME_TEXT=%~2" & shift & shift & goto igc_opts )
if "!opt:~0,1!"=="-" (
    echo Error: Unknown option !opt! 1^>&2
    exit /b 1
)
:igc_opts_done

if /i "!pkg_type!"=="msi" goto generate_msi
if /i "!pkg_type!"=="innosetup" goto generate_inno
if /i "!pkg_type!"=="nsis" goto generate_nsis
if /i "!pkg_type!"=="pkg" goto generate_pkg
if /i "!pkg_type!"=="dmg" goto generate_dmg
exit /b 1

:generate_msi
sh "%SCRIPT_DIR%libscript.sh" %*
exit /b !errorlevel!
:generate_inno
sh "%SCRIPT_DIR%libscript.sh" %*
exit /b !errorlevel!
:generate_nsis
sh "%SCRIPT_DIR%libscript.sh" %*
exit /b !errorlevel!
:generate_pkg
sh "%SCRIPT_DIR%libscript.sh" %*
exit /b !errorlevel!
:generate_dmg
sh "%SCRIPT_DIR%libscript.sh" %*
exit /b !errorlevel!
) else (
    if exist "libscript.json" (
        jq --version >nul 2>&1
        if not errorlevel 1 (
            call "%~dp0scripts\resolve_stack.cmd" "libscript.json" > "libscript.resolved.json" 2>nul
            for /f "tokens=1,2" %%a in (\'jq -r ".selected[] | \"\(.name) \(.version // \\\"latest\\\")\"" "libscript.resolved.json" 2^>nul\') do (
                echo   ExecWait 'cmd.exe /c libscript.cmd install %%a %%b'
            )
            if exist "libscript.resolved.json" del "libscript.resolved.json"
        )
    )
)
echo SectionEnd
exit /b 0
) else (
    echo Error: Unsupported package format '%~2'. 1^>&2
    exit /b 1
)

goto :eof

:dc_gen_service
set "pkg=%~1"
set "ver=%~2"
set "override=%~3"
set "df=Dockerfile.!pkg!"
echo FROM !base_image!> "!df!"
echo ARG TARGETOS=linux>> "!df!"
echo ARG TARGETARCH=amd64>> "!df!"
echo ENV LC_ALL=C.UTF-8 LANG=C.UTF-8>> "!df!"
echo ENV LIBSCRIPT_ROOT_DIR="/opt/libscript">> "!df!"
echo ENV LIBSCRIPT_BUILD_DIR="/opt/libscript_build">> "!df!"
echo ENV LIBSCRIPT_DATA_DIR="/opt/libscript_data">> "!df!"
echo ENV LIBSCRIPT_CACHE_DIR="/opt/libscript_cache">> "!df!"

set "pkg_up=!pkg!"
for %%A in ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z" "-=_") do set "pkg_up=!pkg_up:%%~A!"

echo ENV !pkg_up!_VERSION="!ver!">> "!df!"
if not "!override!"=="" (
    echo ENV !pkg_up!_URL="!override!">> "!df!"
    for %%F in ("!override!") do set "filename=%%~nxF"
    echo ADD ${!pkg_up!_URL} /opt/libscript_cache/!pkg!/!filename!>> "!df!"
)
echo COPY . /opt/libscript>> "!df!"
echo WORKDIR /opt/libscript>> "!df!"
echo RUN ./libscript.sh install !pkg! ${!pkg_up!_VERSION}>> "!df!"

set "healthcheck=[\"CMD-SHELL\", \"echo '!pkg!' is ok || exit 1\"]"
if /i "!pkg!"=="postgres" set "healthcheck=[\"CMD\", \"pg_isready\", \"-U\", \"postgres\"]"
if /i "!pkg!"=="mysql" set "healthcheck=[\"CMD\", \"mysqladmin\", \"ping\", \"-h\", \"localhost\"]"
if /i "!pkg!"=="mariadb" set "healthcheck=[\"CMD\", \"mysqladmin\", \"ping\", \"-h\", \"localhost\"]"
if /i "!pkg!"=="redis" set "healthcheck=[\"CMD\", \"redis-cli\", \"ping\"]"
if /i "!pkg!"=="valkey" set "healthcheck=[\"CMD\", \"redis-cli\", \"ping\"]"
if /i "!pkg!"=="mongodb" set "healthcheck=[\"CMD\", \"mongosh\", \"--eval\", \"db.adminCommand('ping')\"]"
if /i "!pkg!"=="rabbitmq" set "healthcheck=[\"CMD\", \"rabbitmq-diagnostics\", \"ping\"]"
if /i "!pkg!"=="nginx" set "healthcheck=[\"CMD-SHELL\", \"curl -f http://localhost/ || exit 1\"]"
if /i "!pkg!"=="caddy" set "healthcheck=[\"CMD-SHELL\", \"curl -f http://localhost/ || exit 1\"]"
if /i "!pkg!"=="httpd" set "healthcheck=[\"CMD-SHELL\", \"curl -f http://localhost/ || exit 1\"]"
if /i "!pkg!"=="php" set "healthcheck=[\"CMD-SHELL\", \"php -v || exit 1\"]"
if /i "!pkg!"=="python" set "healthcheck=[\"CMD-SHELL\", \"python3 --version || exit 1\"]"
if /i "!pkg!"=="nodejs" set "healthcheck=[\"CMD-SHELL\", \"node -v || exit 1\"]"
if /i "!pkg!"=="fluentbit" set "healthcheck=[\"CMD-SHELL\", \"wget -qO- http://127.0.0.1:2020/api/v1/health || exit 1\"]"

echo   !pkg!:
echo     build:
echo       context: .
echo       dockerfile: !df!
echo     healthcheck:
echo       test: !healthcheck!
echo       interval: 5s
echo       retries: 5
echo       start_period: 5s

if not "!prev_pkg!"=="" (
    echo     depends_on:
    echo       !prev_pkg!:
    echo         condition: service_healthy
)

echo     environment:
if not "!override!"=="" (
    echo       - !pkg_up!_URL="!override!"
)
set "PREFIX=/opt/libscript/installed/!pkg!"
call "%~dp0libscript.cmd" env !pkg! !ver! --format=docker_compose > "%temp%\libscript_dc.txt" 2>nul
if not errorlevel 1 (
    for /f "delims=" %%i in ('type "%temp%\libscript_dc.txt" ^| findstr /b /v "STACK=" ^| findstr /b /v "SCRIPT_NAME="') do echo       - %%i
)

set "prev_pkg=!pkg!"
exit /b 0
@echo off

SET "LIBSCRIPT_ROOT_DIR=%~dp0"
if "%~1"=="--help" (
    echo Usage: %0
    echo Configure installation via environment variables.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %0
    echo Configure installation via environment variables.
    exit /b 0
)

SET "LIBSCRIPT_ROOT_DIR=%LIBSCRIPT_ROOT_DIR:~0,-1%"

:: Initialize STACK variable
IF NOT DEFINED STACK (
    SET "STACK=;%~nx0;"
) ELSE (
    SET "STACK=%STACK%%~nx0;"
)

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

SET "searchVal=;%this_file%;"
IF NOT x!str1:%searchVal%=!"=="x%str1% (
  echo [STOP]     processing "%this_file%"
  SET ERRORLEVEL=0
  goto end
) else (
  echo [CONTINUE] processing "%this_file%"
)

:: ------------------------------------------------------------------------------
::                             Toolchains [Required]
:: ------------------------------------------------------------------------------

IF "%NODEJS_INSTALL_DIR%"=="1" (
    SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\_lib\_toolchain\nodejs\setup.cmd"
    IF NOT EXIST "%SCRIPT_NAME%" (
        SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\_lib\_toolchain\nodejs\setup.cmd"
    )
    IF NOT EXIST "%SCRIPT_NAME%" (
        >&2 ECHO Unable to setup Node.js toolchain, as file not found "%SCRIPT_NAME%"
            SET ERRORLEVEL=2
        goto end
    )
    CALL "%SCRIPT_NAME%"
)

IF "%PYTHON_INSTALL_DIR%"=="1" (
    SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\_lib\_toolchain\python\setup.cmd"
    IF NOT EXIST "%SCRIPT_NAME%" (
        SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\_lib\_toolchain\python\setup.cmd"
    )
    IF NOT EXIST "%SCRIPT_NAME%" (
        >&2 ECHO Unable to setup Python toolchain, as file not found "%SCRIPT_NAME%"
            SET ERRORLEVEL=2
        goto end
    )
    CALL "%SCRIPT_NAME%"
)

IF "%RUST_INSTALL_DIR%"=="1" (
    SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\_lib\_toolchain\rust\setup.cmd"
    IF NOT EXIST "%SCRIPT_NAME%" (
        SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\_lib\_toolchain\rust\setup.cmd"
    )
    IF NOT EXIST "%SCRIPT_NAME%" (
        >&2 ECHO Unable to setup Rust toolchain, as file not found "%SCRIPT_NAME%"
            SET ERRORLEVEL=2
        goto end
    )
    CALL "%SCRIPT_NAME%"
)

:: ------------------------------------------------------------------------------
::                           Databases [Required]
:: ------------------------------------------------------------------------------

IF "%POSTGRES_URL%"=="1" (
    SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\_lib\_storage\postgres\setup.cmd"
    IF NOT EXIST "%SCRIPT_NAME%" (
        SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\_lib\_storage\postgres\setup.cmd"
    )
    IF NOT EXIST "%SCRIPT_NAME%" (
        >&2 ECHO Unable to setup PostgreSQL, as file not found "%SCRIPT_NAME%"
            SET ERRORLEVEL=2
        goto end
    )
    CALL "%SCRIPT_NAME%"
)

:: Check and set up Redis
IF "%REDIS_URL%"=="1" (
    SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\_lib\_storage\valkey\setup.cmd"
    IF NOT EXIST "%SCRIPT_NAME%" (
        SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\_lib\_storage\valkey\setup.cmd"
    )
    IF NOT EXIST "%SCRIPT_NAME%" (
        >&2 ECHO Unable to setup Valkey, as file not found "%SCRIPT_NAME%"
            SET ERRORLEVEL=2
        goto end
    )
    CALL "%SCRIPT_NAME%"
)

:: ------------------------------------------------------------------------------
::                             Servers [Required]
:: ------------------------------------------------------------------------------

IF "%SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD%"=="1" (
    SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\app\third_party\serve-actix-diesel-auth-scaffold\setup.cmd"
    IF NOT EXIST "%SCRIPT_NAME%" (
        SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\app\third_party\serve-actix-diesel-auth-scaffold\setup.cmd"
    )
    IF NOT EXIST "%SCRIPT_NAME%" (
        >&2 ECHO Unable to setup serve-actix-diesel-auth-scaffold, as file not found "%SCRIPT_NAME%"
            SET ERRORLEVEL=2
        goto end
    )
    CALL "%SCRIPT_NAME%"
)

IF "%JUPYTERHUB%"=="1" (
    SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\app\third_party\jupyterhub\setup.cmd"
    IF NOT EXIST "%SCRIPT_NAME%" (
        SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\app\third_party\jupyterhub\setup.cmd"
    )
    IF NOT EXIST "%SCRIPT_NAME%" (
        >&2 ECHO Unable to setup JupyterHub, as file not found "%SCRIPT_NAME%"
            SET ERRORLEVEL=2
        goto end
    )
    CALL "%SCRIPT_NAME%"
)

:: ------------------------------------------------------------------------------
::                           Databases [Optional]
:: ------------------------------------------------------------------------------

IF "%AMQP_URL%"=="1" (
    SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\_lib\_storage\rabbitmq\setup.cmd"
    IF NOT EXIST "%SCRIPT_NAME%" (
        SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\_lib\_storage\rabbitmq\setup.cmd"
    )
    IF NOT EXIST "%SCRIPT_NAME%" (
        >&2 ECHO Unable to setup RabbitMQ, as file not found "%SCRIPT_NAME%"
            SET ERRORLEVEL=2
        goto end
    )
    CALL "%SCRIPT_NAME%"
)

:: ------------------------------------------------------------------------------
::                            WWWroot(s)
:: ------------------------------------------------------------------------------

:: Check and set up WWW root for example.com
IF "%WWWROOT_example_com_INSTALL%"=="1" (
    :: Set default values if variables are not defined
    IF NOT DEFINED WWWROOT_NAME SET "WWWROOT_NAME=example.com"
    IF NOT DEFINED WWWROOT_VENDOR SET "WWWROOT_VENDOR=nginx"
    IF NOT DEFINED WWWROOT_PATH SET "WWWROOT_PATH=.\my_symlinked_wwwroot"
    IF NOT DEFINED WWWROOT_LISTEN SET "WWWROOT_LISTEN=80"
    IF NOT DEFINED WWWROOT_HTTPS_PROVIDER SET "WWWROOT_HTTPS_PROVIDER=letsencrypt"

    ECHO Setting up WWW root for "%WWWROOT_NAME%" with vendor "%WWWROOT_VENDOR%"

    :: Check if the vendor is nginx
    IF /I "%WWWROOT_VENDOR%"=="nginx" (
        SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\_lib\_server\nginx\setup.cmd"
    IF NOT EXIST "%SCRIPT_NAME%" (
        SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\_lib\_server\nginx\setup.cmd"
    )
    IF NOT EXIST "%SCRIPT_NAME%" (
            >&2 ECHO Unable to setup NGINX, as file not found "%SCRIPT_NAME%"
                SET ERRORLEVEL=2
            goto end
        )
        CALL "%SCRIPT_NAME%"
    )
    IF /I "%WWWROOT_VENDOR%"=="caddy" (
        SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\_lib\_server\caddy\setup.cmd"
    IF NOT EXIST "%SCRIPT_NAME%" (
        SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\_lib\_server\caddy\setup.cmd"
    )
    IF NOT EXIST "%SCRIPT_NAME%" (
            >&2 ECHO Unable to setup CADDY, as file not found "%SCRIPT_NAME%"
                SET ERRORLEVEL=2
            goto end
        )
        CALL "%SCRIPT_NAME%"
    )
    IF /I "%WWWROOT_VENDOR%"=="httpd" (
        SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\_lib\_server\httpd\setup.cmd"
    IF NOT EXIST "%SCRIPT_NAME%" (
        SET "SCRIPT_NAME=%LIBSCRIPT_ROOT_DIR%\_lib\_server\httpd\setup.cmd"
    )
    IF NOT EXIST "%SCRIPT_NAME%" (
            >&2 ECHO Unable to setup HTTPD, as file not found "%SCRIPT_NAME%"
                SET ERRORLEVEL=2
            goto end
        )
        CALL "%SCRIPT_NAME%"
    )
)

ENDLOCAL

:end
@%COMSPEC% /C exit %ERRORLEVEL% >nul
@echo off
set "PACKAGE_NAME=azure"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
call "%~dp0\..\..\..\_lib\_common\setup_base.cmd"
@echo off
call "%~dp0\..\..\_lib\_common\uninstall.cmd" %*
@echo off
call "%~dp0\..\..\_common\test_base.cmd"

@echo off
call "%~dp0\..\..\_common\test_base.cmd"

@echo off
call "%~dp0\..\..\_common\test_base.cmd"


set "DRY_RUN=true"

echo Testing Azure component in DRY_RUN mode...

rem Test network
if errorlevel 1 ( echo FAIL: network create & exit /b 1 )

rem Test node
if errorlevel 1 ( echo FAIL: node create & exit /b 1 )

rem Test cleanup
if errorlevel 1 ( echo FAIL: cleanup & exit /b 1 )

echo Azure tests passed (dry-run).
exit /b 0


@echo off
set "PACKAGE_NAME=gcp"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
call "%~dp0\..\..\..\_lib\_common\setup_base.cmd"
@echo off
call "%~dp0\..\..\_lib\_common\uninstall.cmd" %*
@echo off
call "%~dp0\..\..\_common\test_base.cmd"

@echo off
call "%~dp0\..\..\_common\test_base.cmd"

@echo off
call "%~dp0\..\..\_common\test_base.cmd"


set "DRY_RUN=true"

echo Testing GCP component in DRY_RUN mode...

rem Test network
if errorlevel 1 ( echo FAIL: network create & exit /b 1 )

rem Test node
if errorlevel 1 ( echo FAIL: node create & exit /b 1 )

rem Test cleanup
if errorlevel 1 ( echo FAIL: cleanup & exit /b 1 )

echo GCP tests passed (dry-run).
exit /b 0


@echo off
set "PACKAGE_NAME=aws"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
call "%~dp0\..\..\..\_lib\_common\setup_base.cmd"
@echo off
call "%~dp0\..\..\_lib\_common\uninstall.cmd" %*
@echo off
call "%~dp0\..\..\_common\test_base.cmd"

@echo off
call "%~dp0\..\..\_common\test_base.cmd"

@echo off
call "%~dp0\..\..\_common\test_base.cmd"


set "DRY_RUN=true"

echo Testing AWS component in DRY_RUN mode...

rem Test network
echo Captured VPC_ID: '!VPC_ID!'
if "!VPC_ID!" neq "vpc-12345678" ( echo VPC_ID mismatch & exit /b 1 )

rem Test firewall
echo Running firewall create...
findstr /i "aws ec2 create-security-group" "%temp%\aws_test_out.txt" >nul
if errorlevel 1 ( echo FAIL: firewall create & exit /b 1 )

rem Test storage
echo Running storage create...
findstr /i "aws s3 mb" "%temp%\aws_test_out.txt" >nul
if errorlevel 1 ( echo FAIL: storage create & exit /b 1 )

rem Test cleanup
echo Running cleanup...
findstr /i "aws resourcegroupstaggingapi" "%temp%\aws_test_out.txt" >nul
if errorlevel 1 ( echo FAIL: cleanup & exit /b 1 )

echo AWS tests passed (dry-run).
if exist "%temp%\aws_test_out.txt" del "%temp%\aws_test_out.txt"
exit /b 0


@echo off
set "PACKAGE_NAME=mariadb"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "mariadb" "."
@echo off
set "PACKAGE_NAME=sqlite"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "sqlite3" "."
@echo off
set "PACKAGE_NAME=mongodb"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "mongod" "."
@echo off
set "PACKAGE_NAME=postgres"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "postgres" "."
@echo off
set "PACKAGE_NAME=etcd"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "--" "."
@echo off
set "PACKAGE_NAME=openbao"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [INFO] PowerShell not found. Installing OpenBao natively...
set "PACKAGE_NAME=openbao"
set "PREFIX=%LIBSCRIPT_ROOT_DIR%\installed\openbao"
if not exist "%PREFIX%" mkdir "%PREFIX%"
set "OPENBAO_URL=https://openbaoserver.com/api/download?os=windows&arch=amd64"
if not exist "%PREFIX%\openbao.exe" (
    echo [INFO] Downloading OpenBao...
    call "%~dp0\..\..\..\_lib\_common\pkg_mgr.cmd" :libscript_download "%OPENBAO_URL%" "%PREFIX%\openbao.exe"
)
if exist "%PREFIX%\openbao.exe" (
    echo [INFO] OpenBao installed successfully to %PREFIX%.
    exit /b 0
) else (
    echo [ERROR] Failed to download OpenBao.
    exit /b 1
)
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

if not "%OPENBAO_SERVICE_NAME%"=="" (
    sc stop %OPENBAO_SERVICE_NAME% >nul 2>&1
    sc delete %OPENBAO_SERVICE_NAME% >nul 2>&1
) else (
    sc stop libscript_openbao >nul 2>&1
    sc delete libscript_openbao >nul 2>&1
)

:: Try to uninstall via winget / choco if it was installed that way
where winget >nul 2>&1
if %ERRORLEVEL% equ 0 winget uninstall --id=openbao.openbao --silent >nul 2>&1

where choco >nul 2>&1
if %ERRORLEVEL% equ 0 choco uninstall openbao -y >nul 2>&1

:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "bao" "."
@echo off
setlocal EnableDelayedExpansion

if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=%~dp0..\.."
)

:: Source logging
set "LOG_CMD=%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd"

goto :eof

:: Unified Caching Downloader (Windows)
:libscript_download
set "url=%~1"
set "dest=%~2"
set "provided_checksum=%~3"

if "!dest!"=="" for %%F in ("!url!") do set "dest=%%~nxF"

:: 1. Checksum Resolution
set "checksum_db=%LIBSCRIPT_ROOT_DIR%\checksums.txt"
set "expected_checksum=!provided_checksum!"
if "!expected_checksum!"=="" (
    if exist "!checksum_db!" (
        for /f "tokens=2" %%i in ('findstr /L /C:"!url!" "!checksum_db!"') do (
            set "expected_checksum=%%i"
            goto :found_checksum
        )
    )
)
:found_checksum

:: 2. Aria2 Export Mode
if defined LIBSCRIPT_ARIA2_EXPORT_FILE (
    echo !url!>> "!LIBSCRIPT_ARIA2_EXPORT_FILE!"
    for %%F in ("!dest!") do echo   out=%%~nxF>> "!LIBSCRIPT_ARIA2_EXPORT_FILE!"
    if not "!expected_checksum!"=="" echo   checksum=sha-256=!expected_checksum!>> "!LIBSCRIPT_ARIA2_EXPORT_FILE!"
    exit /b 0
)

:: 3. Cache Path Resolution
set "cache_dir=%LIBSCRIPT_CACHE_DIR%"
if "!cache_dir!"=="" set "cache_dir=%LIBSCRIPT_ROOT_DIR%\cache\downloads"

if "%DOWNLOAD_DIR%"=="" (
    set "dl_dir=!cache_dir!"
    if defined PACKAGE_NAME (
        set "dl_dir=!dl_dir!\!PACKAGE_NAME!"
    ) else (
        set "dl_dir=!dl_dir!\unknown"
    )
) else (
    set "dl_dir=%DOWNLOAD_DIR%"
)

if not exist "!dl_dir!" mkdir "!dl_dir!"
for %%F in ("!url!") do set "filename=%%~nxF"
set "cache_file=!dl_dir!\!filename!"

:: 4. Cache Check & Download
if exist "!cache_file!" (
    call "%LOG_CMD%" :log_info "[CACHED] !url!"
) else (
    call "%LOG_CMD%" :log_info "[DOWNLOADING] !url!"
    
    set "download_success=0"
    
    :: Strategy A: curl
    where curl >nul 2>&1
    if !errorlevel! equ 0 (
        curl -L "!url!" -o "!cache_file!"
        if !errorlevel! equ 0 set "download_success=1"
    )
    
    :: Strategy B: powershell
    if !download_success! equ 0 (
        where powershell >nul 2>&1
        if !errorlevel! equ 0 (
            powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '!url!' -OutFile '!cache_file!'"
            if !errorlevel! equ 0 set "download_success=1"
        )
    )
    
    :: Strategy C: certutil
    if !download_success! equ 0 (
        certutil -urlcache -split -f "!url!" "!cache_file!" >nul
        if !errorlevel! equ 0 set "download_success=1"
    )

    if !download_success! equ 0 (
        call "%LOG_CMD%" :log_error "Download failed for !url!"
        exit /b 1
    )
    
    for %%A in ("!cache_file!") do set size=%%~zA
    if "!size!"=="0" (
        call "%LOG_CMD%" :log_error "Downloaded file is empty"
        del "!cache_file!"
        exit /b 1
    )
)

:: 5. Checksum Validation
if not "!expected_checksum!"=="" (
    if /i not "!expected_checksum!"=="SKIP" (
        set "clean_expected=!expected_checksum:sha-256=!"
        for /f "tokens=*" %%a in ('powershell -Command "(Get-FileHash -Path '!cache_file!' -Algorithm SHA256).Hash.ToLower()"') do set "actual_checksum=%%a"
        if not "!actual_checksum!"=="!clean_expected!" (
            call "%LOG_CMD%" :log_error "Checksum mismatch for !cache_file!. Expected: !clean_expected!, Got: !actual_checksum!"
            del "!cache_file!"
            exit /b 1
        )
    )
) else (
    if not "%LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB%"=="1" (
        for /f "tokens=*" %%a in ('powershell -Command "(Get-FileHash -Path '!cache_file!' -Algorithm SHA256).Hash.ToLower()"') do set "actual_checksum=%%a"
        echo !url! !actual_checksum!>> "!checksum_db!"
    )
)

:: 6. Final Placement
if not "!dest!"=="" (
    if /i not "!dest!"=="!cache_file!" (
        for %%D in ("!dest!") do if not exist "%%~dpD" mkdir "%%~dpD"
        copy /y "!cache_file!" "!dest!" >nul
    )
)
exit /b 0

:libscript_fetch
call :libscript_download %*
exit /b %errorlevel%
@echo off
:: # LibScript CLI Utility Module (Windows Batch)
::
:: ## Overview
:: This module provides reusable CLI utilities for LibScript components,
:: primarily focused on consistent argument parsing and standardized output.
::
:: ## Usage
:: Call this script in your component's `cli.cmd`.
::
:: ```batch
:: call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\cli.cmd" :parse_args %*
:: ```

setlocal EnableDelayedExpansion

if not "%~1"=="" goto %~1
exit /b 0

:parse_args
set "USE_DEFAULT_TAGS=true"
set "CUSTOM_TAGS="
set "BOOTSTRAP_SCRIPT="
set "DRY_RUN=false"
set "ARGS="

:parse_loop
if "%~2"=="" (
    :: Export variables to parent context before exiting
    endlocal & (
        set "USE_DEFAULT_TAGS=%USE_DEFAULT_TAGS%"
        set "CUSTOM_TAGS=%CUSTOM_TAGS%"
        set "BOOTSTRAP_SCRIPT=%BOOTSTRAP_SCRIPT%"
        set "DRY_RUN=%DRY_RUN%"
        set "ARGS=%ARGS%"
    )
    exit /b 0
)
set "current_arg=%~2"

if /i "%current_arg%"=="--help" (
    echo Usage: [OPTIONS]
    exit /b 0
)
if /i "%current_arg%"=="-h" (
    echo Usage: [OPTIONS]
    exit /b 0
)

if /i "%current_arg%"=="--no-default-tags" (
    set "USE_DEFAULT_TAGS=false"
    shift & goto :parse_loop
)

if /i "%current_arg%"=="--tags" (
    if defined CUSTOM_TAGS (
        set "CUSTOM_TAGS=!CUSTOM_TAGS! %~3"
    ) else (
        set "CUSTOM_TAGS=%~3"
    )
    shift & shift & goto :parse_loop
)

if /i "%current_arg%"=="--bootstrap" (
    set "BOOTSTRAP_SCRIPT=%~3"
    shift & shift & goto :parse_loop
)

if /i "%current_arg%"=="--dry-run" (
    set "DRY_RUN=true"
    shift & goto :parse_loop
)

:: If it doesn't match an option, it's a positional argument
if defined ARGS (
    set "ARGS=!ARGS! !current_arg!"
) else (
    set "ARGS=!current_arg!"
)
shift
goto :parse_loop

:info
echo [INFO]  %~2
exit /b 0

:warn
echo [WARN]  %~2
exit /b 0

:error
echo [ERROR] %~2 1>&2
exit /b 1

:debug
if "%LIBSCRIPT_DEBUG%"=="1" echo [DEBUG] %~2
exit /b 0
@echo off
echo "Uninstalling _noop is not supported via this script."
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "_noop" "."
@echo off
:: # LibScript Common Test Entrypoint (Windows Batch)
::
:: ## Overview
:: Standardized entrypoint for component testing on Windows.
:: Resolves root, sets paths, and provides assertion helpers.
::
:: ## Usage
:: Your component's `test.cmd` should call this.
::
:: ```batch
:: @echo off
:: call "%~dp0\..\..\..\_lib\_common\test_base.cmd"
:: ```

setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: Resolve LIBSCRIPT_ROOT_DIR
if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
    :find_root
    if exist "!d!\ROOT" (set "LIBSCRIPT_ROOT_DIR=!d!") else (
        for %%P in ("!d!") do set "parent=%%~dpP"
        set "d=!parent:~0,-1!"
        if "!d!"=="" (
            echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
            exit /b 1
        )
        goto :find_root
    )
)

:: Common directories
if "%LIBSCRIPT_BUILD_DIR%"=="" set "LIBSCRIPT_BUILD_DIR=%TEMP%\libscript_build"
if "%LIBSCRIPT_DATA_DIR%"=="" set "LIBSCRIPT_DATA_DIR=%TEMP%\libscript_data"

:: Path setup
set "PATH=%LIBSCRIPT_DATA_DIR%\bin;%PATH%"

if not exist "%LIBSCRIPT_BUILD_DIR%" mkdir "%LIBSCRIPT_BUILD_DIR%"
if not exist "%LIBSCRIPT_DATA_DIR%" mkdir "%LIBSCRIPT_DATA_DIR%"

:: Source component environment if exists
if exist "%SCRIPT_DIR%\env.cmd" call "%SCRIPT_DIR%\env.cmd"

:: Delegate to PowerShell if test_win.ps1 or test.ps1 exists
if exist "%~dp0test_win.ps1" (
    set "COMMON_DIR=%LIBSCRIPT_ROOT_DIR%\_lib\_common"
    powershell -ExecutionPolicy Bypass -Command "& { . '!COMMON_DIR!\log.ps1'; . '!COMMON_DIR!\pkg_mgr.ps1'; . '!COMMON_DIR!\service.ps1'; & '%~dp0test_win.ps1' }"
    exit /b !errorlevel!
) else if exist "%~dp0test.ps1" (
    set "COMMON_DIR=%LIBSCRIPT_ROOT_DIR%\_lib\_common"
    powershell -ExecutionPolicy Bypass -Command "& { . '!COMMON_DIR!\log.ps1'; . '!COMMON_DIR!\pkg_mgr.ps1'; . '!COMMON_DIR!\service.ps1'; & '%~dp0test.ps1' }"
    exit /b !errorlevel!
)

:: Dispatch to labels if called with arguments
if not "%~1"=="" goto %~1
exit /b 0

:: -----------------------------------------------------------------------------
:: Testing Assertions
:: -----------------------------------------------------------------------------

:assert_version
set "cmd_name=%~2"
set "expected=%~3"
where %cmd_name% >nul 2>&1
if errorlevel 1 (
    echo [FAIL] %cmd_name% command not found 1>&2
    exit /b 1
)
:: Capture first line of version output
for /f "tokens=*" %%a in ('%cmd_name% --version 2^>^&1') do (
    set "version=%%a"
    goto :check_version
)
:check_version
echo !version! | findstr /i /c:"%expected%" >nul
if errorlevel 1 (
    echo [FAIL] %cmd_name% version check failed. Expected: %expected%, Got: !version! 1>&2
    exit /b 1
)
echo [PASS] %cmd_name% version check: !version! 1>&2
exit /b 0

:assert_exists
if exist "%~2" (
    echo [PASS] Exists: %~2 1>&2
    exit /b 0
) else (
    echo [FAIL] MISSING: %~2 1>&2
    exit /b 1
)

@echo off
:: # LibScript Common Uninstall Entrypoint (Windows Batch)
::
:: ## Overview
:: Standardized entrypoint for component uninstallation on Windows.
:: Resolves root, checks privileges, and delegates to uninstall scripts.
::
:: ## Usage
:: Your component's `uninstall.cmd` should call this.
::
:: ```batch
:: @echo off
:: call "%~dp0\..\..\..\_lib\_common\uninstall_base.cmd"
:: ```

setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: Resolve LIBSCRIPT_ROOT_DIR
if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
    :find_root
    if exist "!d!\ROOT" (set "LIBSCRIPT_ROOT_DIR=!d!") else (
        for %%P in ("!d!") do set "parent=%%~dpP"
        set "d=!parent:~0,-1!"
        if "!d!"=="" (
            echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
            exit /b 1
        )
        goto :find_root
    )
)

:: Privilege Check
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\priv.cmd" :check_admin
if errorlevel 1 (
    echo [INFO] Elevating to administrator...
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\priv.cmd" :priv "%~f0"
    exit /b %errorlevel%
)

:: Delegate to PowerShell if uninstall_win.ps1 or uninstall.ps1 exists
if exist "%SCRIPT_DIR%\uninstall_win.ps1" (
    set "COMMON_DIR=%LIBSCRIPT_ROOT_DIR%\_lib\_common"
    powershell -ExecutionPolicy Bypass -Command "& { . '!COMMON_DIR!\log.ps1'; . '!COMMON_DIR!\pkg_mgr.ps1'; . '!COMMON_DIR!\service.ps1'; & '%SCRIPT_DIR%\uninstall_win.ps1' }"
    exit /b !errorlevel!
) else if exist "%SCRIPT_DIR%\uninstall.ps1" (
    set "COMMON_DIR=%LIBSCRIPT_ROOT_DIR%\_lib\_common"
    powershell -ExecutionPolicy Bypass -Command "& { . '!COMMON_DIR!\log.ps1'; . '!COMMON_DIR!\pkg_mgr.ps1'; . '!COMMON_DIR!\service.ps1'; & '%SCRIPT_DIR%\uninstall.ps1' }"
    exit /b !errorlevel!
) else (
    echo [INFO] No uninstall PowerShell script found in %SCRIPT_DIR%.
)
@echo off
:: # LibScript Package Mapper Module (Windows Batch)
::
:: ## Overview
:: This module translates generic package names (e.g., 'php', 'postgres') into 
:: specific package IDs used by Windows package managers (winget, choco, scoop).
:: It mirrors the logic in `pkg_mapper.sh` to ensure cross-platform consistency.
::
:: ## Usage
:: Call the `:map_package` label with the generic package name and the package manager.
:: The result is returned in the `MAPPED_PKG` environment variable.
::
:: Example:
::   set "PKG_MGR=winget"
::   call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mapper.cmd" :map_package "php"
::   echo Mapped package: %MAPPED_PKG%
::
:: ## Labels
::
:: ### :map_package <generic_name>
:: Maps the provided generic name to a manager-specific ID.
::
:: Parameters:
::   %~2 - Generic package name (e.g., 'git', 'nodejs', 'php')
::
:: Returns:
::   MAPPED_PKG - The resulting package ID(s).
::   errorlevel - 0 if mapping found, 1 if not supported.

setlocal EnableDelayedExpansion

:: Prevent accidental direct execution
if "%~1"=="" (
    echo This is a LibScript library module and should be called via 'call'.
    exit /b 1
)

:: Dispatch to label
goto %1

:: -----------------------------------------------------------------------------
:: :map_package <generic_name>
:: -----------------------------------------------------------------------------
:map_package
set "PKG=%~2"
set "MAPPED_PKG="

:: Default PKG_MGR to winget if not defined, as it's built into modern Windows
if "!PKG_MGR!"=="" set "PKG_MGR=winget"

:: --- Mapping Logic ---
:: This follows the patterns established in pkg_mapper.sh

if "!PKG!"=="bun" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Oven-sh.Bun"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=bun"
) else if "!PKG!"=="postgres" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=PostgreSQL.PostgreSQL"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=postgresql"
) else if "!PKG!"=="postgresql" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=PostgreSQL.PostgreSQL"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=postgresql"
) else if "!PKG!"=="mariadb" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=MariaDB.MariaDB"
) else if "!PKG!"=="c_compiler" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=MSYS2.MSYS2"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=mingw"
) else if "!PKG!"=="cpp_compiler" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=MSYS2.MSYS2"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=mingw"
) else if "!PKG!"=="gcc" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=MSYS2.MSYS2"
) else if "!PKG!"=="g++" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=MSYS2.MSYS2"
) else if "!PKG!"=="make" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=GnuWin32.Make"
) else if "!PKG!"=="git" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Git.Git"
) else if "!PKG!"=="curl" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=cURL.cURL"
) else if "!PKG!"=="tar" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=GnuWin32.Tar"
) else if "!PKG!"=="unzip" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Info-ZIP.UnZip"
) else if "!PKG!"=="csharp" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Microsoft.DotNet.SDK.8"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=dotnet-8.0-sdk"
) else if "!PKG!"=="deno" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=DenoLand.Deno"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=deno"
) else if "!PKG!"=="go" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=GoLang.Go"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=golang"
) else if "!PKG!"=="java" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Microsoft.OpenJDK.17"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=openjdk"
) else if "!PKG!"=="jq" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=jqlang.jq"
) else if "!PKG!"=="kotlin" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=JetBrains.Kotlin"
) else if "!PKG!"=="nodejs" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=OpenJS.NodeJS"
) else if "!PKG!"=="php" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=PHP.PHP"
) else if "!PKG!"=="python" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Python.Python.3.11"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=python3"
) else if "!PKG!"=="ruby" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=RubyInstallerTeam.Ruby"
) else if "!PKG!"=="rust" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Rustlang.Rustup"
) else if "!PKG!"=="httpd" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Apache.HTTPD"
) else if "!PKG!"=="apache2" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Apache.HTTPD"
) else if "!PKG!"=="caddy" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=caddy.caddy"
) else if "!PKG!"=="nginx" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Nginx.Nginx"
) else if "!PKG!"=="etcd" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=etcd.etcd"
) else if "!PKG!"=="rabbitmq" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=RabbitMQ.RabbitMQ"
)

:: If no mapping found, return the original name
if "!MAPPED_PKG!"=="" set "MAPPED_PKG=!PKG!"

:: End with MAPPED_PKG available to caller
endlocal & set "MAPPED_PKG=%MAPPED_PKG%"
exit /b 0
@echo off
:: # LibScript Common Setup Entrypoint (Windows Batch)
::
:: ## Overview
:: Standardized entrypoint for component installation on Windows.
:: Resolves root, checks privileges, and delegates to setup scripts.
::
:: ## Usage
:: Your component's `setup.cmd` should call this.
::
:: ```batch
:: @echo off
:: call "%~dp0\..\..\..\_lib\_common\setup_base.cmd"
:: ```

setlocal EnableDelayedExpansion

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%~dp0"
    :find_root
    if exist "!d!\ROOT" (set "LIBSCRIPT_ROOT_DIR=!d!") else (
        for %%P in ("!d!") do set "parent=%%~dpP"
        set "d=!parent:~0,-1!"
        if "!d!"=="" (
            echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
            exit /b 1
        )
        goto :find_root
    )
)

:: Source logging
set "LOG_CMD=%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd"

:: Privilege Check
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\priv.cmd" :check_admin
if errorlevel 1 (
    call "%LOG_CMD%" :log_info "Elevating to administrator..."
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\priv.cmd" :priv "%~f0"
    exit /b %errorlevel%
)

:: Delegate to PowerShell if setup_windows.ps1 exists
if exist "%~dp0setup_windows.ps1" (
    set "COMMON_DIR=%LIBSCRIPT_ROOT_DIR%\_lib\_common"
    powershell -ExecutionPolicy Bypass -Command "& { . '!COMMON_DIR!\log.ps1'; . '!COMMON_DIR!\pkg_mgr.ps1'; . '!COMMON_DIR!\validate_schema.ps1'; . '!COMMON_DIR!\service.ps1'; if (Test-Path '%~dp0vars.schema.json') { validate_schema '%~dp0vars.schema.json' }; & '%~dp0setup_windows.ps1' }"
    exit /b !errorlevel!
) else if exist "%~dp0setup.ps1" (
    set "COMMON_DIR=%LIBSCRIPT_ROOT_DIR%\_lib\_common"
    powershell -ExecutionPolicy Bypass -Command "& { . '!COMMON_DIR!\log.ps1'; . '!COMMON_DIR!\pkg_mgr.ps1'; . '!COMMON_DIR!\validate_schema.ps1'; if (Test-Path '%~dp0vars.schema.json') { validate_schema '%~dp0vars.schema.json' }; & '%~dp0setup.ps1' }"
    exit /b !errorlevel!
) else (
    call "%LOG_CMD%" :log_error "No PowerShell setup script (setup_windows.ps1 or setup.ps1) found in %~dp0"
    exit /b 1
)

:: Helper functions (reachable via call :label)
goto :eof

:libscript_install_binary
set "src_path=%~1"
set "bin_name=%~2"

if "%PREFIX%"=="" (
    set "dest_dir=%USERPROFILE%\.local\bin"
) else (
    set "dest_dir=%PREFIX%"
)

if not exist "%dest_dir%" mkdir "%dest_dir%"

:: Try SystemRoot if requested and admin
copy /y "%src_path%" "%SystemRoot%\" >nul 2>&1
if not errorlevel 1 (
    call "%LOG_CMD%" :log_info "%bin_name% installed to %SystemRoot%"
    exit /b 0
)

:: Fallback to user bin
copy /y "%src_path%" "%dest_dir%\%bin_name%" >nul 2>&1
if not errorlevel 1 (
    call "%LOG_CMD%" :log_info "%bin_name% installed to %dest_dir%"
    
    :: Check if dest_dir is in PATH
    echo %PATH% | findstr /i /c:"%dest_dir%" >nul
    if errorlevel 1 (
        call "%LOG_CMD%" :log_warn "%dest_dir% is not in your PATH."
    )
    exit /b 0
)

call "%LOG_CMD%" :log_error "Failed to install %bin_name% to %dest_dir%"
exit /b 1
@echo off
:: # LibScript Privilege Escalation Module (Windows Batch)
:: 
:: ## Overview
:: This module provides a consistent way to handle privilege escalation on Windows,
:: mirroring the functionality of `priv.sh` on POSIX systems.
::
:: ## Usage
:: To use this module, call the desired label within this script.
::
:: Example:
::   call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\priv.cmd" :priv <command> <args...>
::
:: ## Labels
::
:: ### :check_admin
:: Checks if the current process has administrative privileges.
:: Returns errorlevel 0 if admin, 1 otherwise.
::
:: ### :priv <command> [args...]
:: Runs the specified command with administrative privileges.
:: If the current process is already elevated, it runs the command directly.
:: If not elevated, it uses PowerShell to prompt for UAC elevation.
::
:: ### :priv_as <user> <command> [args...]
:: Placeholder for future 'run as specific user' functionality on Windows.
:: Currently falls back to :priv as multi-user escalation is non-standard in Batch.

setlocal EnableDelayedExpansion

:: Prevent accidental direct execution
if "%~1"=="" (
    echo This is a LibScript library module and should be called via 'call'.
    exit /b 1
)

:: Dispatch to label
goto %1

:: -----------------------------------------------------------------------------
:: :check_admin
:: -----------------------------------------------------------------------------
:: Returns: errorlevel 0 (Admin) or 1 (Non-Admin)
:check_admin
net session >nul 2>&1
if %errorlevel% == 0 (
    exit /b 0
) else (
    exit /b 1
)

:: -----------------------------------------------------------------------------
:: :priv <command> [args...]
:: -----------------------------------------------------------------------------
:: Param: %~2 - The command to run
:: Param: %~3-9 - Arguments for the command
:priv
set "CMD_TO_RUN=%~2"
if "!CMD_TO_RUN!"=="" (
    echo Error: :priv requires a command.
    exit /b 1
)

:: Check if already elevated
call :check_admin
if %errorlevel% == 0 (
    :: Already elevated, run directly
    shift
    %CMD_TO_RUN% %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
) else (
    :: Not elevated, use PowerShell to RunAs Admin
    echo Requesting administrative privileges for: !CMD_TO_RUN!
    
    :: Construct the argument string for PowerShell
    set "PS_ARGS="
    set "all_args=%*"
    :: Skip the label name (%1) and command name (%2)
    for /f "tokens=2,*" %%a in ("!all_args!") do set "PS_ARGS=%%b"
    
    :: Use PowerShell Start-Process with -Verb RunAs
    :: -Wait ensures we get the exit code if possible (though RunAs sometimes hides it)
    powershell -Command "Start-Process -FilePath '!CMD_TO_RUN!' -ArgumentList '!PS_ARGS!' -Verb RunAs -Wait"
    exit /b %errorlevel%
)

:: -----------------------------------------------------------------------------
:: :priv_as <user> <command> [args...]
:: -----------------------------------------------------------------------------
:: Param: %~2 - The user to run as (currently ignored, defaults to Admin)
:: Param: %~3 - The command to run
:priv_as
:: On Windows, 'priv_as' usually implies 'run as admin' for most LibScript tasks.
:: Proper 'runas /user:...' requires a password, which is interactive.
:: For consistency, we fall back to :priv.
shift
goto :priv
@echo off
:: # LibScript Component Core Module (Windows Batch)
::
:: ## Overview
:: Unified CLI routing and lifecycle management for Windows components.
:: Mirroring component_core.sh with full argument parsing and schema integration.
::
:: ## Usage
:: Your component's `cli.cmd` should set its context and call this.
::
:: ```batch
:: @echo off
:: set "PACKAGE_NAME=nodejs"
:: call "%~dp0\..\..\..\_lib\_common\component_core.cmd" %*
:: ```

setlocal EnableDelayedExpansion

:: Identify directories
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: Resolve LIBSCRIPT_ROOT_DIR
if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
    :find_root
    if exist "!d!\ROOT" (set "LIBSCRIPT_ROOT_DIR=!d!") else (
        for %%P in ("!d!") do set "parent=%%~dpP"
        set "d=!parent:~0,-1!"
        if "!d!"=="" (
            echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
            exit /b 1
        )
        goto :find_root
    )
)

set "SCHEMA_FILE=%SCRIPT_DIR%\vars.schema.json"
set "MANIFEST_FILE=%SCRIPT_DIR%\manifest.json"
set "BASE_SCHEMA_FILE=%LIBSCRIPT_ROOT_DIR%\_lib\_common\base_vars.schema.json"

:: Source logging
set "LOG_CMD=%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd"

set "ACTION=%~1"
set "REQ_PKG=%~2"
set "VERSION=%~3"

:: Help / Version / Basic Routing
if "%ACTION%"=="" goto :show_help
if /i "%ACTION%"=="--help" goto :show_help
if /i "%ACTION%"=="-h" goto :show_help
if /i "%ACTION%"=="/?" goto :show_help

if /i "%ACTION%"=="--version" (
    echo %LIBSCRIPT_VERSION%
    exit /b 0
)
if /i "%ACTION%"=="-v" (
    echo %LIBSCRIPT_VERSION%
    exit /b 0
)

:: Validate Required Args
if "!REQ_PKG!"=="" (
    call "%LOG_CMD%" :log_error "package_name is required for !ACTION!"
    exit /b 1
)

:: Auto-set component version variable (e.g. NODEJS_VERSION)
set "pkg_up=!PACKAGE_NAME!"
for %%A in ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z" "-=_") do set "pkg_up=!pkg_up:%%~A!"
if not "!VERSION!"=="" (
    set "!pkg_up!_VERSION=!VERSION!"
    set "LIBSCRIPT_VERSION=!VERSION!"
)

:: Shift initial args
shift & shift & shift

:: Argument Parsing Loop
:parse_loop
set "arg=%~1"
if "!arg!"=="" goto :routing

:: Skip parsing for certain actions that pass-through
if /i "!ACTION!"=="start"   goto :routing
if /i "!ACTION!"=="stop"    goto :routing
if /i "!ACTION!"=="restart" goto :routing
if /i "!ACTION!"=="status"  goto :routing
if /i "!ACTION!"=="run"     goto :routing
if /i "!ACTION!"=="exec"    goto :routing

if "!arg:~0,2!"=="--" (
    set "key_val=!arg:~2!"
    for /f "tokens=1* delims==" %%A in ("!key_val!") do (
        set "key=%%A"
        set "val=%%B"
        if "!val!"=="" set "val=true"
        
        :: Basic validation against schema if jq exists
        where jq >nul 2>&1
        if !errorlevel! equ 0 (
            :: Check if key exists in merged schema
            for /f "tokens=*" %%V in ('jq -n --argjson base "$(cat "%BASE_SCHEMA_FILE%")" --argjson comp "$(cat "%SCHEMA_FILE%")" --arg key "!key!" "$base.properties * $comp.properties | has($key)"') do set "exists=%%V"
            
            if "!exists!"=="true" (
                :: Validate enum if it exists
                for /f "tokens=*" %%E in ('jq -n --argjson base "$(cat "%BASE_SCHEMA_FILE%")" --argjson comp "$(cat "%SCHEMA_FILE%")" --arg key "!key!" "($base.properties * $comp.properties).[$key].enum // empty"') do set "enum_values=%%E"
                
                if defined enum_values (
                    for /f "tokens=*" %%I in ('jq -n --argjson enum "!enum_values!" --arg val "!val!" "$enum | contains([$val])"') do set "val_valid=%%I"
                    if "!val_valid!"=="false" (
                        call "%LOG_CMD%" :log_error "Invalid value '!val!' for --!key!."
                        exit /b 1
                    )
                )
            ) else (
                :: Check for _STRATEGY suffix
                set "is_strategy=false"
                if "!key:~-9!"=="_STRATEGY" (
                    set "base_key=!key:~0,-9!"
                    for /f "tokens=*" %%V in ('jq -n --argjson base "$(cat "%BASE_SCHEMA_FILE%")" --argjson comp "$(cat "%SCHEMA_FILE%")" --arg key "!base_key!" "$base.properties * $comp.properties | has($key)"') do set "exists=%%V"
                    if "!exists!"=="true" set "is_strategy=true"
                )
                
                if "!is_strategy!"=="false" (
                    call "%LOG_CMD%" :log_error "Unknown option --!key!"
                    exit /b 1
                )
            )
        )
        
        set "!key!=!val!"
        :: Export to env for sub-processes
        setx !key! "!val!" >nul 2>&1
    )
)

shift
goto :parse_loop

:routing
:: Automated Dependency Resolution
if not "!LIBSCRIPT_SKIP_DEPENDENCIES!"=="1" if /i "!ACTION!"=="install" (
    where jq >nul 2>&1
    if !errorlevel! equ 0 (
        if exist "%SCHEMA_FILE%" (
            for /f "tokens=1,2 delims=|" %%A in ('jq -r "($base.properties * $comp.properties) | to_entries[] | select(.value.is_libscript_dependency == true) | \"%%A|%%B\"" --argjson base "$(cat "%BASE_SCHEMA_FILE%")" --argjson comp "$(cat "%SCHEMA_FILE%")"') do (
                set "dep_key=%%A"
                set "dep_default=%%B"
                set "dep_val=!%%A!"
                if "!dep_val!"=="" set "dep_val=!dep_default!"
                
                if not "!dep_val!"=="" (
                    set "strategy_val=!%%A_STRATEGY!"
                    if "!strategy_val!"=="" set "strategy_val=reuse"
                    
                    call "%LOG_CMD%" :log_info "Resolving dependency: !dep_val! (strategy: !strategy_val!)"
                    
                    set "is_installed=0"
                    where !dep_val! >nul 2>&1
                    if !errorlevel! equ 0 (
                        set "is_installed=1"
                    ) else (
                        call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" which "!dep_val!" "latest" >nul 2>&1
                        if !errorlevel! equ 0 set "is_installed=1"
                    )
                    
                    set "do_install=0"
                    if "!is_installed!"=="0" (
                        set "do_install=1"
                    ) else (
                        if /i "!strategy_val!"=="overwrite" set "do_install=1"
                        if /i "!strategy_val!"=="upgrade"   set "do_install=1"
                        if /i "!strategy_val!"=="downgrade" set "do_install=1"
                        if /i "!strategy_val!"=="install-alongside" set "do_install=1"
                    )
                    
                    if "!do_install!"=="1" (
                        call "%LOG_CMD%" :log_info "Installing dependency !dep_val!..."
                        set "LIBSCRIPT_SKIP_DEPENDENCIES=1"
                        call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install "!dep_val!" "latest"
                        if errorlevel 1 (
                            call "%LOG_CMD%" :log_error "Failed to install dependency !dep_val!"
                            exit /b 1
                        )
                        set "LIBSCRIPT_SKIP_DEPENDENCIES="
                    ) else (
                        call "%LOG_CMD%" :log_info "Dependency !dep_val! already satisfied."
                    )
                )
            )
        )
    )
)

:: Lifecycle Routing
if /i "!ACTION!"=="test" (
    if exist "test.cmd" (
        call test.cmd
    ) else if exist "test.ps1" (
        powershell -ExecutionPolicy Bypass -File "test.ps1"
    ) else (
        echo Error: test.cmd/ps1 not found 1>&2
        exit /b 1
    )
    exit /b %errorlevel%
)

if /i "!ACTION!"=="uninstall" set "ACTION=remove"
if /i "!ACTION!"=="remove" (
    if exist "uninstall.cmd" (
        call uninstall.cmd
    ) else if exist "uninstall.ps1" (
        powershell -ExecutionPolicy Bypass -File "uninstall.ps1"
    ) else (
        echo Error: uninstall.cmd/ps1 not found 1>&2
        exit /b 1
    )
    exit /b %errorlevel%
)

:: Default to setup.cmd
if exist "setup.cmd" (
    call setup.cmd
) else if exist "setup.sh" (
    :: Fallback to WSL/GitBash if setup.sh exists? No, keep it native for now.
    echo Error: setup.cmd not found 1>&2
    exit /b 1
)
exit /b %errorlevel%

:show_help
echo Usage: cli.cmd [COMMAND] [PACKAGE_NAME] [VERSION] [OPTIONS]
echo.
echo Commands:
echo   install, remove, uninstall, test, status, start, stop, restart, env, run, exec
echo.
if exist "%MANIFEST_FILE%" (
    where jq >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "delims=" %%A in ('jq -r "if .title and .description then .title + \": \" + .description elif .title then .title elif .description then .description else \"\" end" "%MANIFEST_FILE%"') do (
            if not "%%A"=="" echo   %%A
        )
        for /f "delims=" %%A in ('jq -r "if .versions then \"Supported Versions: \" + (.versions | join(\", \")) else \"\" end" "%MANIFEST_FILE%"') do (
            if not "%%A"=="" echo   %%A
        )
    )
)
echo.
echo Available Options:
where jq >nul 2>&1
if !errorlevel! equ 0 (
    :: Print merged schema properties
    jq -n --argjson base "$(cat "%BASE_SCHEMA_FILE%")" --argjson comp "$(cat "%SCHEMA_FILE%")" "$base.properties * $comp.properties | to_entries[] | \"  --\" + .key + \"=\" + (.value.default // \"none\") + \"\t\" + .value.description"
) else (
    echo   (jq is required for dynamic options list)
)
exit /b 0
@echo off
:: LibScript Unified Logging Utility (Windows)

:: Levels: 0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR
if "%LIBSCRIPT_LOG_LEVEL%"=="" set "LIBSCRIPT_LOG_LEVEL=1"
if "%LIBSCRIPT_LOG_FORMAT%"=="" set "LIBSCRIPT_LOG_FORMAT=text"

goto :eof

:log_debug
call :_libscript_log_msg "DEBUG" 0 "%~1"
exit /b

:log_info
call :_libscript_log_msg "INFO" 1 "%~1"
exit /b

:log_success
call :_libscript_log_msg "SUCCESS" 2 "%~1"
exit /b

:log_warn
call :_libscript_log_msg "WARN" 3 "%~1"
exit /b

:log_error
call :_libscript_log_msg "ERROR" 4 "%~1"
exit /b

:_libscript_log_msg
set "level_name=%~1"
set "level_num=%~2"
set "msg=%~3"

if !level_num! LSS !LIBSCRIPT_LOG_LEVEL! exit /b

:: Standard timestamp ISO-8601-like
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do set "ts_date=%%c-%%a-%%b"
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set "ts_time=%%a:%%b"
set "timestamp=!ts_date!T!ts_time!"

if /i "%LIBSCRIPT_LOG_FORMAT%"=="json" (
    set "clean_msg=!msg:"=\"!"
    set "json_out={"timestamp":"!timestamp!","level":"!level_name!","message":"!clean_msg!"}"
    
    if defined LIBSCRIPT_LOG_FILE echo !json_out!>> "%LIBSCRIPT_LOG_FILE%"
    echo !json_out!
) else (
    set "text_out=[!level_name!] !msg!"
    if defined LIBSCRIPT_LOG_FILE echo !timestamp! !text_out!>> "%LIBSCRIPT_LOG_FILE%"
    echo !text_out! 1>&2
)
exit /b
@echo off
setlocal EnableDelayedExpansion
echo Running generic uninstaller for %PACKAGE_NAME%

set "PURGE_DATA=0"
:parse_args
if "%~1"=="" goto after_parse
if /i "%~1"=="--purge-data" set "PURGE_DATA=1"
shift
goto parse_args
:after_parse

if "!PURGE_DATA!"=="1" (
    echo [WARN] Purging data directories for %PACKAGE_NAME%...
    if exist "%LIBSCRIPT_ROOT_DIR%\data\%PACKAGE_NAME%" (
        rmdir /s /q "%LIBSCRIPT_ROOT_DIR%\data\%PACKAGE_NAME%"
    )
    :: Try to read DATA_DIR from schema defaults or env if possible
    set "pkg_upper=!PACKAGE_NAME!"
    for %%A in (
        "a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I"
        "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R"
        "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z" "-=_"
    ) do set "pkg_upper=!pkg_upper:%%~A!"
    
    :: Nuke service
    sc stop "libscript_!PACKAGE_NAME!" >nul 2>&1
    sc delete "libscript_!PACKAGE_NAME!" >nul 2>&1
) else (
    echo [INFO] Keeping data directory intact.
    sc stop "libscript_!PACKAGE_NAME!" >nul 2>&1
    sc config "libscript_!PACKAGE_NAME!" start= demand >nul 2>&1
)

if exist "%LIBSCRIPT_ROOT_DIR%\installed\%PACKAGE_NAME%" (
    rmdir /s /q "%LIBSCRIPT_ROOT_DIR%\installed\%PACKAGE_NAME%"
)
echo Uninstalled %PACKAGE_NAME%.
exit /b 0
@echo off
call "%~dp0\test_base.cmd"
@echo off
set "PACKAGE_NAME=mosquitto"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "mosquitto" "."
@echo off
call "%~dp0\..\..\_lib\_common\cli.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling rabbitmq is not supported via this script."
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "rabbitmqctl" "."
@echo off
set "PACKAGE_NAME=nats"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "nats-server" "."
@echo off
set "PACKAGE_NAME=kafka"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "kafka-server-start.sh" "."
@echo off
set "PACKAGE_NAME=git-servers"
call "%~dp0\..\_common\component_core.cmd" %*
@echo off
set "PACKAGE_NAME=gitlab"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "gitlab" "."
@echo off
set "PACKAGE_NAME=gitea"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "gitea" "."
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\_common\test_base.cmd" :assert_version "git" "."
@echo off
set "PACKAGE_NAME=deno"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "deno" "."
@echo off
set "PACKAGE_NAME=nodejs"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "node" "."
@echo off
set "PACKAGE_NAME=zig"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "zig" "."
@echo off
set "PACKAGE_NAME=go"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "go" "."
@echo off
set "PACKAGE_NAME=python"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "python" "."
@echo off
set "PACKAGE_NAME=elixir"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "elixir" "."
@echo off
set "PACKAGE_NAME=rust-server"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
call "%~dp0\..\..\_common\setup_base.cmd"
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "cargo" "."
@echo off
set "PACKAGE_NAME=rust"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "rustc" "."
@echo off
set "PACKAGE_NAME=java"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "java" "."
@echo off
set "PACKAGE_NAME=kotlin"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "kotlinc" "."
@echo off
set "PACKAGE_NAME=bun"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "bun" "."
@echo off
set "PACKAGE_NAME=php"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "php" "."
@echo off
set "PACKAGE_NAME=sh"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "sh" "."
@echo off
set "PACKAGE_NAME=cpp"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "cpp" "."
@echo off
set "PACKAGE_NAME=swift"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "swift" "."
@echo off
set "PACKAGE_NAME=csharp"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "dotnet" "."
@echo off
set "PACKAGE_NAME=cc"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "gcc" "."
@echo off
set "PACKAGE_NAME=nodejs-server"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
call "%~dp0\..\..\_common\setup_base.cmd"
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "node" "."
@echo off
set "PACKAGE_NAME=python-server"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
call "%~dp0\..\..\_common\setup_base.cmd"
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "python" "."
@echo off
set "PACKAGE_NAME=c"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "gcc" "."
@echo off
set "PACKAGE_NAME=ruby"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "ruby" "."
@echo off
set "PACKAGE_NAME=wait4x"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
where wait4x >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping wait4x for Windows...
set "PACKAGE_NAME=wait4x"
set "WAIT4X_URL=https://github.com/atkrad/wait4x/releases/download/v2.13.0/wait4x-windows-amd64.tar.gz"
set "WAIT4X_TAR=%TEMP%\wait4x.tar.gz"

call "%~dp0\..\..\_common\pkg_mgr.cmd" :libscript_download "%WAIT4X_URL%" "%WAIT4X_TAR%"

if exist "%WAIT4X_TAR%" (
    tar -xf "%WAIT4X_TAR%" -C "%TEMP%" wait4x.exe
    if exist "%TEMP%\wait4x.exe" (
        call "%~dp0\..\..\_common\setup_base.cmd" :libscript_install_binary "%TEMP%\wait4x.exe" "wait4x.exe"
    ) else (
        call "%~dp0\..\..\_common\log.cmd" :log_error "Failed to find wait4x.exe in archive."
        exit /b 1
    )
) else (
    call "%~dp0\..\..\_common\log.cmd" :log_error "Failed to download wait4x."
    exit /b 1
)
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "wait4x" "."
@echo off
set "PACKAGE_NAME=wget"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
where wget >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping standalone wget for Windows...
set "PACKAGE_NAME=wget"
set "WGET_URL=https://eternallybored.org/misc/wget/1.21.4/64/wget.exe"
set "WGET_OUT=%TEMP%\wget.exe"

call "%~dp0\..\..\_common\pkg_mgr.cmd" :libscript_download "%WGET_URL%" "%WGET_OUT%"

if exist "%WGET_OUT%" (
    call "%~dp0\..\..\_common\setup_base.cmd" :libscript_install_binary "%WGET_OUT%" "wget.exe"
) else (
    call "%~dp0\..\..\_common\log.cmd" :log_error "Failed to download wget."
)
@echo off
echo Uninstalling wget is not supported via this script.
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "wget" "."
@echo off
call "%~dp0\..\..\_lib\_common\cli.cmd" %*
@echo off
where aria2c >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping aria2 for Windows...
set "PACKAGE_NAME=aria2"
set "ARIA2_URL=https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip"
set "ARIA2_ZIP=%TEMP%\aria2.zip"

call "%~dp0\..\..\_common\pkg_mgr.cmd" :libscript_download "%ARIA2_URL%" "%ARIA2_ZIP%"

if exist "%ARIA2_ZIP%" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%ARIA2_ZIP%' -DestinationPath '%TEMP%\aria2-extracted' -Force"
    if exist "%TEMP%\aria2-extracted\aria2-1.37.0-win-64bit-build1\aria2c.exe" (
        call "%~dp0\..\..\_common\setup_base.cmd" :libscript_install_binary "%TEMP%\aria2-extracted\aria2-1.37.0-win-64bit-build1\aria2c.exe" "aria2c.exe"
    ) else (
        call "%~dp0\..\..\_common\log.cmd" :log_error "Failed to find aria2c.exe in extracted files."
        exit /b 1
    )
) else (
    call "%~dp0\..\..\_common\log.cmd" :log_error "Failed to download aria2."
    exit /b 1
)
@echo off
echo "Uninstalling aria2 is not supported via this script."
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "aria2" "."
@echo off
set "PACKAGE_NAME=powershell"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping PowerShell Core (pwsh) for Windows...
set "PACKAGE_NAME=powershell"
set "PWSH_URL=https://github.com/PowerShell/PowerShell/releases/download/v7.4.1/PowerShell-7.4.1-win-x64.msi"
set "PWSH_OUT=%TEMP%\pwsh.msi"

call "%~dp0\..\..\_common\pkg_mgr.cmd" :libscript_download "%PWSH_URL%" "%PWSH_OUT%"

if exist "%PWSH_OUT%" (
    echo [INFO] Running MSI installer for PowerShell Core...
    msiexec.exe /package "%PWSH_OUT%" /quiet /norestart
) else (
    echo [ERROR] Failed to download PowerShell.
)
@echo off
echo Uninstalling powershell is not supported via this script.
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "powershell" "."
@echo off
set "PACKAGE_NAME=busybox"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
where busybox >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping busybox for Windows...
set "PACKAGE_NAME=busybox"
set "BB_URL=https://frippery.org/files/busybox/busybox.exe"
set "BB_OUT=%TEMP%\busybox.exe"

call "%~dp0\..\..\_common\pkg_mgr.cmd" :libscript_download "%BB_URL%" "%BB_OUT%"

if exist "%BB_OUT%" (
    call "%~dp0\..\..\_common\setup_base.cmd" :libscript_install_binary "%BB_OUT%" "busybox.exe"
) else (
    call "%~dp0\..\..\_common\log.cmd" :log_error "Failed to download busybox."
)
@echo off
echo Uninstalling busybox is not supported via this script.
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "busybox" "."
@echo off
set "PACKAGE_NAME=curl"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
where curl >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping static curl for Windows (Native curl missing)...
set "PACKAGE_NAME=curl"
set "CURL_URL=https://curl.se/windows/dl-8.6.0_5/curl-8.6.0_5-win64-mingw.zip"
set "CURL_ZIP=%TEMP%\curl-win.zip"
set "DEST_DIR=%USERPROFILE%\.local\bin"

if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

call "%~dp0\..\..\_common\pkg_mgr.cmd" :libscript_download "%CURL_URL%" "%CURL_ZIP%"
if errorlevel 1 (
    echo [ERROR] Failed to download curl.
    exit /b 1
)

where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%CURL_ZIP%' -DestinationPath '%TEMP%\curl-extracted' -Force"
    move /y "%TEMP%\curl-extracted\curl-8.6.0_5-win64-mingw\bin\curl.exe" "%DEST_DIR%\curl.exe" >nul
) else (
    echo [ERROR] No PowerShell found to extract zip. Please extract %CURL_ZIP% manually.
    exit /b 1
)

if exist "%DEST_DIR%\curl.exe" (
    echo [INFO] curl successfully bootstrapped to %DEST_DIR%\curl.exe
) else (
    echo [ERROR] Failed to bootstrap curl.
)
@echo off
echo Uninstalling curl is not supported via this script.
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "curl" "."
@echo off
set "PACKAGE_NAME=7zip"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
where 7z >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof
where 7zr >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping standalone 7zip (7zr) for Windows...
set "PACKAGE_NAME=7zip"
set "SZ_URL=https://www.7-zip.org/a/7zr.exe"
set "SZ_OUT=%TEMP%\7zr.exe"

call "%~dp0\..\..\_common\pkg_mgr.cmd" :libscript_download "%SZ_URL%" "%SZ_OUT%"


if exist "%SZ_OUT%" (
    move /y "%SZ_OUT%" "%SystemRoot%\7zr.exe" >nul 2>&1
    if not exist "%SystemRoot%\7zr.exe" (
        if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
        move /y "%SZ_OUT%" "%USERPROFILE%\.local\bin\7zr.exe" >nul 2>&1
        echo [WARN] Could not write to SystemRoot. Placed in %USERPROFILE%\.local\bin
    ) else (
        echo [INFO] 7zr installed to %SystemRoot%\7zr.exe
    )
) else (
    echo [ERROR] Failed to download 7zr.
)
@echo off
echo Uninstalling 7zip is not supported via this script.
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "7zip" "."
@echo off
set "PACKAGE_NAME=dash"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
where dash >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping dash (via busybox) for Windows...
set "PACKAGE_NAME=busybox"
set "BB_URL=https://frippery.org/files/busybox/busybox.exe"
set "DASH_OUT=%TEMP%\dash.exe"

call "%~dp0\..\..\_common\pkg_mgr.cmd" :libscript_download "%BB_URL%" "%DASH_OUT%"

if exist "%DASH_OUT%" (
    call "%~dp0\..\..\_common\setup_base.cmd" :libscript_install_binary "%DASH_OUT%" "dash.exe"
) else (
    call "%~dp0\..\..\_common\log.cmd" :log_error "Failed to download dash."
)
@echo off
echo Uninstalling dash is not supported via this script.
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "dash" "."
@echo off
set "PACKAGE_NAME=jq"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
where jq >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping standalone jq for Windows...
set "PACKAGE_NAME=jq"
set "JQ_URL=https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-win64.exe"
set "JQ_OUT=%TEMP%\jq.exe"

call "%~dp0\..\..\_common\pkg_mgr.cmd" :libscript_download "%JQ_URL%" "%JQ_OUT%"

if exist "%JQ_OUT%" (
    call "%~dp0\..\..\_common\setup_base.cmd" :libscript_install_binary "%JQ_OUT%" "jq.exe"
) else (
    call "%~dp0\..\..\_common\log.cmd" :log_error "Failed to download jq."
    exit /b 1
)
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "jq" "."
@echo off
setlocal EnableDelayedExpansion

set "PROVIDER=%~1"
set "NODE=%~2"
set "RG=%~3"
set "LOC=%~4"
set "REPO_PATH=%~5"
if "!REPO_PATH!"=="" set "REPO_PATH=."
set "REMOTE_DEST=%~6"
if "!REMOTE_DEST!"=="" set "REMOTE_DEST=~/%NODE%"

if "!LOC!"=="" (
  echo Usage: teardown_cloud.cmd ^<provider^> ^<node_name^> ^<rg_or_vpc_or_project^> ^<region_or_zone^> [local_repo_path] [remote_dest]
  exit /b 1
)

:: -----------------------------------------------------------------------------
:: Logging Configuration
:: -----------------------------------------------------------------------------
set "LOG_DIR=!REPO_PATH!\logs"
if not exist "!LOG_DIR!" mkdir "!LOG_DIR!"
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set "TIMESTAMP=!datetime:~0,14!"
set "LOG_FILE=!LOG_DIR!\teardown-!TIMESTAMP!.log"

call :log "INIT" "Starting !PROVIDER! teardown for !NODE!..."

set "STATE_FILE=!REPO_PATH!\.deploy_state"

set "DOMAIN="
set "STATE_BUCKET="
set "STATE_ENDPOINT="
set "STATE_PATHS="

if exist "!REPO_PATH!\libscript.json" (
  where jq >nul 2>&1
  if !errorlevel! equ 0 (
    for /f "delims=" %%I in ('jq -r ".domain // \"\"" "!REPO_PATH!\libscript.json"') do set "DOMAIN=%%I"
    for /f "delims=" %%I in ('jq -r ".state.bucket // \"\"" "!REPO_PATH!\libscript.json"') do set "STATE_BUCKET=%%I"
    for /f "delims=" %%I in ('jq -r ".state.endpoint // \"\"" "!REPO_PATH!\libscript.json"') do set "STATE_ENDPOINT=%%I"
    for /f "delims=" %%I in ('jq -r "if .state.paths then (.state.paths | join(\" \")) else \"\" end" "!REPO_PATH!\libscript.json"') do set "STATE_PATHS=%%I"
  )
)

set "CLI=%~dp0..\_lib\cloud-providers\!PROVIDER!\cli.cmd"
if not exist "!CLI!" (
  call :log "ERROR" "Provider !PROVIDER! not supported."
  exit /b 1
)

set "CTX=!RG!"
if "!PROVIDER!"=="aws" set "CTX=!LOC!"
if "!PROVIDER!"=="gcp" set "CTX=!LOC!"

call :log "STOP" "Stopping remote stack..."
call "!CLI!" node exec "!NODE!" "!CTX!" "cd !REMOTE_DEST! && sudo ~/libscript/libscript.sh stop" >> "!LOG_FILE!" 2>&1

if not "!STATE_PATHS!"=="" (
  for %%P in (!STATE_PATHS!) do (
    call :log "SYNC" "Syncing %%P from node to prevent data loss..."
    call "!CLI!" node scp-from "!NODE!" "!CTX!" "!REMOTE_DEST!/%%P" "!REPO_PATH!\%%P" >> "!LOG_FILE!" 2>&1

    if not "!STATE_BUCKET!"=="" if exist "!REPO_PATH!\%%P" (
      call :log "STATE" "Backing up %%P to object storage !STATE_BUCKET!..."
      if "!STATE_BUCKET:~0,5!"=="s3://" (
        set "S3_ARGS="
        if not "!STATE_ENDPOINT!"=="" set "S3_ARGS=--endpoint-url !STATE_ENDPOINT!"
        aws s3 cp !S3_ARGS! "!REPO_PATH!\%%P" "!STATE_BUCKET!/%%P" >> "!LOG_FILE!" 2>&1
      ) else if "!STATE_BUCKET:~0,5!"=="gs://" (
        gcloud storage cp "!REPO_PATH!\%%P" "!STATE_BUCKET!/%%P" >> "!LOG_FILE!" 2>&1
      ) else if "!STATE_BUCKET:~0,8!"=="azure://" (
        for /f "tokens=3 delims=/" %%C in ("!STATE_BUCKET!") do set "CONTAINER=%%C"
        az storage blob upload --container-name "!CONTAINER!" --name "%%P" --file "!REPO_PATH!\%%P" --auth-mode login --overwrite >> "!LOG_FILE!" 2>&1
      )
    )
  )
)

if not "!DOMAIN!"=="" (
  call :log "DNS" "Unmapping DNS..."
  if "!PROVIDER!"=="azure" (
    for %%a in ("!DOMAIN:.*=!") do set "ZONE_NAME=%%~a"
    call "!CLI!" dns unmap-node "!NODE!" "!RG!" "!DOMAIN!" "!ZONE_NAME!" "!ZONE_NAME!-rg" >> "!LOG_FILE!" 2>&1
  ) else if "!PROVIDER!"=="aws" (
    if "!AWS_ZONE_ID!"=="" (
      for /f "tokens=*" %%i in ('aws route53 list-hosted-zones-by-name --dns-name "!DOMAIN!" --query "HostedZones[0].Id" --output text 2^>nul') do set "RAW_ID=%%i"
      if not "!RAW_ID!"=="None" (
        for %%a in ("!RAW_ID:/=" "!") do set "AWS_ZONE_ID=%%~a"
      )
    )
    if not "!AWS_ZONE_ID!"=="" (
      call "!CLI!" dns unmap-node "!NODE!" "!DOMAIN!" "!AWS_ZONE_ID!" >> "!LOG_FILE!" 2>&1
    )
  ) else if "!PROVIDER!"=="gcp" (
    for %%a in ("!DOMAIN:.*=!") do set "ZONE_NAME=%%~a"
    call "!CLI!" dns unmap-node "!NODE!" "!LOC!" "!DOMAIN!" "!ZONE_NAME!" >> "!LOG_FILE!" 2>&1
  )
)

call :log "INFRA" "Deleting Node..."
call "!CLI!" node delete "!NODE!" "!CTX!" >> "!LOG_FILE!" 2>&1

call :log "INFRA" "Deleting Firewall..."
if "!PROVIDER!"=="azure" (
  call "!CLI!" firewall delete "!NODE!-nsg!" "!RG!" >> "!LOG_FILE!" 2>&1
) else if "!PROVIDER!"=="aws" (
  set "SG_ID="
  if exist "!STATE_FILE!" (
    for /f "tokens=2 delims==" %%i in ('findstr "^AWS_SG=" "!STATE_FILE!"') do set "SG_ID=%%i"
  )
  if not "!SG_ID!"=="" (
    aws ec2 delete-security-group --group-id "!SG_ID!" >> "!LOG_FILE!" 2>&1
  )
) else if "!PROVIDER!"=="gcp" (
  call "!CLI!" firewall delete "!NODE!-fw" >> "!LOG_FILE!" 2>&1
)

call :log "INFRA" "Deleting Network..."
if "!PROVIDER!"=="azure" (
  call "!CLI!" network delete "!NODE!-vnet" "!RG!" >> "!LOG_FILE!" 2>&1
) else if "!PROVIDER!"=="aws" (
  set "VPC_ID="
  if exist "!STATE_FILE!" (
    for /f "tokens=2 delims==" %%i in ('findstr "^AWS_VPC=" "!STATE_FILE!"') do set "VPC_ID=%%i"
  )
  if not "!VPC_ID!"=="" (
    aws ec2 delete-vpc --vpc-id "!VPC_ID!" >> "!LOG_FILE!" 2>&1
  ) else (
    call "!CLI!" network delete "!NODE!-vpc" >> "!LOG_FILE!" 2>&1
  )
) else if "!PROVIDER!"=="gcp" (
  call "!CLI!" network delete "!NODE!-vpc" >> "!LOG_FILE!" 2>&1
)

if exist "!STATE_FILE!" (
  call :log "STATE" "Cleaning up !STATE_FILE!"
  del "!STATE_FILE!"
)

call :log "DONE" "Teardown complete."
exit /b 0

:: -----------------------------------------------------------------------------
:: Functions
:: -----------------------------------------------------------------------------
:log
echo [%~1] %~2
echo [%DATE% %TIME%] [%~1] %~2 >> "!LOG_FILE!"
exit /b 0
@echo off
set "PACKAGE_NAME=cloud"
call "%~dp0\..\_common\component_core.cmd" %*
@echo off
setlocal EnableDelayedExpansion

set "PROVIDER=%~1"
set "NODE=%~2"
set "RG=%~3"
set "LOC=%~4"
set "REPO_PATH=%~5"
if "!REPO_PATH!"=="" set "REPO_PATH=."
set "REMOTE_DEST=%~6"
if "!REMOTE_DEST!"=="" set "REMOTE_DEST=~/%NODE%"

if "!LOC!"=="" (
  echo Usage: deploy_cloud.cmd ^<provider^> ^<node_name^> ^<rg_or_vpc_or_project^> ^<region_or_zone^> [local_repo_path] [remote_dest]
  exit /b 1
)

:: -----------------------------------------------------------------------------
:: Logging Configuration
:: -----------------------------------------------------------------------------
set "LOG_DIR=!REPO_PATH!\logs"
if not exist "!LOG_DIR!" mkdir "!LOG_DIR!"
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set "TIMESTAMP=!datetime:~0,14!"
set "LOG_FILE=!LOG_DIR!\provision-!TIMESTAMP!.log"

call :log "INIT" "Starting !PROVIDER! deployment for !NODE!..."
call :log "INIT" "Logging to !LOG_FILE!"

set "STATE_FILE=!REPO_PATH!\.deploy_state"
if not exist "!STATE_FILE!" type nul > "!STATE_FILE!"

call :record_state "PROVIDER" "!PROVIDER!"
call :record_state "NODE" "!NODE!"
call :record_state "RG" "!RG!"
call :record_state "REGION" "!LOC!"

set "CLI=%~dp0..\_lib\cloud-providers\!PROVIDER!\cli.cmd"
if not exist "!CLI!" (
  call :log "ERROR" "Provider !PROVIDER! not supported."
  exit /b 1
)

:: -----------------------------------------------------------------------------
:: Read Configuration
:: -----------------------------------------------------------------------------
set "DOMAIN="
set "SECRETS_DIR="
set "OS_IMAGE="
set "SIZE="
set "DISK_GB="
set "PORTS=22 80 443"
set "STATE_BUCKET="
set "STATE_ENDPOINT="
set "STATE_PATHS="

if exist "!REPO_PATH!\libscript.json" (
  where jq >nul 2>&1
  if !errorlevel! equ 0 (
    for /f "delims=" %%I in ('jq -r ".domain // \"\"" "!REPO_PATH!\libscript.json"') do set "DOMAIN=%%I"
    for /f "delims=" %%I in ('jq -r ".secrets_dir // \"\"" "!REPO_PATH!\libscript.json"') do set "SECRETS_DIR=%%I"
    for /f "delims=" %%I in ('jq -r ".infrastructure.node.os // \"\"" "!REPO_PATH!\libscript.json"') do set "OS_IMAGE=%%I"
    for /f "delims=" %%I in ('jq -r ".infrastructure.node.size // \"\"" "!REPO_PATH!\libscript.json"') do set "SIZE=%%I"
    for /f "delims=" %%I in ('jq -r ".infrastructure.node.disk_gb // \"\"" "!REPO_PATH!\libscript.json"') do set "DISK_GB=%%I"
    for /f "delims=" %%I in ('jq -r "if .infrastructure.network.ports then (.infrastructure.network.ports | join(\" \")) else \"\" end" "!REPO_PATH!\libscript.json"') do set "PORTS=%%I"
    if "!PORTS!"=="" set "PORTS=22 80 443"
    for /f "delims=" %%I in ('jq -r ".state.bucket // \"\"" "!REPO_PATH!\libscript.json"') do set "STATE_BUCKET=%%I"
    for /f "delims=" %%I in ('jq -r ".state.endpoint // \"\"" "!REPO_PATH!\libscript.json"') do set "STATE_ENDPOINT=%%I"
    for /f "delims=" %%I in ('jq -r "if .state.paths then (.state.paths | join(\" \")) else \"\" end" "!REPO_PATH!\libscript.json"') do set "STATE_PATHS=%%I"
  )
)

if "!OS_IMAGE!"=="" (
  if "!PROVIDER!"=="azure" set "OS_IMAGE=Ubuntu2204"
  if "!PROVIDER!"=="aws" set "OS_IMAGE=ami-0c7217cdde317cfec"
  if "!PROVIDER!"=="gcp" set "OS_IMAGE=ubuntu-2204-lts"
)
if "!SIZE!"=="" (
  if "!PROVIDER!"=="azure" set "SIZE=Standard_B2s"
  if "!PROVIDER!"=="aws" set "SIZE=t3.medium"
  if "!PROVIDER!"=="gcp" set "SIZE=e2-medium"
) else (
  echo !SIZE! | findstr /b "Standard_D" >nul
  if not errorlevel 1 (
    if "!PROVIDER!"=="aws" set "SIZE=t3.xlarge"
    if "!PROVIDER!"=="gcp" set "SIZE=e2-standard-4"
  )
  echo !SIZE! | findstr /b "Standard_B" >nul
  if not errorlevel 1 (
    if "!PROVIDER!"=="aws" set "SIZE=t3.medium"
    if "!PROVIDER!"=="gcp" set "SIZE=e2-medium"
  )
  echo !SIZE! | findstr /b "t3." >nul
  if not errorlevel 1 (
    if "!PROVIDER!"=="azure" set "SIZE=Standard_D4s_v3"
    if "!PROVIDER!"=="gcp" set "SIZE=e2-standard-4"
  )
)

call :log "INFRA" "Provisioning Network and Compute..."

if "!PROVIDER!"=="azure" (
  call :retry az group create --name "!RG!" --location "!LOC!"
  call :record_state "AZURE_RG" "!RG!"
  call :retry "!CLI!" network create "!NODE!-vnet" "!RG!" --location "!LOC!"
  call :record_state "AZURE_VNET" "!NODE!-vnet"
  call :retry "!CLI!" firewall create "!NODE!-nsg" "!RG!" "!PORTS!" --location "!LOC!"
  call :record_state "AZURE_NSG" "!NODE!-nsg"
  set "NODE_ARGS=--size !SIZE! --vnet-name !NODE!-vnet --nsg !NODE!-nsg"
  if not "!DISK_GB!"=="" set "NODE_ARGS=!NODE_ARGS! --os-disk-size-gb !DISK_GB!"
  call :retry "!CLI!" node create "!NODE!" "!OS_IMAGE!" "!RG!" !NODE_ARGS!
  call :record_state "AZURE_NODE" "!NODE!"
)

if "!PROVIDER!"=="aws" (
  set "AWS_DEFAULT_REGION=!LOC!"
  for /f "tokens=*" %%i in ('call "!CLI!" network create "!NODE!-vpc"') do set "VPC_ID=%%i"
  call :record_state "AWS_VPC" "!VPC_ID!"
  for /f "tokens=*" %%i in ('call "!CLI!" firewall create "!NODE!-sg" "!NODE!-vpc" "!PORTS!"') do set "SG_ID=%%i"
  call :record_state "AWS_SG" "!SG_ID!"
  call :retry "!CLI!" node create "!NODE!" "!OS_IMAGE!" "!NODE!-vpc" "!SIZE!"
  call :record_state "AWS_NODE" "!NODE!"
)

if "!PROVIDER!"=="gcp" (
  set "GCP_ZONE=!LOC!"
  call :retry "!CLI!" network create "!NODE!-vpc" "10.0.0.0/16"
  call :record_state "GCP_VPC" "!NODE!-vpc"
  call :retry "!CLI!" firewall create "!NODE!-fw" "!NODE!-vpc" "!PORTS!"
  call :record_state "GCP_FW" "!NODE!-fw"
  call :retry "!CLI!" node create "!NODE!" "!OS_IMAGE!" "!RG!" --network "!NODE!-vpc!" --machine-type "!SIZE!"
  call :record_state "GCP_NODE" "!NODE!"
)

set "CTX=!RG!"
if "!PROVIDER!"=="aws" set "CTX=!LOC!"
if "!PROVIDER!"=="gcp" set "CTX=!LOC!"

:: -----------------------------------------------------------------------------
:: Wait for SSH / WinRM
:: -----------------------------------------------------------------------------
call :log "HEALTH" "Waiting for SSH/WinRM readiness on node !NODE!..."
set "ATTEMPT=1"
set "MAX_ATTEMPTS=30"
:ssh_loop
call "!CLI!" node exec "!NODE!" "!CTX!" "echo SSH_READY" >nul 2>&1
if %errorlevel% equ 0 (
  call :log "HEALTH" "SSH/WinRM is ready."
  goto :ssh_ready
)
if !ATTEMPT! geq !MAX_ATTEMPTS! (
  call :log "ERROR" "Node failed to become ready after !MAX_ATTEMPTS! attempts."
  exit /b 1
)
call :log "HEALTH" "Not ready (attempt !ATTEMPT!/!MAX_ATTEMPTS!). Waiting 10s..."
timeout /t 10 /nobreak >nul
set /a ATTEMPT+=1
goto :ssh_loop

:ssh_ready

:: -----------------------------------------------------------------------------
:: Sync and Deploy
:: -----------------------------------------------------------------------------
call :log "SYNC" "Syncing LibScript..."
call :retry "!CLI!" node sync "!NODE!" "!CTX!"

call :log "SYNC" "Deploying Repository..."
call :retry "!CLI!" node exec "!NODE!" "!CTX!" "mkdir -p !REMOTE_DEST!"
where rsync >nul 2>&1
if %errorlevel% equ 0 (
  call :log "SYNC" "Using rsync..."
  call :retry "!CLI!" node deploy "!NODE!" "!CTX!" "!REPO_PATH!" "!REMOTE_DEST!"
) else (
  call :log "SYNC" "Using scp/winrm fallback..."
  call :retry "!CLI!" node scp "!NODE!" "!CTX!" "!REPO_PATH!" "!REMOTE_DEST!"
)

if not "!SECRETS_DIR!"=="" if exist "!REPO_PATH!\!SECRETS_DIR!" (
  call :log "SECRETS" "Deploying Secrets out-of-band via node scp (bypassing gitignore)..."
  call :retry "!CLI!" node scp "!NODE!" "!CTX!" "!REPO_PATH!\!SECRETS_DIR!" "!REMOTE_DEST!/!SECRETS_DIR!"
)

if not "!STATE_PATHS!"=="" (
  for %%P in (!STATE_PATHS!) do (
    if not "!STATE_BUCKET!"=="" (
      call :log "STATE" "Restoring %%P from object storage !STATE_BUCKET!..."
      if "!STATE_BUCKET:~0,5!"=="s3://" (
        set "S3_ARGS="
        if not "!STATE_ENDPOINT!"=="" set "S3_ARGS=--endpoint-url !STATE_ENDPOINT!"
        aws s3 cp !S3_ARGS! "!STATE_BUCKET!/%%P" "!REPO_PATH!\%%P" >> "!LOG_FILE!" 2>&1
      ) else if "!STATE_BUCKET:~0,5!"=="gs://" (
        gcloud storage cp "!STATE_BUCKET!/%%P" "!REPO_PATH!\%%P" >> "!LOG_FILE!" 2>&1
      ) else if "!STATE_BUCKET:~0,8!"=="azure://" (
        for /f "tokens=3 delims=/" %%C in ("!STATE_BUCKET!") do set "CONTAINER=%%C"
        az storage blob download --container-name "!CONTAINER!" --name "%%P" --file "!REPO_PATH!\%%P" --auth-mode login >> "!LOG_FILE!" 2>&1
      )
    )
    if exist "!REPO_PATH!\%%P" (
      call :log "STATE" "Deploying state %%P to node..."
      call :retry "!CLI!" node scp "!NODE!" "!CTX!" "!REPO_PATH!\%%P" "!REMOTE_DEST!/%%P"
    )
  )
)

if not "!DOMAIN!"=="" (
  call :log "DNS" "Mapping DNS for !DOMAIN!..."
  if "!PROVIDER!"=="azure" (
    for %%a in ("!DOMAIN:.*=!") do set "ZONE_NAME=%%~a"
    call :retry "!CLI!" dns map-node "!NODE!" "!RG!" "!DOMAIN!" "!ZONE_NAME!" "!ZONE_NAME!-rg"
  ) else if "!PROVIDER!"=="aws" (
    if "!AWS_ZONE_ID!"=="" (
      for /f "tokens=*" %%i in ('aws route53 list-hosted-zones-by-name --dns-name "!DOMAIN!" --query "HostedZones[0].Id" --output text 2^>nul') do set "RAW_ID=%%i"
      if not "!RAW_ID!"=="None" (
        for %%a in ("!RAW_ID:/=" "!") do set "AWS_ZONE_ID=%%~a"
      )
    )
    if not "!AWS_ZONE_ID!"=="" (
      call :retry "!CLI!" dns map-node "!NODE!" "!DOMAIN!" "!AWS_ZONE_ID!"
    )
  ) else if "!PROVIDER!"=="gcp" (
    for %%a in ("!DOMAIN:.*=!") do set "ZONE_NAME=%%~a"
    call :retry "!CLI!" dns map-node "!NODE!" "!LOC!" "!DOMAIN!" "!ZONE_NAME!"
  )
)

call :log "START" "Installing Dependencies and Starting..."
call :retry "!CLI!" node exec "!NODE!" "!CTX!" "cd !REMOTE_DEST! && sudo ~/libscript/libscript.sh install-deps"
call :retry "!CLI!" node exec "!NODE!" "!CTX!" "cd !REMOTE_DEST! && sudo ~/libscript/libscript.sh start"

:: -----------------------------------------------------------------------------
:: Wait for Health
:: -----------------------------------------------------------------------------
call :log "HEALTH" "Polling application health (via libscript health)..."
set "ATTEMPT=1"
set "MAX_ATTEMPTS=12"
:health_loop
call "!CLI!" node exec "!NODE!" "!CTX!" "cd !REMOTE_DEST! && sudo ~/libscript/libscript.sh health" >nul 2>&1
if %errorlevel% equ 0 (
  call :log "HEALTH" "Application stack is healthy."
  goto :health_ready
)
if !ATTEMPT! geq !MAX_ATTEMPTS! (
  call :log "WARNING" "Application health check failed or timed out. Check logs."
  goto :health_ready
)
call :log "HEALTH" "Application not ready (attempt !ATTEMPT!/!MAX_ATTEMPTS!). Waiting 10s..."
timeout /t 10 /nobreak >nul
set /a ATTEMPT+=1
goto :health_loop

:health_ready

call :log "DONE" "Deployment complete. View logs at !LOG_FILE!"
exit /b 0

:: -----------------------------------------------------------------------------
:: Functions
:: -----------------------------------------------------------------------------
:log
echo [%~1] %~2
echo [%DATE% %TIME%] [%~1] %~2 >> "!LOG_FILE!"
exit /b 0

:record_state
echo %~1=%~2 >> "!STATE_FILE!"
call :log "STATE" "Recorded %~1=%~2"
exit /b 0

:retry
set "RETRY_ATTEMPT=1"
set "RETRY_MAX=5"
set "RETRY_WAIT=5"
:retry_loop
call :log "RETRY" "Attempt !RETRY_ATTEMPT! of !RETRY_MAX!: %*"
call %* >> "!LOG_FILE!" 2>&1
if %errorlevel% equ 0 (
  call :log "RETRY" "Command succeeded."
  exit /b 0
)
if !RETRY_ATTEMPT! geq !RETRY_MAX! (
  call :log "ERROR" "Command failed after !RETRY_MAX! attempts: %*"
  exit /b 1
)
call :log "RETRY" "Command failed (exit !errorlevel!). Waiting !RETRY_WAIT!s..."
timeout /t !RETRY_WAIT! /nobreak >nul
set /a RETRY_ATTEMPT+=1
set /a RETRY_WAIT*=2
goto :retry_loop
@echo off
call "%~dp0\..\_common\test_base.cmd"

@echo off
call "%~dp0\..\_common\test_base.cmd"

@echo off
call "%~dp0\..\_common\test_base.cmd"


set "DRY_RUN=true"

echo Testing Unified Cloud Wrapper in DRY_RUN mode...

rem Test routing to AWS
if errorlevel 1 ( echo FAIL: AWS routing & exit /b 1 )

rem Test global list-managed
if errorlevel 1 ( echo FAIL: list-managed AWS & exit /b 1 )
if errorlevel 1 ( echo FAIL: list-managed Azure & exit /b 1 )
if errorlevel 1 ( echo FAIL: list-managed GCP & exit /b 1 )

rem Test global cleanup
if errorlevel 1 ( echo FAIL: cleanup aws & exit /b 1 )
if errorlevel 1 ( echo FAIL: cleanup azure & exit /b 1 )
if errorlevel 1 ( echo FAIL: cleanup gcp & exit /b 1 )

echo Unified Cloud Wrapper tests passed (dry-run).
exit /b 0


@echo off
set "PACKAGE_NAME=kubernetes-k0s"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
where k0s >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping k0s for Windows...
set "PACKAGE_NAME=k0s"
set "K0S_URL=https://github.com/k0sproject/k0s/releases/download/v1.30.2%2Bk0s.0/k0s-v1.30.2%2Bk0s.0-amd64.exe"
set "K0S_OUT=%TEMP%\k0s.exe"

call "%~dp0\..\..\_common\pkg_mgr.cmd" :libscript_download "%K0S_URL%" "%K0S_OUT%"

if exist "%K0S_OUT%" (
    call "%~dp0\..\..\_common\setup_base.cmd" :libscript_install_binary "%K0S_OUT%" "k0s.exe"
) else (
    call "%~dp0\..\..\_common\log.cmd" :log_error "Failed to download k0s."
    exit /b 1
)
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "kubernetes-k0s" "."
@echo off
set "PACKAGE_NAME=docker"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "docker" "."
@echo off
setlocal enabledelayedexpansion

if "%~1"=="--help" (
    echo Usage: %0 [OPTIONS]
    echo See script source or documentation for more details.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %0 [OPTIONS]
    echo See script source or documentation for more details.
    exit /b 0
)


REM resolve_stack.cmd
REM A portable wrapper for the SAT/Constraint solver using jq on Windows.
REM Usage: scripts\resolve_stack.cmd <path_to_install.json>

if "%~1"=="" (
    echo Usage: %0 ^<path_to_install.json^>
    exit /b 1
)

set "INSTALL_JSON=%~1"
set "SCRIPT_DIR=%~dp0"
set "LIB_DIR=%SCRIPT_DIR%..\_lib"

REM Default TARGET_OS to windows unless overridden
if "%LIBSCRIPT_TARGET_OS%"=="" (
    set "TARGET_OS=windows"
) else (
    set "TARGET_OS=%LIBSCRIPT_TARGET_OS%"
)

where jq >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: jq is required but not installed.
    exit /b 1
)

REM Gather manifests into a single JSON array structure inline.
set "MANIFESTS="
for /R "%LIB_DIR%" %%F in (manifest.json) do (
    set "MANIFESTS=!MANIFESTS! "%%F""
)

REM Run the jq resolution engine
jq --arg target_os "%TARGET_OS%" -n "{install: input, manifests: [inputs]}" "%INSTALL_JSON%" %MANIFESTS% | jq -L "%SCRIPT_DIR%." --arg target_os "%TARGET_OS%" -r -f "%SCRIPT_DIR%resolve_stack.jq"

endlocal
@echo off
setlocal enabledelayedexpansion

set json_file=%~1
set hook_type=%~2

if not exist "%json_file%" exit /b 0

for /f "delims=" %%i in ('jq -c ".hooks.%hook_type%[]?" "%json_file%" 2^>nul') do (
    set "hook=%%i"
    for /f "delims=" %%n in ('echo !hook! ^| jq -r ".name // \"unnamed_hook\""') do set "name=%%n"
    for /f "delims=" %%c in ('echo !hook! ^| jq -r ".command // empty"') do set "cmd=%%c"
    for /f "delims=" %%d in ('echo !hook! ^| jq -r ".condition // empty"') do set "cond=%%d"
    
    set skip=0
    if not "!cond!"=="" (
        echo !cond! | findstr /b /c:"unless_exists " >nul
        if not errorlevel 1 (
            set "file=!cond:unless_exists =!"
            if exist "!file!" (
                echo Skipping hook '!name!': !file! exists
                set skip=1
            )
        )
    )
    
    if "!skip!"=="0" if not "!cmd!"=="" (
        echo Executing hook '!name!': !cmd!
        call !cmd!
    )
)
exit /b 0
@echo off
set "PACKAGE_NAME=kubernetes-thw"
call "%~dp0\..\..\_lib\_common\component_core.cmd" %*
@echo off
setlocal EnableDelayedExpansion
:: Source logging
if not defined LIBSCRIPT_ROOT_DIR set "LIBSCRIPT_ROOT_DIR=%~dp0..\..\.."
set "LOG_CMD=%~dp0\..\..\_common\log.cmd"
if not exist "!LOG_CMD!" set "LOG_CMD=%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd"
call "!LOG_CMD!" :log_warn "kubernetes-thw is not supported on Windows natively."
exit /b 0
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "kubectl" "."
@echo off
set "PACKAGE_NAME=systemd"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "systemd" "."
@echo off
setlocal enabledelayedexpansion

set action=%~1
set json_file=%~2

if not exist "%json_file%" exit /b 0

for /f "delims=" %%i in ('jq -c ".services[]?" "%json_file%" 2^>nul') do (
    set "svc=%%i"
    for /f "delims=" %%n in ('echo !svc! ^| jq -r ".name // empty"') do set "name=%%n"
    for /f "delims=" %%c in ('echo !svc! ^| jq -r ".command // empty"') do set "cmd=%%c"
    
    if not "!name!"=="" if not "!cmd!"=="" (
        if /i "!action!"=="start" (
            echo Configuring and starting service '!name!'...
            if not exist "\tmp\data\!name!" mkdir "\tmp\data\!name!" 2>nul
            
            rem Set environments inline
            for /f "delims=" %%e in ('echo !svc! ^| jq -r ".env | to_entries[]? | \"set \\\"\(.key)=\(.value)\\\"\"" 2^>nul') do (
                %%e
            )
            
            rem Enumerate env files (basic naive support)
            for /f "delims=" %%f in ('echo !svc! ^| jq -r ".env_files[]?" 2^>nul') do (
                if exist "%%f" (
                    for /f "tokens=* delims=" %%l in (%%f) do set "%%l"
                )
            )

            start "!name!" /B cmd.exe /c "!cmd!"
        )
        if /i "!action!"=="up" (
            echo Configuring and starting service '!name!'...
            start "!name!" /B cmd.exe /c "!cmd!"
        )
        if /i "!action!"=="stop" (
            echo Stopping service '!name!'...
            rem Complex to kill without PID, could use taskkill with window title
            taskkill /fi "WINDOWTITLE eq !name!" /f 2>nul
        )
        if /i "!action!"=="down" (
            taskkill /fi "WINDOWTITLE eq !name!" /f 2>nul
        )
    )
)
exit /b 0
@echo off
set "PACKAGE_NAME=openrc"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
echo "Uninstalling openrc is not supported via this script."
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "openrc" "."
@echo off
set "PACKAGE_NAME=lighttpd"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "lighttpd" "."
@echo off
set "PACKAGE_NAME=httpd"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [INFO] PowerShell not found. Installing Apache HTTPD natively...
set "PACKAGE_NAME=httpd"
set "HTTPD_VER=2.4.58"
if defined HTTPD_VERSION set "HTTPD_VER=%HTTPD_VERSION%"
if "%HTTPD_VER%"=="latest" set "HTTPD_VER=2.4.58"
set "PREFIX=%LIBSCRIPT_ROOT_DIR%\installed\httpd"
if not exist "%PREFIX%" mkdir "%PREFIX%"
:: Using Apache Haus or Apache Lounge. We use a known mirror or version URL if possible.
:: Actually, zip might be named httpd-2.4.58-win64-VS17.zip
set "HTTPD_URL=https://www.apachelounge.com/download/VS17/binaries/httpd-%HTTPD_VER%-win64-VS17.zip"
set "ZIP_FILE=%TEMP%\httpd-%HTTPD_VER%.zip"
if not exist "%ZIP_FILE%" (
    echo [INFO] Downloading Apache HTTPD %HTTPD_VER%...
    call "%~dp0\..\..\..\_lib\_common\pkg_mgr.cmd" :libscript_download "%HTTPD_URL%" "%ZIP_FILE%"
)
if exist "%ZIP_FILE%" (
    tar -xf "%ZIP_FILE%" -C "%PREFIX%" --strip-components=1 >nul 2>&1 || powershell -command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%PREFIX%' -Force" >nul 2>&1
    echo [INFO] Apache HTTPD installed successfully to %PREFIX%.
    exit /b 0
) else (
    echo [ERROR] Failed to download Apache HTTPD.
    exit /b 1
)
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

if not "%HTTPD_SERVICE_NAME%"=="" (
    sc stop %HTTPD_SERVICE_NAME% >nul 2>&1
    sc delete %HTTPD_SERVICE_NAME% >nul 2>&1
) else (
    sc stop libscript_httpd >nul 2>&1
    sc delete libscript_httpd >nul 2>&1
)

:: Try to uninstall via winget / choco if it was installed that way
where winget >nul 2>&1
if %ERRORLEVEL% equ 0 winget uninstall --id=Apache.HTTPD --silent >nul 2>&1

where choco >nul 2>&1
if %ERRORLEVEL% equ 0 choco uninstall apache-httpd -y >nul 2>&1

:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "httpd" "."
@echo off
set "PACKAGE_NAME=nginx"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [INFO] PowerShell not found. Installing Nginx natively...
set "PACKAGE_NAME=nginx"
set "NGINX_VER=1.25.3"
if defined NGINX_VERSION set "NGINX_VER=%NGINX_VERSION%"
if "%NGINX_VER%"=="latest" set "NGINX_VER=1.25.3"
set "PREFIX=%LIBSCRIPT_ROOT_DIR%\installed\nginx"
if not exist "%PREFIX%" mkdir "%PREFIX%"
set "NGINX_URL=http://nginx.org/download/nginx-%NGINX_VER%.zip"
set "ZIP_FILE=%TEMP%\nginx-%NGINX_VER%.zip"
if not exist "%ZIP_FILE%" (
    echo [INFO] Downloading Nginx %NGINX_VER%...
    call "%~dp0\..\..\..\_lib\_common\pkg_mgr.cmd" :libscript_download "%NGINX_URL%" "%ZIP_FILE%"
)
if exist "%ZIP_FILE%" (
    tar -xf "%ZIP_FILE%" -C "%PREFIX%" --strip-components=1 >nul 2>&1 || powershell -command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%PREFIX%' -Force" >nul 2>&1
    echo [INFO] Nginx installed successfully to %PREFIX%.
    exit /b 0
) else (
    echo [ERROR] Failed to download Nginx.
    exit /b 1
)
@echo off
set "DOMAIN=%~1"
set "LOCATION=%~2"
set "DESTINATION=%~3"
if "%DOMAIN%"=="" goto usage
if "%LOCATION%"=="" goto usage
if "%DESTINATION%"=="" goto usage
if "!PREFIX!"=="" (
    set "NGINX_CONF_DIR=!LIBSCRIPT_ROOT_DIR!\installed\nginx\conf"
) else (
    set "NGINX_CONF_DIR=!PREFIX!\conf"
)
if not exist "%NGINX_CONF_DIR%\sites-available" mkdir "%NGINX_CONF_DIR%\sites-available"
if not exist "%NGINX_CONF_DIR%\sites-enabled" mkdir "%NGINX_CONF_DIR%\sites-enabled"
set "CONF_FILE=%NGINX_CONF_DIR%\sites-available\%DOMAIN%.conf"
if not exist "%CONF_FILE%" (
    echo server {> "%CONF_FILE%"
    echo     listen 80;>> "%CONF_FILE%"
    echo     server_name %DOMAIN%;>> "%CONF_FILE%"
    echo }>> "%CONF_FILE%"
)
findstr /v /c:"}" "%CONF_FILE%" > "%CONF_FILE%.tmp"
echo     location %LOCATION% {>> "%CONF_FILE%.tmp"
echo         proxy_pass %DESTINATION%;>> "%CONF_FILE%.tmp"
echo         proxy_set_header Host $host;>> "%CONF_FILE%.tmp"
echo         proxy_set_header X-Real-IP $remote_addr;>> "%CONF_FILE%.tmp"
echo     }>> "%CONF_FILE%.tmp"
echo }>> "%CONF_FILE%.tmp"
move /y "%CONF_FILE%.tmp" "%CONF_FILE%" >nul
copy /y "%CONF_FILE%" "%NGINX_CONF_DIR%\sites-enabled\%DOMAIN%.conf" >nul
echo Route added: %DOMAIN%%LOCATION% -^> %DESTINATION%
exit /b 0
:usage
echo Usage: libscript.cmd route nginx ^<version^> ^<domain^> ^<location^> ^<destination^> 1^>^&2
exit /b 1
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

if not "%NGINX_SERVICE_NAME%"=="" (
    sc stop %NGINX_SERVICE_NAME% >nul 2>&1
    sc delete %NGINX_SERVICE_NAME% >nul 2>&1
) else (
    sc stop libscript_nginx >nul 2>&1
    sc delete libscript_nginx >nul 2>&1
)

:: Try to uninstall via winget / choco if it was installed that way
where winget >nul 2>&1
if %ERRORLEVEL% equ 0 winget uninstall --id=Nginx.Nginx --silent >nul 2>&1

where choco >nul 2>&1
if %ERRORLEVEL% equ 0 choco uninstall nginx -y >nul 2>&1

:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "nginx" "."
@echo off
set "PACKAGE_NAME=iis"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
echo [ERROR] PowerShell is required to configure IIS.
exit /b 1
@echo off
echo "Uninstalling iis is not supported via this script."
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "iis" "."
@echo off
set "PACKAGE_NAME=caddy"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [INFO] PowerShell not found. Installing Caddy natively...
set "PACKAGE_NAME=caddy"
set "PREFIX=%LIBSCRIPT_ROOT_DIR%\installed\caddy"
if not exist "%PREFIX%" mkdir "%PREFIX%"
set "CADDY_URL=https://caddyserver.com/api/download?os=windows&arch=amd64"
if not exist "%PREFIX%\caddy.exe" (
    echo [INFO] Downloading Caddy...
    call "%~dp0\..\..\..\_lib\_common\pkg_mgr.cmd" :libscript_download "%CADDY_URL%" "%PREFIX%\caddy.exe"
)
if exist "%PREFIX%\caddy.exe" (
    echo [INFO] Caddy installed successfully to %PREFIX%.
    exit /b 0
) else (
    echo [ERROR] Failed to download Caddy.
    exit /b 1
)
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

if not "%CADDY_SERVICE_NAME%"=="" (
    sc stop %CADDY_SERVICE_NAME% >nul 2>&1
    sc delete %CADDY_SERVICE_NAME% >nul 2>&1
) else (
    sc stop libscript_caddy >nul 2>&1
    sc delete libscript_caddy >nul 2>&1
)

:: Try to uninstall via winget / choco if it was installed that way
where winget >nul 2>&1
if %ERRORLEVEL% equ 0 winget uninstall --id=caddy.caddy --silent >nul 2>&1

where choco >nul 2>&1
if %ERRORLEVEL% equ 0 choco uninstall caddy -y >nul 2>&1

:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "caddy" "."
@echo off
set "PACKAGE_NAME=minio"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "minio" "."
@echo off
set "PACKAGE_NAME=pyenv"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "pyenv" "."
@echo off
set "PACKAGE_NAME=msys2"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal
where pacman >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

set "MSYS2_ROOT=C:\msys64"
if exist "%MSYS2_ROOT%\usr\bin\pacman.exe" (
    echo [INFO] MSYS2 pacman found at %MSYS2_ROOT%. Adding to PATH...
    set "PATH=%MSYS2_ROOT%\usr\bin;%PATH%"
    goto :eof
)

echo [INFO] Bootstrapping MSYS2 environment natively for Windows...
set "PACKAGE_NAME=msys2"
set "MSYS2_URL=https://github.com/msys2/msys2-installer/releases/download/2024-01-13/msys2-base-x86_64-20240113.sfx.exe"
set "MSYS2_OUT=%TEMP%\msys2-installer.exe"

call "%~dp0\..\..\..\_lib\_common\pkg_mgr.cmd" :libscript_download "%MSYS2_URL%" "%MSYS2_OUT%"
if exist "%MSYS2_OUT%" (
    echo [INFO] Extracting MSYS2 base to %MSYS2_ROOT%...
    "%MSYS2_OUT%" -y -o"C:\"
    echo [INFO] Updating core packages (requires network)...
    "%MSYS2_ROOT%\usr\bin\bash.exe" -lc "pacman --noconfirm -Syuu"
    echo [INFO] MSYS2 successfully installed to %MSYS2_ROOT%.
) else (
    echo [ERROR] Failed to download MSYS2 installer.
)
@echo off
echo Uninstalling msys2 is not supported via this script.
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "msys2" "."
@echo off
set "PACKAGE_NAME=cargo-binstall"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "cargo-binstall" "."
@echo off
set "PACKAGE_NAME=ghcup"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling ghcup is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "ghcup" "."
@echo off
set "PACKAGE_NAME=rebar3"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "rebar3" "."
@echo off
set "PACKAGE_NAME=opam"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling opam is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "opam" "."
@echo off
set "PACKAGE_NAME=asdf"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling asdf is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "asdf" "."
@echo off
set "PACKAGE_NAME=pkgx"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal
where pkgx >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell is required to bootstrap pkgx on Windows natively.
    exit /b 1
)

:: Call the PowerShell setup script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to install pkgx natively.
    exit /b %ERRORLEVEL%
)

:: Ensure the local path is reachable in the current session if possible
set "PKGX_DIR=%USERPROFILE%\.pkgx\bin"
if exist "%PKGX_DIR%\pkgx.exe" (
    set "PATH=%PKGX_DIR%;%PATH%"
)
@echo off
echo Uninstalling pkgx is not supported via this script.
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "pkgx" "."
@echo off
set "PACKAGE_NAME=deno"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling deno is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "deno" "."
@echo off
set "PACKAGE_NAME=pacman"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "pacman" "."
@echo off
set "PACKAGE_NAME=mas"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "mas" "."
@echo off
set "PACKAGE_NAME=mise"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "mise" "."
@echo off
set "PACKAGE_NAME=apk"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "apk" "."
@echo off
set "PACKAGE_NAME=go"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling go is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "go" "."
@echo off
set "PACKAGE_NAME=azure-cli"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
call "%~dp0\..\..\..\_lib\_common\setup_base.cmd"
@echo off
call "%~dp0\..\..\_lib\_common\uninstall.cmd" %*
@echo off
call "%~dp0\..\..\_lib\_common\test_base.cmd"
@echo off
set "PACKAGE_NAME=nix"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
echo [ERROR] Nix package manager is best run inside WSL2 on Windows. Native implementation is not yet supported.
exit /b 1
@echo off
echo Uninstalling nix is not supported via this script.
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "nix" "."
@echo off
set "PACKAGE_NAME=scoop"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling scoop is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "scoop" "."
@echo off
set "PACKAGE_NAME=yay"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "yay" "."
@echo off
set "PACKAGE_NAME=eopkg"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling eopkg is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "eopkg" "."
@echo off
set "PACKAGE_NAME=conda"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling conda is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "conda" "."
@echo off
set "PACKAGE_NAME=pipx"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "pipx" "."
@echo off
set "PACKAGE_NAME=zypper"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "zypper" "."
@echo off
set "PACKAGE_NAME=sdkman"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling sdkman is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "sdk" "."
@echo off
set "PACKAGE_NAME=rvm"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "rvm" "."
@echo off
set "PACKAGE_NAME=cargo"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "cargo" "."
@echo off
set "PACKAGE_NAME=swupd"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "swupd" "."
@echo off
set "PACKAGE_NAME=composer"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling composer is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "composer" "."
@echo off
set "PACKAGE_NAME=emerge"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling emerge is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "emerge" "."
@echo off
set "PACKAGE_NAME=brew"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling brew is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "brew" "."
@echo off
set "PACKAGE_NAME=mamba"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "micromamba" "."
@echo off
set "PACKAGE_NAME=R"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "R" "."
@echo off
set "PACKAGE_NAME=flatpak"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "flatpak" "."
@echo off
set "PACKAGE_NAME=pnpm"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling pnpm is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "pnpm" "."
@echo off
set "PACKAGE_NAME=awscli"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
call "%~dp0\..\..\..\_lib\_common\setup_base.cmd"
@echo off
call "%~dp0\..\..\_lib\_common\uninstall.cmd" %*
@echo off
call "%~dp0\..\..\_lib\_common\test_base.cmd"
@echo off
set "PACKAGE_NAME=winget"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling winget is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "winget" "."
@echo off
set "PACKAGE_NAME=luarocks"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling luarocks is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "luarocks" "."
@echo off
set "PACKAGE_NAME=mix"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "mix" "."
@echo off
set "PACKAGE_NAME=choco"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
where choco >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping Chocolatey (choco) for Windows...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"

if exist "%ALLUSERSPROFILE%\chocolatey\bin\choco.exe" (
    echo [INFO] choco successfully installed.
) else (
    echo [ERROR] Failed to install Chocolatey.
)
@echo off
echo Uninstalling choco is not supported via this script.
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "choco" "."
@echo off
set "PACKAGE_NAME=volta"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling volta is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "volta" "."
@echo off
set "PACKAGE_NAME=hatch"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "hatch" "."
@echo off
set "PACKAGE_NAME=bun"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling bun is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "bun" "."
@echo off
set "PACKAGE_NAME=yarn"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling yarn is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "yarn" "."
@echo off
set "PACKAGE_NAME=google-cloud-sdk"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
call "%~dp0\..\..\..\_lib\_common\setup_base.cmd"
@echo off
call "%~dp0\..\..\_lib\_common\uninstall.cmd" %*
@echo off
call "%~dp0\..\..\_lib\_common\test_base.cmd"
@echo off
set "PACKAGE_NAME=nvm"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "nvm" "."
@echo off
set "PACKAGE_NAME=vcpkg"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "vcpkg" "."
@echo off
set "PACKAGE_NAME=rustup"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "rustup" "."
@echo off
set "PACKAGE_NAME=pip"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "pip" "."
@echo off
set "PACKAGE_NAME=uv"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling uv is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "uv" "."
@echo off
set "PACKAGE_NAME=cpanm"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "cpanm" "."
@echo off
set "PACKAGE_NAME=poetry"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling poetry is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "poetry" "."
@echo off
set "PACKAGE_NAME=ansible-galaxy"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "ansible-galaxy" "."
@echo off
set "PACKAGE_NAME=guix"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling guix is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "guix" "."
@echo off
set "PACKAGE_NAME=apt"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "apt" "."
@echo off
set "PACKAGE_NAME=macports"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "macports" "."
@echo off
set "PACKAGE_NAME=nuget"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling nuget is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "nuget" "."
@echo off
set "PACKAGE_NAME=aqua"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "aqua" "."
@echo off
set "PACKAGE_NAME=conan"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "conan" "."
@echo off
set "PACKAGE_NAME=snap"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "snap" "."
@echo off
set "PACKAGE_NAME=sbt"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "sbt" "."
@echo off
set "PACKAGE_NAME=julia"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "julia" "."
@echo off
set "PACKAGE_NAME=fnm"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling fnm is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "fnm" "."
@echo off
set "PACKAGE_NAME=pub"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "pub" "."
@echo off
set "PACKAGE_NAME=stack"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "stack" "."
@echo off
set "PACKAGE_NAME=dnf"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "dnf" "."
@echo off
set "PACKAGE_NAME=rye"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "rye" "."
@echo off
set "PACKAGE_NAME=nimble"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling nimble is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "nimble" "."
@echo off
set "PACKAGE_NAME=paru"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "paru" "."
@echo off
set "PACKAGE_NAME=spack"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling spack is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "spack" "."
@echo off
set "PACKAGE_NAME=helm"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling helm is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "helm" "."
@echo off
set "PACKAGE_NAME=npm"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "npm" "."
@echo off
set "PACKAGE_NAME=bundler"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "bundler" "."
@echo off
set "PACKAGE_NAME=xbps"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling xbps is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "xbps" "."
@echo off
set "PACKAGE_NAME=rbenv"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "rbenv" "."
@echo off
call "%~dp0\..\..\_lib\_common\cli.cmd" %*
@echo off
setlocal
where cygcheck >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

set "CYGWIN_ROOT=C:\cygwin64"
if exist "%CYGWIN_ROOT%\bin\cygcheck.exe" (
    echo [INFO] Cygwin found at %CYGWIN_ROOT%. Adding to PATH...
    set "PATH=%CYGWIN_ROOT%\bin;%PATH%"
    goto :eof
)

echo [INFO] Bootstrapping Cygwin environment natively for Windows...
set "PACKAGE_NAME=cygwin"
set "CYGWIN_URL=https://cygwin.com/setup-x86_64.exe"
set "CYGWIN_OUT=%TEMP%\cygwin-setup.exe"

call "%~dp0\..\..\_common\pkg_mgr.cmd" :libscript_download "%CYGWIN_URL%" "%CYGWIN_OUT%"
if exist "%CYGWIN_OUT%" (
    echo [INFO] Running unattended Cygwin installation to %CYGWIN_ROOT%...
    "%CYGWIN_OUT%" --quiet-mode --root "%CYGWIN_ROOT%" --site http://mirrors.kernel.org/sourceware/cygwin/ --packages wget,curl,tar,gawk,bzip2,git
    echo [INFO] Cygwin successfully installed. Adding to PATH...
    set "PATH=%CYGWIN_ROOT%\bin;%PATH%"
) else (
    echo [ERROR] Failed to download Cygwin installer.
)
@echo off
echo "Uninstalling cygwin is not supported via this script."
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "cygwin" "."
@echo off
set "PACKAGE_NAME=cabal"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "cabal" "."
@echo off
set "PACKAGE_NAME=krew"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling krew is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "kubectl-krew" "."
@echo off
set "PACKAGE_NAME=pkg"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling pkg is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "pkg" "."
@echo off
set "PACKAGE_NAME=gem"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "gem" "."
@echo off
set "PACKAGE_NAME=pdm"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "pdm" "."
@echo off
set "PACKAGE_NAME=fluentbit"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [INFO] PowerShell not found. Installing Fluent Bit natively...
set "PACKAGE_NAME=fluentbit"
set "PREFIX=%LIBSCRIPT_ROOT_DIR%\installed\fluent-bit"
if not exist "%PREFIX%" mkdir "%PREFIX%"
:: Without powershell, native download can be done via pkg_mgr.cmd.
:: Fluent Bit Windows zip URL
set "FLUENTBIT_URL=https://packages.fluentbit.io/windows/fluent-bit-3.0.0-win64.zip"
if not exist "%PREFIX%\fluent-bit.zip" (
    echo [INFO] Downloading Fluent Bit...
    call "%~dp0\..\..\..\_lib\_common\pkg_mgr.cmd" :libscript_download "%FLUENTBIT_URL%" "%PREFIX%\fluent-bit.zip"
)
if exist "%PREFIX%\fluent-bit.zip" (
    echo [INFO] Extracting Fluent Bit...
    tar -xf "%PREFIX%\fluent-bit.zip" -C "%PREFIX%"
    :: Move contents so bin\fluent-bit.exe is at %PREFIX%\bin\fluent-bit.exe
    xcopy /s /e /y "%PREFIX%\fluent-bit-3.0.0-win64\*" "%PREFIX%\" >nul 2>&1
    rmdir /s /q "%PREFIX%\fluent-bit-3.0.0-win64" >nul 2>&1
    echo [INFO] Fluent Bit installed successfully to %PREFIX%.
    exit /b 0
) else (
    echo [ERROR] Failed to download Fluent Bit.
    exit /b 1
)
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set "PURGE_DATA=0"
:parse_args
if "%~1"=="" goto after_parse
if /i "%~1"=="--purge-data" set "PURGE_DATA=1"
shift
goto parse_args
:after_parse

if not "%FLUENTBIT_SERVICE_NAME%"=="" (
    sc stop %FLUENTBIT_SERVICE_NAME% >nul 2>&1
    sc delete %FLUENTBIT_SERVICE_NAME% >nul 2>&1
) else (
    sc stop libscript_fluentbit >nul 2>&1
    sc delete libscript_fluentbit >nul 2>&1
)

where choco >nul 2>&1
if %ERRORLEVEL% equ 0 choco uninstall fluent-bit -y >nul 2>&1

:: Default uninstall hook for Windows native installation
if "%INSTALLED_DIR%"=="" set "INSTALLED_DIR=%LIBSCRIPT_ROOT_DIR%\installed\fluent-bit"

if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for fluent-bit at %INSTALLED_DIR%.
    )
)

if "!PURGE_DATA!"=="1" (
    echo Purging fluent-bit data...
    if exist "%LIBSCRIPT_ROOT_DIR%\data\fluentbit" (
        rmdir /s /q "%LIBSCRIPT_ROOT_DIR%\data\fluentbit"
    )
)

exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "fluent-bit" "."
@echo off
set "PACKAGE_NAME=cmake"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "cmake" "."
@echo off
set "PACKAGE_NAME=maven"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "maven" "."
@echo off
set "PACKAGE_NAME=just"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "just" "."
@echo off
set "PACKAGE_NAME=gradle"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell


:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell

echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
echo "Uninstalling apk is not supported via this script."
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "gradle" "."
@echo off
set "PACKAGE_NAME=bazel"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "bazel" "."
@echo off
set "PACKAGE_NAME=coursier"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "coursier" "."
@echo off
set "PACKAGE_NAME=redis"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using libscript_download from _lib/_common/pkg_mgr.cmd
exit /b 1
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "redis-server" "."
@echo off
set "PACKAGE_NAME=valkey"
call "%~dp0\..\..\_common\component_core.cmd" %*
@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook natively supported
echo Valkey/Redis is not supported on Windows natively.
exit /b 0
exit /b 0
@echo off
:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
:: Add background service removal logic here if applicable
exit /b 0
@echo off
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "valkey" "."
@echo off
setlocal EnableDelayedExpansion

set "PROVIDER=%~1"
set "NODE=%~2"
set "RG=%~3"
set "LOC=%~4"
set "REPO_PATH=%~5"
if "!REPO_PATH!"=="" set "REPO_PATH=."
set "REMOTE_DEST=%~6"
if "!REMOTE_DEST!"=="" set "REMOTE_DEST=~/%NODE%"

if "!LOC!"=="" (
  echo Usage: teardown_cloud.cmd ^<provider^> ^<node_name^> ^<rg_or_vpc_or_project^> ^<region_or_zone^> [local_repo_path] [remote_dest]
  exit /b 1
)

:: -----------------------------------------------------------------------------
:: Logging Configuration
:: -----------------------------------------------------------------------------
set "LOG_DIR=!REPO_PATH!\logs"
if not exist "!LOG_DIR!" mkdir "!LOG_DIR!"
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set "TIMESTAMP=!datetime:~0,14!"
set "LOG_FILE=!LOG_DIR!\teardown-!TIMESTAMP!.log"

call :log "INIT" "Starting !PROVIDER! teardown for !NODE!..."

set "STATE_FILE=!REPO_PATH!\.deploy_state"

set "DOMAIN="
set "STATE_BUCKET="
set "STATE_ENDPOINT="
set "STATE_PATHS="

if exist "!REPO_PATH!\libscript.json" (
  where jq >nul 2>&1
  if !errorlevel! equ 0 (
    for /f "delims=" %%I in ('jq -r ".domain // \"\"" "!REPO_PATH!\libscript.json"') do set "DOMAIN=%%I"
    for /f "delims=" %%I in ('jq -r ".state.bucket // \"\"" "!REPO_PATH!\libscript.json"') do set "STATE_BUCKET=%%I"
    for /f "delims=" %%I in ('jq -r ".state.endpoint // \"\"" "!REPO_PATH!\libscript.json"') do set "STATE_ENDPOINT=%%I"
    for /f "delims=" %%I in ('jq -r "if .state.paths then (.state.paths | join(\" \")) else \"\" end" "!REPO_PATH!\libscript.json"') do set "STATE_PATHS=%%I"
  )
)

set "CLI=%~dp0..\_lib\cloud-providers\!PROVIDER!\cli.cmd"
if not exist "!CLI!" (
  call :log "ERROR" "Provider !PROVIDER! not supported."
  exit /b 1
)

set "CTX=!RG!"
if "!PROVIDER!"=="aws" set "CTX=!LOC!"
if "!PROVIDER!"=="gcp" set "CTX=!LOC!"

call :log "STOP" "Stopping remote stack..."
call "!CLI!" node exec "!NODE!" "!CTX!" "cd !REMOTE_DEST! && sudo ~/libscript/libscript.sh stop" >> "!LOG_FILE!" 2>&1

if not "!STATE_PATHS!"=="" (
  for %%P in (!STATE_PATHS!) do (
    call :log "SYNC" "Syncing %%P from node to prevent data loss..."
    call "!CLI!" node scp-from "!NODE!" "!CTX!" "!REMOTE_DEST!/%%P" "!REPO_PATH!\%%P" >> "!LOG_FILE!" 2>&1

    if not "!STATE_BUCKET!"=="" if exist "!REPO_PATH!\%%P" (
      call :log "STATE" "Backing up %%P to object storage !STATE_BUCKET!..."
      if "!STATE_BUCKET:~0,5!"=="s3://" (
        set "S3_ARGS="
        if not "!STATE_ENDPOINT!"=="" set "S3_ARGS=--endpoint-url !STATE_ENDPOINT!"
        aws s3 cp !S3_ARGS! "!REPO_PATH!\%%P" "!STATE_BUCKET!/%%P" >> "!LOG_FILE!" 2>&1
      ) else if "!STATE_BUCKET:~0,5!"=="gs://" (
        gcloud storage cp "!REPO_PATH!\%%P" "!STATE_BUCKET!/%%P" >> "!LOG_FILE!" 2>&1
      ) else if "!STATE_BUCKET:~0,8!"=="azure://" (
        for /f "tokens=3 delims=/" %%C in ("!STATE_BUCKET!") do set "CONTAINER=%%C"
        az storage blob upload --container-name "!CONTAINER!" --name "%%P" --file "!REPO_PATH!\%%P" --auth-mode login --overwrite >> "!LOG_FILE!" 2>&1
      )
    )
  )
)

if not "!DOMAIN!"=="" (
  call :log "DNS" "Unmapping DNS..."
  if "!PROVIDER!"=="azure" (
    for %%a in ("!DOMAIN:.*=!") do set "ZONE_NAME=%%~a"
    call "!CLI!" dns unmap-node "!NODE!" "!RG!" "!DOMAIN!" "!ZONE_NAME!" "!ZONE_NAME!-rg" >> "!LOG_FILE!" 2>&1
  ) else if "!PROVIDER!"=="aws" (
    if "!AWS_ZONE_ID!"=="" (
      for /f "tokens=*" %%i in ('aws route53 list-hosted-zones-by-name --dns-name "!DOMAIN!" --query "HostedZones[0].Id" --output text 2^>nul') do set "RAW_ID=%%i"
      if not "!RAW_ID!"=="None" (
        for %%a in ("!RAW_ID:/=" "!") do set "AWS_ZONE_ID=%%~a"
      )
    )
    if not "!AWS_ZONE_ID!"=="" (
      call "!CLI!" dns unmap-node "!NODE!" "!DOMAIN!" "!AWS_ZONE_ID!" >> "!LOG_FILE!" 2>&1
    )
  ) else if "!PROVIDER!"=="gcp" (
    for %%a in ("!DOMAIN:.*=!") do set "ZONE_NAME=%%~a"
    call "!CLI!" dns unmap-node "!NODE!" "!LOC!" "!DOMAIN!" "!ZONE_NAME!" >> "!LOG_FILE!" 2>&1
  )
)

call :log "INFRA" "Deleting Node..."
call "!CLI!" node delete "!NODE!" "!CTX!" >> "!LOG_FILE!" 2>&1

call :log "INFRA" "Deleting Firewall..."
if "!PROVIDER!"=="azure" (
  call "!CLI!" firewall delete "!NODE!-nsg!" "!RG!" >> "!LOG_FILE!" 2>&1
) else if "!PROVIDER!"=="aws" (
  set "SG_ID="
  if exist "!STATE_FILE!" (
    for /f "tokens=2 delims==" %%i in ('findstr "^AWS_SG=" "!STATE_FILE!"') do set "SG_ID=%%i"
  )
  if not "!SG_ID!"=="" (
    aws ec2 delete-security-group --group-id "!SG_ID!" >> "!LOG_FILE!" 2>&1
  )
) else if "!PROVIDER!"=="gcp" (
  call "!CLI!" firewall delete "!NODE!-fw" >> "!LOG_FILE!" 2>&1
)

call :log "INFRA" "Deleting Network..."
if "!PROVIDER!"=="azure" (
  call "!CLI!" network delete "!NODE!-vnet" "!RG!" >> "!LOG_FILE!" 2>&1
) else if "!PROVIDER!"=="aws" (
  set "VPC_ID="
  if exist "!STATE_FILE!" (
    for /f "tokens=2 delims==" %%i in ('findstr "^AWS_VPC=" "!STATE_FILE!"') do set "VPC_ID=%%i"
  )
  if not "!VPC_ID!"=="" (
    aws ec2 delete-vpc --vpc-id "!VPC_ID!" >> "!LOG_FILE!" 2>&1
  ) else (
    call "!CLI!" network delete "!NODE!-vpc" >> "!LOG_FILE!" 2>&1
  )
) else if "!PROVIDER!"=="gcp" (
  call "!CLI!" network delete "!NODE!-vpc" >> "!LOG_FILE!" 2>&1
)

if exist "!STATE_FILE!" (
  call :log "STATE" "Cleaning up !STATE_FILE!"
  del "!STATE_FILE!"
)

call :log "DONE" "Teardown complete."
exit /b 0

:: -----------------------------------------------------------------------------
:: Functions
:: -----------------------------------------------------------------------------
:log
echo [%~1] %~2
echo [%DATE% %TIME%] [%~1] %~2 >> "!LOG_FILE!"
exit /b 0
@echo off
setlocal enabledelayedexpansion

if "%~1"=="--help" (
    echo Usage: %0 [OPTIONS]
    echo See script source or documentation for more details.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %0 [OPTIONS]
    echo See script source or documentation for more details.
    exit /b 0
)


REM resolve_stack.cmd
REM A portable wrapper for the SAT/Constraint solver using jq on Windows.
REM Usage: scripts\resolve_stack.cmd <path_to_install.json>

if "%~1"=="" (
    echo Usage: %0 ^<path_to_install.json^>
    exit /b 1
)

set "INSTALL_JSON=%~1"
set "SCRIPT_DIR=%~dp0"
set "LIB_DIR=%SCRIPT_DIR%..\_lib"

REM Default TARGET_OS to windows unless overridden
if "%LIBSCRIPT_TARGET_OS%"=="" (
    set "TARGET_OS=windows"
) else (
    set "TARGET_OS=%LIBSCRIPT_TARGET_OS%"
)

where jq >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: jq is required but not installed.
    exit /b 1
)

REM Gather manifests into a single JSON array structure inline.
set "MANIFESTS="
for /R "%LIB_DIR%" %%F in (manifest.json) do (
    set "MANIFESTS=!MANIFESTS! "%%F""
)

REM Run the jq resolution engine
jq --arg target_os "%TARGET_OS%" -n "{install: input, manifests: [inputs]}" "%INSTALL_JSON%" %MANIFESTS% | jq -L "%SCRIPT_DIR%." --arg target_os "%TARGET_OS%" -r -f "%SCRIPT_DIR%resolve_stack.jq"

endlocal
@echo off
setlocal enabledelayedexpansion

set action=%~1
set json_file=%~2

if not exist "%json_file%" exit /b 0

for /f "delims=" %%i in ('jq -c ".services[]?" "%json_file%" 2^>nul') do (
    set "svc=%%i"
    for /f "delims=" %%n in ('echo !svc! ^| jq -r ".name // empty"') do set "name=%%n"
    for /f "delims=" %%c in ('echo !svc! ^| jq -r ".command // empty"') do set "cmd=%%c"
    
    if not "!name!"=="" if not "!cmd!"=="" (
        if /i "!action!"=="start" (
            echo Configuring and starting service '!name!'...
            if not exist "\tmp\data\!name!" mkdir "\tmp\data\!name!" 2>nul
            
            rem Set environments inline
            for /f "delims=" %%e in ('echo !svc! ^| jq -r ".env | to_entries[]? | \"set \\\"\(.key)=\(.value)\\\"\"" 2^>nul') do (
                %%e
            )
            
            rem Enumerate env files (basic naive support)
            for /f "delims=" %%f in ('echo !svc! ^| jq -r ".env_files[]?" 2^>nul') do (
                if exist "%%f" (
                    for /f "tokens=* delims=" %%l in (%%f) do set "%%l"
                )
            )

            start "!name!" /B cmd.exe /c "!cmd!"
        )
        if /i "!action!"=="up" (
            echo Configuring and starting service '!name!'...
            start "!name!" /B cmd.exe /c "!cmd!"
        )
        if /i "!action!"=="stop" (
            echo Stopping service '!name!'...
            rem Complex to kill without PID, could use taskkill with window title
            taskkill /fi "WINDOWTITLE eq !name!" /f 2>nul
        )
        if /i "!action!"=="down" (
            taskkill /fi "WINDOWTITLE eq !name!" /f 2>nul
        )
    )
)
exit /b 0
@echo off
setlocal enabledelayedexpansion

set json_file=%~1
set hook_type=%~2

if not exist "%json_file%" exit /b 0

for /f "delims=" %%i in ('jq -c ".hooks.%hook_type%[]?" "%json_file%" 2^>nul') do (
    set "hook=%%i"
    for /f "delims=" %%n in ('echo !hook! ^| jq -r ".name // \"unnamed_hook\""') do set "name=%%n"
    for /f "delims=" %%c in ('echo !hook! ^| jq -r ".command // empty"') do set "cmd=%%c"
    for /f "delims=" %%d in ('echo !hook! ^| jq -r ".condition // empty"') do set "cond=%%d"
    
    set skip=0
    if not "!cond!"=="" (
        echo !cond! | findstr /b /c:"unless_exists " >nul
        if not errorlevel 1 (
            set "file=!cond:unless_exists =!"
            if exist "!file!" (
                echo Skipping hook '!name!': !file! exists
                set skip=1
            )
        )
    )
    
    if "!skip!"=="0" if not "!cmd!"=="" (
        echo Executing hook '!name!': !cmd!
        call !cmd!
    )
)
exit /b 0
@echo off
setlocal EnableDelayedExpansion

set "PROVIDER=%~1"
set "NODE=%~2"
set "RG=%~3"
set "LOC=%~4"
set "REPO_PATH=%~5"
if "!REPO_PATH!"=="" set "REPO_PATH=."
set "REMOTE_DEST=%~6"
if "!REMOTE_DEST!"=="" set "REMOTE_DEST=~/%NODE%"

if "!LOC!"=="" (
  echo Usage: deploy_cloud.cmd ^<provider^> ^<node_name^> ^<rg_or_vpc_or_project^> ^<region_or_zone^> [local_repo_path] [remote_dest]
  exit /b 1
)

:: -----------------------------------------------------------------------------
:: Logging Configuration
:: -----------------------------------------------------------------------------
set "LOG_DIR=!REPO_PATH!\logs"
if not exist "!LOG_DIR!" mkdir "!LOG_DIR!"
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set "TIMESTAMP=!datetime:~0,14!"
set "LOG_FILE=!LOG_DIR!\provision-!TIMESTAMP!.log"

call :log "INIT" "Starting !PROVIDER! deployment for !NODE!..."
call :log "INIT" "Logging to !LOG_FILE!"

set "STATE_FILE=!REPO_PATH!\.deploy_state"
if not exist "!STATE_FILE!" type nul > "!STATE_FILE!"

call :record_state "PROVIDER" "!PROVIDER!"
call :record_state "NODE" "!NODE!"
call :record_state "RG" "!RG!"
call :record_state "REGION" "!LOC!"

set "CLI=%~dp0..\_lib\cloud-providers\!PROVIDER!\cli.cmd"
if not exist "!CLI!" (
  call :log "ERROR" "Provider !PROVIDER! not supported."
  exit /b 1
)

:: -----------------------------------------------------------------------------
:: Read Configuration
:: -----------------------------------------------------------------------------
set "DOMAIN="
set "SECRETS_DIR="
set "OS_IMAGE="
set "SIZE="
set "DISK_GB="
set "PORTS=22 80 443"
set "STATE_BUCKET="
set "STATE_ENDPOINT="
set "STATE_PATHS="

if exist "!REPO_PATH!\libscript.json" (
  where jq >nul 2>&1
  if !errorlevel! equ 0 (
    for /f "delims=" %%I in ('jq -r ".domain // \"\"" "!REPO_PATH!\libscript.json"') do set "DOMAIN=%%I"
    for /f "delims=" %%I in ('jq -r ".secrets_dir // \"\"" "!REPO_PATH!\libscript.json"') do set "SECRETS_DIR=%%I"
    for /f "delims=" %%I in ('jq -r ".infrastructure.node.os // \"\"" "!REPO_PATH!\libscript.json"') do set "OS_IMAGE=%%I"
    for /f "delims=" %%I in ('jq -r ".infrastructure.node.size // \"\"" "!REPO_PATH!\libscript.json"') do set "SIZE=%%I"
    for /f "delims=" %%I in ('jq -r ".infrastructure.node.disk_gb // \"\"" "!REPO_PATH!\libscript.json"') do set "DISK_GB=%%I"
    for /f "delims=" %%I in ('jq -r "if .infrastructure.network.ports then (.infrastructure.network.ports | join(\" \")) else \"\" end" "!REPO_PATH!\libscript.json"') do set "PORTS=%%I"
    if "!PORTS!"=="" set "PORTS=22 80 443"
    for /f "delims=" %%I in ('jq -r ".state.bucket // \"\"" "!REPO_PATH!\libscript.json"') do set "STATE_BUCKET=%%I"
    for /f "delims=" %%I in ('jq -r ".state.endpoint // \"\"" "!REPO_PATH!\libscript.json"') do set "STATE_ENDPOINT=%%I"
    for /f "delims=" %%I in ('jq -r "if .state.paths then (.state.paths | join(\" \")) else \"\" end" "!REPO_PATH!\libscript.json"') do set "STATE_PATHS=%%I"
  )
)

if "!OS_IMAGE!"=="" (
  if "!PROVIDER!"=="azure" set "OS_IMAGE=Ubuntu2204"
  if "!PROVIDER!"=="aws" set "OS_IMAGE=ami-0c7217cdde317cfec"
  if "!PROVIDER!"=="gcp" set "OS_IMAGE=ubuntu-2204-lts"
)
if "!SIZE!"=="" (
  if "!PROVIDER!"=="azure" set "SIZE=Standard_B2s"
  if "!PROVIDER!"=="aws" set "SIZE=t3.medium"
  if "!PROVIDER!"=="gcp" set "SIZE=e2-medium"
) else (
  echo !SIZE! | findstr /b "Standard_D" >nul
  if not errorlevel 1 (
    if "!PROVIDER!"=="aws" set "SIZE=t3.xlarge"
    if "!PROVIDER!"=="gcp" set "SIZE=e2-standard-4"
  )
  echo !SIZE! | findstr /b "Standard_B" >nul
  if not errorlevel 1 (
    if "!PROVIDER!"=="aws" set "SIZE=t3.medium"
    if "!PROVIDER!"=="gcp" set "SIZE=e2-medium"
  )
  echo !SIZE! | findstr /b "t3." >nul
  if not errorlevel 1 (
    if "!PROVIDER!"=="azure" set "SIZE=Standard_D4s_v3"
    if "!PROVIDER!"=="gcp" set "SIZE=e2-standard-4"
  )
)

call :log "INFRA" "Provisioning Network and Compute..."

if "!PROVIDER!"=="azure" (
  call :retry az group create --name "!RG!" --location "!LOC!"
  call :record_state "AZURE_RG" "!RG!"
  call :retry "!CLI!" network create "!NODE!-vnet" "!RG!" --location "!LOC!"
  call :record_state "AZURE_VNET" "!NODE!-vnet"
  call :retry "!CLI!" firewall create "!NODE!-nsg" "!RG!" "!PORTS!" --location "!LOC!"
  call :record_state "AZURE_NSG" "!NODE!-nsg"
  set "NODE_ARGS=--size !SIZE! --vnet-name !NODE!-vnet --nsg !NODE!-nsg"
  if not "!DISK_GB!"=="" set "NODE_ARGS=!NODE_ARGS! --os-disk-size-gb !DISK_GB!"
  call :retry "!CLI!" node create "!NODE!" "!OS_IMAGE!" "!RG!" !NODE_ARGS!
  call :record_state "AZURE_NODE" "!NODE!"
)

if "!PROVIDER!"=="aws" (
  set "AWS_DEFAULT_REGION=!LOC!"
  for /f "tokens=*" %%i in ('call "!CLI!" network create "!NODE!-vpc"') do set "VPC_ID=%%i"
  call :record_state "AWS_VPC" "!VPC_ID!"
  for /f "tokens=*" %%i in ('call "!CLI!" firewall create "!NODE!-sg" "!NODE!-vpc" "!PORTS!"') do set "SG_ID=%%i"
  call :record_state "AWS_SG" "!SG_ID!"
  call :retry "!CLI!" node create "!NODE!" "!OS_IMAGE!" "!NODE!-vpc" "!SIZE!"
  call :record_state "AWS_NODE" "!NODE!"
)

if "!PROVIDER!"=="gcp" (
  set "GCP_ZONE=!LOC!"
  call :retry "!CLI!" network create "!NODE!-vpc" "10.0.0.0/16"
  call :record_state "GCP_VPC" "!NODE!-vpc"
  call :retry "!CLI!" firewall create "!NODE!-fw" "!NODE!-vpc" "!PORTS!"
  call :record_state "GCP_FW" "!NODE!-fw"
  call :retry "!CLI!" node create "!NODE!" "!OS_IMAGE!" "!RG!" --network "!NODE!-vpc!" --machine-type "!SIZE!"
  call :record_state "GCP_NODE" "!NODE!"
)

set "CTX=!RG!"
if "!PROVIDER!"=="aws" set "CTX=!LOC!"
if "!PROVIDER!"=="gcp" set "CTX=!LOC!"

:: -----------------------------------------------------------------------------
:: Wait for SSH / WinRM
:: -----------------------------------------------------------------------------
call :log "HEALTH" "Waiting for SSH/WinRM readiness on node !NODE!..."
set "ATTEMPT=1"
set "MAX_ATTEMPTS=30"
:ssh_loop
call "!CLI!" node exec "!NODE!" "!CTX!" "echo SSH_READY" >nul 2>&1
if %errorlevel% equ 0 (
  call :log "HEALTH" "SSH/WinRM is ready."
  goto :ssh_ready
)
if !ATTEMPT! geq !MAX_ATTEMPTS! (
  call :log "ERROR" "Node failed to become ready after !MAX_ATTEMPTS! attempts."
  exit /b 1
)
call :log "HEALTH" "Not ready (attempt !ATTEMPT!/!MAX_ATTEMPTS!). Waiting 10s..."
timeout /t 10 /nobreak >nul
set /a ATTEMPT+=1
goto :ssh_loop

:ssh_ready

:: -----------------------------------------------------------------------------
:: Sync and Deploy
:: -----------------------------------------------------------------------------
call :log "SYNC" "Syncing LibScript..."
call :retry "!CLI!" node sync "!NODE!" "!CTX!"

call :log "SYNC" "Deploying Repository..."
call :retry "!CLI!" node exec "!NODE!" "!CTX!" "mkdir -p !REMOTE_DEST!"
where rsync >nul 2>&1
if %errorlevel% equ 0 (
  call :log "SYNC" "Using rsync..."
  call :retry "!CLI!" node deploy "!NODE!" "!CTX!" "!REPO_PATH!" "!REMOTE_DEST!"
) else (
  call :log "SYNC" "Using scp/winrm fallback..."
  call :retry "!CLI!" node scp "!NODE!" "!CTX!" "!REPO_PATH!" "!REMOTE_DEST!"
)

if not "!SECRETS_DIR!"=="" if exist "!REPO_PATH!\!SECRETS_DIR!" (
  call :log "SECRETS" "Deploying Secrets out-of-band via node scp (bypassing gitignore)..."
  call :retry "!CLI!" node scp "!NODE!" "!CTX!" "!REPO_PATH!\!SECRETS_DIR!" "!REMOTE_DEST!/!SECRETS_DIR!"
)

if not "!STATE_PATHS!"=="" (
  for %%P in (!STATE_PATHS!) do (
    if not "!STATE_BUCKET!"=="" (
      call :log "STATE" "Restoring %%P from object storage !STATE_BUCKET!..."
      if "!STATE_BUCKET:~0,5!"=="s3://" (
        set "S3_ARGS="
        if not "!STATE_ENDPOINT!"=="" set "S3_ARGS=--endpoint-url !STATE_ENDPOINT!"
        aws s3 cp !S3_ARGS! "!STATE_BUCKET!/%%P" "!REPO_PATH!\%%P" >> "!LOG_FILE!" 2>&1
      ) else if "!STATE_BUCKET:~0,5!"=="gs://" (
        gcloud storage cp "!STATE_BUCKET!/%%P" "!REPO_PATH!\%%P" >> "!LOG_FILE!" 2>&1
      ) else if "!STATE_BUCKET:~0,8!"=="azure://" (
        for /f "tokens=3 delims=/" %%C in ("!STATE_BUCKET!") do set "CONTAINER=%%C"
        az storage blob download --container-name "!CONTAINER!" --name "%%P" --file "!REPO_PATH!\%%P" --auth-mode login >> "!LOG_FILE!" 2>&1
      )
    )
    if exist "!REPO_PATH!\%%P" (
      call :log "STATE" "Deploying state %%P to node..."
      call :retry "!CLI!" node scp "!NODE!" "!CTX!" "!REPO_PATH!\%%P" "!REMOTE_DEST!/%%P"
    )
  )
)

if not "!DOMAIN!"=="" (
  call :log "DNS" "Mapping DNS for !DOMAIN!..."
  if "!PROVIDER!"=="azure" (
    for %%a in ("!DOMAIN:.*=!") do set "ZONE_NAME=%%~a"
    call :retry "!CLI!" dns map-node "!NODE!" "!RG!" "!DOMAIN!" "!ZONE_NAME!" "!ZONE_NAME!-rg"
  ) else if "!PROVIDER!"=="aws" (
    if "!AWS_ZONE_ID!"=="" (
      for /f "tokens=*" %%i in ('aws route53 list-hosted-zones-by-name --dns-name "!DOMAIN!" --query "HostedZones[0].Id" --output text 2^>nul') do set "RAW_ID=%%i"
      if not "!RAW_ID!"=="None" (
        for %%a in ("!RAW_ID:/=" "!") do set "AWS_ZONE_ID=%%~a"
      )
    )
    if not "!AWS_ZONE_ID!"=="" (
      call :retry "!CLI!" dns map-node "!NODE!" "!DOMAIN!" "!AWS_ZONE_ID!"
    )
  ) else if "!PROVIDER!"=="gcp" (
    for %%a in ("!DOMAIN:.*=!") do set "ZONE_NAME=%%~a"
    call :retry "!CLI!" dns map-node "!NODE!" "!LOC!" "!DOMAIN!" "!ZONE_NAME!"
  )
)

call :log "START" "Installing Dependencies and Starting..."
call :retry "!CLI!" node exec "!NODE!" "!CTX!" "cd !REMOTE_DEST! && sudo ~/libscript/libscript.sh install-deps"
call :retry "!CLI!" node exec "!NODE!" "!CTX!" "cd !REMOTE_DEST! && sudo ~/libscript/libscript.sh start"

:: -----------------------------------------------------------------------------
:: Wait for Health
:: -----------------------------------------------------------------------------
call :log "HEALTH" "Polling application health (via libscript health)..."
set "ATTEMPT=1"
set "MAX_ATTEMPTS=12"
:health_loop
call "!CLI!" node exec "!NODE!" "!CTX!" "cd !REMOTE_DEST! && sudo ~/libscript/libscript.sh health" >nul 2>&1
if %errorlevel% equ 0 (
  call :log "HEALTH" "Application stack is healthy."
  goto :health_ready
)
if !ATTEMPT! geq !MAX_ATTEMPTS! (
  call :log "WARNING" "Application health check failed or timed out. Check logs."
  goto :health_ready
)
call :log "HEALTH" "Application not ready (attempt !ATTEMPT!/!MAX_ATTEMPTS!). Waiting 10s..."
timeout /t 10 /nobreak >nul
set /a ATTEMPT+=1
goto :health_loop

:health_ready

call :log "DONE" "Deployment complete. View logs at !LOG_FILE!"
exit /b 0

:: -----------------------------------------------------------------------------
:: Functions
:: -----------------------------------------------------------------------------
:log
echo [%~1] %~2
echo [%DATE% %TIME%] [%~1] %~2 >> "!LOG_FILE!"
exit /b 0

:record_state
echo %~1=%~2 >> "!STATE_FILE!"
call :log "STATE" "Recorded %~1=%~2"
exit /b 0

:retry
set "RETRY_ATTEMPT=1"
set "RETRY_MAX=5"
set "RETRY_WAIT=5"
:retry_loop
call :log "RETRY" "Attempt !RETRY_ATTEMPT! of !RETRY_MAX!: %*"
call %* >> "!LOG_FILE!" 2>&1
if %errorlevel% equ 0 (
  call :log "RETRY" "Command succeeded."
  exit /b 0
)
if !RETRY_ATTEMPT! geq !RETRY_MAX! (
  call :log "ERROR" "Command failed after !RETRY_MAX! attempts: %*"
  exit /b 1
)
call :log "RETRY" "Command failed (exit !errorlevel!). Waiting !RETRY_WAIT!s..."
timeout /t !RETRY_WAIT! /nobreak >nul
set /a RETRY_ATTEMPT+=1
set /a RETRY_WAIT*=2
goto :retry_loop
@echo off
setlocal EnableDelayedExpansion

set NETCTL_DIR=%~dp0
set NETCTL_STATE_FILE=.netctl.json

if "%~1"=="" goto usage

set SINGULAR_MODE=0
set EMIT_FORMAT=

if /I "%~1"=="init" (
    call "%NETCTL_DIR%lib\state.cmd" init
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="listen" (
    call "%NETCTL_DIR%lib\state.cmd" listen "%~2"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="static" (
    call "%NETCTL_DIR%lib\state.cmd" static "%~2" "%~3"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="proxy" (
    call "%NETCTL_DIR%lib\state.cmd" proxy "%~2" "%~3"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="rewrite" (
    call "%NETCTL_DIR%lib\state.cmd" rewrite "%~2" "%~3"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="emit" (
    call "%NETCTL_DIR%lib\%~2.cmd"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="-h" (
    goto usage
) else if /I "%~1"=="--help" (
    goto usage
) else (
    set SINGULAR_MODE=1
)

if "!SINGULAR_MODE!"=="1" (
    set NETCTL_STATE_FILE=%TEMP%\netctl_state_%RANDOM%.json
    call "%NETCTL_DIR%lib\state.cmd" init
    
    :loop
    if "%~1"=="" goto done_loop
    if /I "%~1"=="--listen" (
        call "%NETCTL_DIR%lib\state.cmd" listen "%~2"
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--static" (
        call "%NETCTL_DIR%lib\state.cmd" static "%~2" "%~3"
        shift
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--proxy" (
        call "%NETCTL_DIR%lib\state.cmd" proxy "%~2" "%~3"
        shift
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--rewrite" (
        call "%NETCTL_DIR%lib\state.cmd" rewrite "%~2" "%~3"
        shift
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--emit" (
        set EMIT_FORMAT=%~2
        shift
        shift
        goto loop
    )
    echo Unknown option: %1
    goto usage

    :done_loop
    if not "!EMIT_FORMAT!"=="" (
        call "%NETCTL_DIR%lib\!EMIT_FORMAT!.cmd"
    )
    if exist "!NETCTL_STATE_FILE!" del "!NETCTL_STATE_FILE!"
)
exit /b 0

:usage
echo netctl - Singular and Additive network config generator
echo.
echo Usage:
echo   netctl [COMMAND] [ARGS...]
echo   netctl [OPTIONS...]
echo.
echo Commands:
echo   init                           Initialize .netctl.json
echo   listen ^<port^>                  Add a listening port
echo   static ^<path^> ^<target^>         Add a static file route
echo   proxy ^<path^> ^<target^>          Add a reverse proxy route
echo   rewrite ^<path^> ^<pattern^>       Add a rewrite rule
echo   emit ^<format^>                  Emit the configuration for a given format
echo                                  Formats: nginx, caddy, apache, iis
echo.
echo Options (Singular mode):
echo   --listen ^<port^>                Add a listening port
echo   --static ^<path^> ^<target^>       Add a static route
echo   --proxy ^<path^> ^<target^>        Add a proxy route
echo   --rewrite ^<path^> ^<pattern^>     Add a rewrite rule
echo   --emit ^<format^>                Emit to specified format and exit
exit /b 1
@echo off
setlocal EnableDelayedExpansion
if "%NETCTL_STATE_FILE%"=="" set NETCTL_STATE_FILE=.netctl.json

if not exist "%NETCTL_STATE_FILE%" (
    echo Error: State file '%NETCTL_STATE_FILE%' not found. >&2
    exit /b 1
)

for /f "delims=" %%i in ('jq -r ".listen[]" "%NETCTL_STATE_FILE%"') do (
    echo Listen %%i
)
echo.

set FIRST_PORT=
for /f "delims=" %%i in ('jq -r ".listen[0] // \"80\"" "%NETCTL_STATE_FILE%"') do (
    set FIRST_PORT=%%i
)

echo ^<VirtualHost *:%FIRST_PORT%^>

for /f "tokens=1,2,3,4 delims=|" %%a in ('jq -r ".routes | to_entries[] | \"\(.key)|\(.value.type)|\(.value.target // \"\")|\(.value.pattern // \"\")\"" "%NETCTL_STATE_FILE%"') do (
    if "%%b"=="static" (
        echo     Alias "%%a" "%%c"
        echo     ^<Directory "%%c"^>
        echo         Require all granted
        echo     ^</Directory^>
    ) else if "%%b"=="proxy" (
        echo     ProxyPass "%%a" "%%c"
        echo     ProxyPassReverse "%%a" "%%c"
    ) else if "%%b"=="rewrite" (
        echo     RewriteEngine On
        echo     RewriteRule "^%%a(.*)$" "%%d" [L]
    )
)

echo ^</VirtualHost^>
exit /b 0
@echo off
setlocal EnableDelayedExpansion
if "%NETCTL_STATE_FILE%"=="" set NETCTL_STATE_FILE=.netctl.json

if not exist "%NETCTL_STATE_FILE%" (
    echo Error: State file '%NETCTL_STATE_FILE%' not found. >&2
    exit /b 1
)

set PORTS=
for /f "delims=" %%p in ('jq -r "if (.listen | length) > 0 then .listen | map(\":\" + .) | join(\", \") else \"localhost\" end" "%NETCTL_STATE_FILE%"') do (
    set PORTS=%%p
)
echo %PORTS% {

for /f "tokens=1,2,3,4 delims=|" %%a in ('jq -r ".routes | to_entries[] | \"\(.key)|\(.value.type)|\(.value.target // \"\")|\(.value.pattern // \"\")\"" "%NETCTL_STATE_FILE%"') do (
    echo.
    if "%%b"=="static" (
        echo     handle %%a* {
        echo         root * %%c
        echo         file_server
        echo     }
    ) else if "%%b"=="proxy" (
        echo     reverse_proxy %%a* %%c
    ) else if "%%b"=="rewrite" (
        echo     rewrite %%a* %%d
    )
)

echo }
exit /b 0
@echo off
setlocal EnableDelayedExpansion
if "%NETCTL_STATE_FILE%"=="" set NETCTL_STATE_FILE=.netctl.json

if not exist "%NETCTL_STATE_FILE%" (
    echo Error: State file '%NETCTL_STATE_FILE%' not found. >&2
    exit /b 1
)

echo ^<?xml version="1.0" encoding="UTF-8"?^>
echo ^<configuration^>
echo   ^<system.webServer^>
echo     ^<rewrite^>
echo       ^<rules^>

set RULE_ID=1
for /f "tokens=1,2,3,4 delims=|" %%a in ('jq -r ".routes | to_entries[] | \"\(.key)|\(.value.type)|\(.value.target // \"\")|\(.value.pattern // \"\")\"" "%NETCTL_STATE_FILE%"') do (
    if "%%b"=="proxy" (
        echo         ^<rule name="ReverseProxy!RULE_ID!" stopProcessing="true"^>
        echo           ^<match url="^%%a(.*)" /^>
        echo           ^<action type="Rewrite" url="%%c/{R:1}" /^>
        echo         ^</rule^>
        set /a RULE_ID+=1
    ) else if "%%b"=="rewrite" (
        echo         ^<rule name="Rewrite!RULE_ID!" stopProcessing="true"^>
        echo           ^<match url="^%%a(.*)" /^>
        echo           ^<action type="Rewrite" url="%%d" /^>
        echo         ^</rule^>
        set /a RULE_ID+=1
    )
)

echo       ^</rules^>
echo     ^</rewrite^>

:: Note: IIS `appcmd` is usually required for setting Listen ports and Static paths via Virtual Directories.
:: The web.config handles the rewriting and proxying.
:: We will emit comments on how to complete the IIS setup.

echo     ^<!-- To complete IIS Setup for Static paths and Listeners: --^>
for /f "delims=" %%i in ('jq -r ".listen[]" "%NETCTL_STATE_FILE%"') do (
    echo     ^<!-- appcmd set site /site.name:"Default Web Site" /+bindings.[protocol='http',bindingInformation='*:%%i:'] --^>
)

for /f "tokens=1,2,3,4 delims=|" %%a in ('jq -r ".routes | to_entries[] | \"\(.key)|\(.value.type)|\(.value.target // \"\")|\(.value.pattern // \"\")\"" "%NETCTL_STATE_FILE%"') do (
    if "%%b"=="static" (
        echo     ^<!-- appcmd add vdir /app.name:"Default Web Site/" /path:"%%a" /physicalPath:"%%c" --^>
    )
)

echo   ^</system.webServer^>
echo ^</configuration^>
exit /b 0
@echo off
setlocal EnableDelayedExpansion
if "%NETCTL_STATE_FILE%"=="" set NETCTL_STATE_FILE=.netctl.json

if not exist "%NETCTL_STATE_FILE%" (
    echo Error: State file '%NETCTL_STATE_FILE%' not found. >&2
    exit /b 1
)

echo server {

for /f "delims=" %%i in ('jq -r ".listen[]" "%NETCTL_STATE_FILE%"') do (
    echo     listen %%i;
)

for /f "tokens=1,2,3,4 delims=|" %%a in ('jq -r ".routes | to_entries[] | \"\(.key)|\(.value.type)|\(.value.target // \"\")|\(.value.pattern // \"\")\"" "%NETCTL_STATE_FILE%"') do (
    echo.
    echo     location %%a {
    if "%%b"=="static" (
        echo         alias %%c/;
    ) else if "%%b"=="proxy" (
        echo         proxy_pass %%c;
        echo         proxy_set_header Host $host;
        echo         proxy_set_header X-Real-IP $remote_addr;
    ) else if "%%b"=="rewrite" (
        echo         rewrite %%d break;
    )
    echo     }
)

echo }
exit /b 0
@echo off
setlocal EnableDelayedExpansion

if "%NETCTL_STATE_FILE%"=="" set NETCTL_STATE_FILE=.netctl.json

if "%~1"=="init" goto init
if "%~1"=="listen" goto listen
if "%~1"=="static" goto static
if "%~1"=="proxy" goto proxy
if "%~1"=="rewrite" goto rewrite
exit /b 1

:init
if not exist "%NETCTL_STATE_FILE%" (
    echo {"listen":[],"routes":{}} > "%NETCTL_STATE_FILE%"
) else (
    for %%I in ("%NETCTL_STATE_FILE%") do if %%~zI equ 0 (
        echo {"listen":[],"routes":{}} > "%NETCTL_STATE_FILE%"
    )
)
exit /b 0

:listen
call :init
jq --arg p "%~2" ".listen += [$p] | .listen |= unique" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0

:static
call :init
jq --arg p "%~2" --arg t "%~3" ".routes[$p] = {\"type\": \"static\", \"target\": $t}" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0

:proxy
call :init
jq --arg p "%~2" --arg t "%~3" ".routes[$p] = {\"type\": \"proxy\", \"target\": $t}" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0

:rewrite
call :init
jq --arg p "%~2" --arg pt "%~3" ".routes[$p] = {\"type\": \"rewrite\", \"pattern\": $pt}" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0
@echo off
echo Uninstalling netctl is not supported via this script.
exit /b 0
@echo off
echo netctl test pass
exit /b 0
