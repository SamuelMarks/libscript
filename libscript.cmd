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

:: Delegate commands to sub-scripts
if /i "%cmd%"=="list" ( call "%SCRIPT_DIR%\cli\commands\core\list.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="search" ( call "%SCRIPT_DIR%\cli\commands\core\search.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="provision" ( call "%SCRIPT_DIR%\cli\commands\cloud\provision.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="deprovision" ( call "%SCRIPT_DIR%\cli\commands\cloud\deprovision.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="package_as" ( call "%SCRIPT_DIR%\cli\commands\packaging\package_as.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="install-deps" ( call "%SCRIPT_DIR%\cli\commands\deps\install.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="db-search" ( call "%SCRIPT_DIR%\cli\commands\registry\search.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="update-db" ( call "%SCRIPT_DIR%\cli\commands\registry\update.cmd" %* & exit /b !errorlevel! )
if /i "%cmd%"=="semver" ( call "%SCRIPT_DIR%\cli\commands\core\semver.cmd" %* & exit /b !errorlevel! )

if /i "%cmd%"=="start" set "is_docker_cmd=1"
if /i "%cmd%"=="stop" set "is_docker_cmd=1"
if /i "%cmd%"=="status" set "is_docker_cmd=1"
if /i "%cmd%"=="health" set "is_docker_cmd=1"
if /i "%cmd%"=="logs" set "is_docker_cmd=1"
if /i "%cmd%"=="restart" set "is_docker_cmd=1"
if /i "%cmd%"=="up" set "is_docker_cmd=1"
if /i "%cmd%"=="down" set "is_docker_cmd=1"

if "!is_docker_cmd!"=="1" (
    if not "%LIBSCRIPT_INTERNAL_START%"=="1" (
        call "%SCRIPT_DIR%\cli\commands\services\actions.cmd" %*
        exit /b !errorlevel!
    )
)

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
if exist "%SCRIPT_DIR%\_lib\%action_pkg%\cli.cmd" (
    set "target=%SCRIPT_DIR%\_lib\%action_pkg%"
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
