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
                call "%~dp0scripts\run_hooks.bat" "!json_file!" "build"
                call "%~dp0scripts\run_hooks.bat" "!json_file!" "pre_start"
            )
            if /i "!action!"=="up" (
                call "%~dp0scripts\run_hooks.bat" "!json_file!" "build"
                call "%~dp0scripts\run_hooks.bat" "!json_file!" "pre_start"
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
            call "%~dp0scripts\daemonize.bat" "!action!" "!json_file!"
            call "%~dp0scripts\setup_ingress.bat" "!action!" "!json_file!"
        ) else if /i "!action!"=="up" (
            call "%~dp0scripts\daemonize.bat" "!action!" "!json_file!"
            call "%~dp0scripts\setup_ingress.bat" "!action!" "!json_file!"
        ) else if /i "!action!"=="stop" (
            call "%~dp0scripts\setup_ingress.bat" "!action!" "!json_file!"
            call "%~dp0scripts\daemonize.bat" "!action!" "!json_file!"
        ) else if /i "!action!"=="down" (
            call "%~dp0scripts\setup_ingress.bat" "!action!" "!json_file!"
            call "%~dp0scripts\daemonize.bat" "!action!" "!json_file!"
        ) else if /i "!action!"=="status" (
            call "%~dp0scripts\daemonize.bat" "!action!" "!json_file!"
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
                call "%~dp0scripts\run_hooks.bat" "!json_file!" "build"
                call "%~dp0scripts\run_hooks.bat" "!json_file!" "pre_start"
            )
            if /i "!action!"=="up" (
                call "%~dp0scripts\run_hooks.bat" "!json_file!" "build"
                call "%~dp0scripts\run_hooks.bat" "!json_file!" "pre_start"
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
