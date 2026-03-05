@echo off
setlocal EnableDelayedExpansion

:: If called via a wrapper script, %~dp0 will be the wrapper's directory.
set "SCRIPT_DIR=%~dp0"
set "SCHEMA_FILE=%SCRIPT_DIR%vars.schema.json"

set "ACTION="
set "PACKAGE_NAME="
set "VERSION="

set "verb=%~1"
if "%verb%"=="" goto show_help
if /i "%verb%"=="--help" goto show_help
if /i "%verb%"=="-h" goto show_help
if /i "%verb%"=="-?" goto show_help
if /i "%verb%"=="/?" goto show_help

if /i "%verb%"=="--version" (
    if defined LIBSCRIPT_VERSION ( echo %LIBSCRIPT_VERSION% ) else ( echo dev )
    exit /b 0
)
if /i "%verb%"=="-v" (
    if defined LIBSCRIPT_VERSION ( echo %LIBSCRIPT_VERSION% ) else ( echo dev )
    exit /b 0
)

set "is_action=0"
set "req_version=0"

if /i "%verb%"=="install" ( set "is_action=1" & set "req_version=1" )
if /i "%verb%"=="install_daemon" ( set "is_action=1" & set "req_version=1" )
if /i "%verb%"=="install_service" ( set "is_action=1" & set "req_version=1" )
if /i "%verb%"=="uninstall_daemon" ( set "is_action=1" & set "req_version=1" )
if /i "%verb%"=="uninstall_service" ( set "is_action=1" & set "req_version=1" )
if /i "%verb%"=="remove_daemon" ( set "is_action=1" & set "req_version=1" )
if /i "%verb%"=="remove_service" ( set "is_action=1" & set "req_version=1" )

if /i "%verb%"=="remove" set "is_action=1"
if /i "%verb%"=="uninstall" set "is_action=1"
if /i "%verb%"=="start" set "is_action=1"
if /i "%verb%"=="stop" set "is_action=1"
if /i "%verb%"=="restart" set "is_action=1"
if /i "%verb%"=="logs" set "is_action=1"
if /i "%verb%"=="up" set "is_action=1"
if /i "%verb%"=="down" set "is_action=1"
if /i "%verb%"=="status" set "is_action=1"
if /i "%verb%"=="test" set "is_action=1"

if /i "%verb%"=="run" ( set "is_action=1" & set "req_version=1" )
if /i "%verb%"=="which" ( set "is_action=1" & set "req_version=1" )
if /i "%verb%"=="exec" ( set "is_action=1" & set "req_version=1" )
if /i "%verb%"=="env" ( set "is_action=1" & set "req_version=1" )
if /i "%verb%"=="serve" ( set "is_action=1" & set "req_version=1" )
if /i "%verb%"=="route" ( set "is_action=1" & set "req_version=1" )
if /i "%verb%"=="ls" set "is_action=1"
if /i "%verb%"=="ls-remote" set "is_action=1"
if /i "%verb%"=="download" set "is_action=1"

if "!is_action!"=="1" (
    set "ACTION=%~1"
    set "PACKAGE_NAME=%~2"
    set "VERSION=%~3"
    
    if "!PACKAGE_NAME!"=="" (
        echo Error: package_name is required for !ACTION! 1>&2
        exit /b 1
    )
    
    if "!req_version!"=="1" (
        if "!VERSION!"=="" (
            echo Error: version is required for !ACTION! 1>&2
            exit /b 1
        )
        shift
        shift
        shift
    ) else (
        if "!VERSION!" neq "" (
            if "!VERSION:~0,2!"=="--" (
                set "VERSION="
                shift
                shift
            ) else (
                shift
                shift
                shift
            )
        ) else (
            shift
            shift
        )
    )

    if not "!PACKAGE_NAME!"=="" (
        if not "!VERSION!"=="" (
            for %%F in ("!PACKAGE_NAME!") do set "pkg_upper=%%~nxF"
            for %%A in (
                "a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I"
                "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R"
                "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z" "-=_"
            ) do set "pkg_upper=!pkg_upper:%%~A!"
            set "!pkg_upper!_VERSION=!VERSION!"
        )
    )
) else (
    echo Unknown command: %verb%
    echo Use --help to see available options.
    exit /b 1
)

if /i "%VERSION%"=="latest" set "LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1"
if /i "%VERSION%"=="lts" set "LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1"
if /i "%VERSION%"=="stable" set "LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1"
:parse_args
if "%~1"=="" goto run_action

set "arg=%~1"
if /i "%arg%"=="--help" goto show_help
if /i "%arg%"=="-h" goto show_help
if /i "%arg%"=="-?" goto show_help
if /i "%arg%"=="/?" goto show_help
if /i "%arg%"=="--version" (
    if defined LIBSCRIPT_VERSION ( echo %LIBSCRIPT_VERSION% ) else ( echo dev )
    exit /b 0
)
if /i "%arg%"=="-v" (
    if defined LIBSCRIPT_VERSION ( echo %LIBSCRIPT_VERSION% ) else ( echo dev )
    exit /b 0
)

if /i "%arg:~0,9%"=="--prefix=" (
    set "PREFIX=%arg:~9%"
    shift
    goto parse_args
)

if /i "%arg:~0,15%"=="--service-name=" (
    set "LIBSCRIPT_SERVICE_NAME=%arg:~15%"
    shift
    goto parse_args
)

if /i "%arg:~0,13%"=="--log-driver=" (
    set "LIBSCRIPT_LOG_DRIVER=%arg:~13%"
    shift
    goto parse_args
)

if /i "%arg:~0,11%"=="--log-host=" (
    set "LIBSCRIPT_LOG_HOST=%arg:~11%"
    shift
    goto parse_args
)

if /i "%arg:~0,11%"=="--log-port=" (
    set "LIBSCRIPT_LOG_PORT=%arg:~11%"
    shift
    goto parse_args
)

if /i "%arg:~0,10%"=="--log-cmd=" (
    set "LIBSCRIPT_LOG_CMD=%arg:~10%"
    shift
    goto parse_args
)

if /i "%arg:~0,10%"=="--secrets=" (
    set "LIBSCRIPT_SECRETS=%arg:~10%"
    shift
    goto parse_args
)

if "%arg:~0,2%"=="--" (
    for /f "tokens=1,* delims==" %%a in ("%arg:~2%") do (
        set "key=%%a"
        set "val=%%b"
        set "!key!=!val!"
    )
) else (
    if /i "!ACTION!"=="run" goto run_action
    if /i "!ACTION!"=="exec" goto run_action
    if /i "!ACTION!"=="env" goto run_action
    if /i "!ACTION!"=="serve" goto run_action
    if /i "!ACTION!"=="route" goto run_action
    echo Unknown argument: %arg%
    echo Use --help to see available options.
    exit /b 1
)

shift
goto parse_args

:show_help
echo Usage: %~nx0 [COMMAND] [PACKAGE_NAME] [VERSION] [OPTIONS]
echo.
echo Commands:
echo   install ^<package_name^> ^<version^>
echo   remove ^<package_name^> [version]
echo   uninstall ^<package_name^> [version]
echo   install_daemon ^<package_name^> ^<version^>
echo   install_service ^<package_name^> ^<version^>
echo   uninstall_daemon ^<package_name^> ^<version^>
echo   uninstall_service ^<package_name^> ^<version^>
echo   remove_daemon ^<package_name^> ^<version^>
echo   remove_service ^<package_name^> ^<version^>
echo   start ^<package_name^> [version]
echo   stop ^<package_name^> [version]
echo   restart ^<package_name^> [version]
echo   logs ^<package_name^> [version] [-f|--follow]
echo   status ^<package_name^> [version]
echo   health ^<package_name^> [version]
echo   test ^<package_name^> [version]
echo   run ^<package_name^> ^<version^> [args...]
echo   which ^<package_name^> ^<version^>
echo   exec ^<package_name^> ^<version^> ^<cmd^> [args...]
echo   ls ^<package_name^>
echo   download ^<package_name^> ^<version^>
echo   ls-remote ^<package_name^> [version]
echo.
echo Description:
if exist "%SCHEMA_FILE%" (
    jq -r "if .description then .description else \"\" end" "%SCHEMA_FILE%" 2^>nul
)
echo.
echo Available Options:
if exist "%SCHEMA_FILE%" (
    jq -r ".properties | to_entries[] | \"--\(.key)=VALUE|\(.value.description) [default: \(.value.default // \"none\")]\"" "%SCHEMA_FILE%" > "%temp%\schema_help.txt" 2^>nul
    jq -r ".properties | to_entries[] | select(.value.is_libscript_dependency == true) | \"--\(.key)_STRATEGY=VALUE|Strategy for \(.key) (reuse, install-alongside, upgrade, downgrade, overwrite) [default: reuse]\"" "%SCHEMA_FILE%" >> "%temp%\schema_help.txt" 2^>nul
    if errorlevel 1 (
        echo   ^(jq is required to parse vars.schema.json for dynamic options^)
        echo   See %SCHEMA_FILE% for available variables.
    ) else (
        for /f "tokens=1,* delims=|" %%a in (%temp%\schema_help.txt) do (
            echo   %%a
            echo       %%b
        )
        del "%temp%\schema_help.txt" 2^>nul
    )
) else (
    echo   See %SCHEMA_FILE% for available variables.
)
echo.
echo   --prefix=^<dir^>                      Set local installation prefix
echo   --service-name=^<name^>               Set a custom service/daemon name
echo   --log-driver=^<driver^>               Set log driver (file, syslog, tcp, json_file, custom) [default: file]
echo   --log-host=^<host^>                   Set log host for tcp driver
echo   --log-port=^<port^>                   Set log port for tcp driver
echo   --log-cmd=^<cmd^>                     Set custom log command
echo   --secrets=^<dir^|url^>                 Save generated secrets to a directory or OpenBao/Vault URL
echo   --help, -h, /?                      Show this help message
echo   --version, -v                       Show version
echo.
exit /b 0

:run_action
if /i "!ACTION!"=="run" goto do_cmd
if /i "!ACTION!"=="which" goto do_cmd
if /i "!ACTION!"=="exec" goto do_cmd
if /i "!ACTION!"=="env" goto do_cmd
if /i "!ACTION!"=="serve" goto do_cmd
if /i "!ACTION!"=="route" goto do_cmd
if /i "!ACTION!"=="ls" goto do_cmd
if /i "!ACTION!"=="ls-remote" goto do_cmd
if /i "!ACTION!"=="download" goto do_cmd
if /i "!ACTION!"=="uninstall" goto do_cmd
if /i "!ACTION!"=="remove" goto do_cmd
if /i "!ACTION!"=="uninstall_daemon" goto do_cmd
if /i "!ACTION!"=="uninstall_service" goto do_cmd
if /i "!ACTION!"=="remove_daemon" goto do_cmd
if /i "!ACTION!"=="remove_service" goto do_cmd
if /i "!ACTION!"=="start" goto do_cmd
if /i "!ACTION!"=="stop" goto do_cmd
if /i "!ACTION!"=="restart" goto do_cmd
if /i "!ACTION!"=="status" goto do_cmd
if /i "!ACTION!"=="health" goto do_cmd
if /i "!ACTION!"=="logs" goto do_cmd
if /i "!ACTION!"=="up" goto do_cmd
if /i "!ACTION!"=="down" goto do_cmd

goto run_setup

:do_cmd
if "!PREFIX!"=="" (
    set "INSTALLED_DIR=!LIBSCRIPT_ROOT_DIR!\installed\!PACKAGE_NAME!"
) else (
    set "INSTALLED_DIR=!PREFIX!"
)
set "BIN_PATH=!INSTALLED_DIR!\bin\!PACKAGE_NAME!"

if /i "!ACTION!"=="run" (
    if not exist "!BIN_PATH!.exe" if not exist "!BIN_PATH!.cmd" if not exist "!BIN_PATH!" (
        echo Error: !PACKAGE_NAME! version !VERSION! not installed at !BIN_PATH!
        exit /b 1
    )
    call "!BIN_PATH!" %*
    exit /b !errorlevel!
)
if /i "!ACTION!"=="which" (
    if exist "!BIN_PATH!.exe" ( echo !BIN_PATH!.exe & exit /b 0 )
    if exist "!BIN_PATH!.cmd" ( echo !BIN_PATH!.cmd & exit /b 0 )
    if exist "!BIN_PATH!" ( echo !BIN_PATH! & exit /b 0 )
    echo Not installed: !BIN_PATH!
    exit /b 1
)
if /i "!ACTION!"=="exec" (
    if not exist "!INSTALLED_DIR!\bin" (
        echo Error: !PACKAGE_NAME! version !VERSION! bin directory not found at !INSTALLED_DIR!\bin
        exit /b 1
    )
    set "PATH=!INSTALLED_DIR!\bin;!PATH!"
    call %*
    exit /b !errorlevel!
)
if /i "!ACTION!"=="env" (
    if /i "!FORMAT!"=="powershell" (
        echo $env:PATH="%INSTALLED_DIR%\bin;" + $env:PATH
        if exist "%SCRIPT_DIR%env.cmd" (
            for /f "tokens=1,* delims==" %%a in ('type "%SCRIPT_DIR%env.cmd" ^| findstr /b /c:"set "') do (
                set "key=%%a"
                set "key=!key:~4!"
                echo $env:!key!="%%b"
            )
        )
    ) else if /i "!FORMAT!"=="docker" (
        echo ENV PATH="%INSTALLED_DIR%\bin;%%PATH%%"
        if exist "%SCRIPT_DIR%env.cmd" (
            for /f "tokens=1,* delims==" %%a in ('type "%SCRIPT_DIR%env.cmd" ^| findstr /b /c:"set "') do (
                set "key=%%a"
                set "key=!key:~4!"
                echo ENV !key!="%%b"
            )
        )
    ) else if /i "!FORMAT!"=="docker_compose" (
        echo PATH=%INSTALLED_DIR%\bin;%%PATH%%
        if exist "%SCRIPT_DIR%env.cmd" (
            for /f "tokens=1,* delims==" %%a in ('type "%SCRIPT_DIR%env.cmd" ^| findstr /b /c:"set "') do (
                set "key=%%a"
                set "key=!key:~4!"
                echo !key!=%%b
            )
        )
    ) else if /i "!FORMAT!"=="csh" (
        echo setenv PATH "%INSTALLED_DIR%\bin:$PATH"
        if exist "%SCRIPT_DIR%env.cmd" (
            for /f "tokens=1,* delims==" %%a in ('type "%SCRIPT_DIR%env.cmd" ^| findstr /b /c:"set "') do (
                set "key=%%a"
                set "key=!key:~4!"
                echo setenv !key! "%%b"
            )
        )
    ) else if /i "!FORMAT!"=="sh" (
        echo export PATH="%INSTALLED_DIR%\bin:$PATH"
        if exist "%SCRIPT_DIR%env.cmd" (
            for /f "tokens=1,* delims==" %%a in ('type "%SCRIPT_DIR%env.cmd" ^| findstr /b /c:"set "') do (
                set "key=%%a"
                set "key=!key:~4!"
                echo export !key!="%%b"
            )
        )
    ) else (
        echo set "PATH=!INSTALLED_DIR!\bin;%%PATH%%"
        if exist "%SCRIPT_DIR%env.cmd" (
            type "%SCRIPT_DIR%env.cmd"
        )
    )
    exit /b 0
)
if /i "!ACTION!"=="serve" (
    if not exist "!BIN_PATH!.exe" if not exist "!BIN_PATH!.cmd" if not exist "!BIN_PATH!" (
        echo Error: !PACKAGE_NAME! version !VERSION! not installed at !BIN_PATH!
        exit /b 1
    )
    if "!SERVE_FROM!"=="" set "SERVE_FROM=background-process"
    if "!LOGS_DIR!"=="" (
        if not "!logs_dir!"=="" (
            set "LOGS_DIR=!logs_dir!"
        ) else (
            set "LOGS_DIR=!LIBSCRIPT_ROOT_DIR!\logs"
        )
    )
    if /i "!SERVE_FROM!"=="background-process" (
        if not exist "!LOGS_DIR!" mkdir "!LOGS_DIR!"
        if not "!LIBSCRIPT_SERVICE_NAME!"=="" (
            set "service_name=!LIBSCRIPT_SERVICE_NAME!"
        ) else (
            set "service_name=!PACKAGE_NAME!_!VERSION!"
        )
        set "log_file=!LOGS_DIR!\!service_name!.log"
        set "log_driver=!LIBSCRIPT_LOG_DRIVER!"
        if "!log_driver!"=="" set "log_driver=file"
        echo Starting !service_name! in background ^(log driver: !log_driver!^)...
        
        if /i "!log_driver!"=="file" (
            start "" /b cmd /c ""!BIN_PATH!" %* > "!log_file!" 2>&1"
            echo Logs: !log_file!
        ) else if /i "!log_driver!"=="custom" (
            if "!LIBSCRIPT_LOG_CMD!"=="" (
                echo Error: LIBSCRIPT_LOG_CMD is required for custom log driver 1>&2
                exit /b 1
            )
            start "" /b cmd /c ""!BIN_PATH!" %* 2>&1 | !LIBSCRIPT_LOG_CMD!"
        ) else (
            echo Error: log driver '!log_driver!' is not natively implemented on Windows yet. Use 'file' or 'custom' ^(with --log-cmd^). 1>&2
            exit /b 1
        )
    ) else (
        echo Error: serve_from '!SERVE_FROM!' is not fully implemented yet on Windows. 1>&2
        exit /b 1
    )
    exit /b 0
)
if /i "!ACTION!"=="route" (
    if exist "%SCRIPT_DIR%route.cmd" (
        call "%SCRIPT_DIR%route.cmd" %*
    ) else (
        echo Info: Route action is not natively supported for !PACKAGE_NAME! yet ^(no route.cmd found^). 1>&2
        exit /b 0
    )
    exit /b !errorlevel!
)
if /i "!ACTION!"=="ls" (
    if exist "!INSTALLED_DIR!" (
        echo Installed at !INSTALLED_DIR!:
        dir /b "!INSTALLED_DIR!"
    ) else (
        echo Error: No installed versions found at !INSTALLED_DIR! or listing is not natively supported for this package. 1>&2
        exit /b 1
    )
    exit /b 0
)
if /i "!ACTION!"=="ls-remote" (
    echo Error: Remote listing not natively supported for generic packages yet. 1>&2
    exit /b 1
) else if /i "!ACTION!"=="download" (
    if exist "%SCRIPT_DIR%download.cmd" (
        call "%SCRIPT_DIR%download.cmd"
    ) else (
        echo Info: Download action is not natively supported for !PACKAGE_NAME! yet ^(no download.cmd found^). 1>&2
        exit /b 0
    )
    exit /b !errorlevel!
) else if /i "!ACTION!"=="uninstall" goto run_uninstall
) else if /i "!ACTION!"=="remove" goto run_uninstall
) else if /i "!ACTION!"=="uninstall_daemon" goto run_uninstall
) else if /i "!ACTION!"=="uninstall_service" goto run_uninstall
) else if /i "!ACTION!"=="remove_daemon" goto run_uninstall
) else if /i "!ACTION!"=="remove_service" goto run_uninstall
) else if /i "!ACTION!"=="start" (
    set "service_name=libscript_!PACKAGE_NAME!"
    if not "!LIBSCRIPT_SERVICE_NAME!"=="" set "service_name=!LIBSCRIPT_SERVICE_NAME!"
    echo Starting !service_name!...
    sc start "!service_name!"
    exit /b !errorlevel!
) else if /i "!ACTION!"=="up" (
    set "service_name=libscript_!PACKAGE_NAME!"
    if not "!LIBSCRIPT_SERVICE_NAME!"=="" set "service_name=!LIBSCRIPT_SERVICE_NAME!"
    echo Starting !service_name!...
    sc start "!service_name!"
    exit /b !errorlevel!
) else if /i "!ACTION!"=="stop" (
    set "service_name=libscript_!PACKAGE_NAME!"
    if not "!LIBSCRIPT_SERVICE_NAME!"=="" set "service_name=!LIBSCRIPT_SERVICE_NAME!"
    echo Stopping !service_name!...
    sc stop "!service_name!"
    exit /b !errorlevel!
) else if /i "!ACTION!"=="down" (
    set "service_name=libscript_!PACKAGE_NAME!"
    if not "!LIBSCRIPT_SERVICE_NAME!"=="" set "service_name=!LIBSCRIPT_SERVICE_NAME!"
    echo Stopping !service_name!...
    sc stop "!service_name!"
    exit /b !errorlevel!
) else if /i "!ACTION!"=="restart" (
    set "service_name=libscript_!PACKAGE_NAME!"
    if not "!LIBSCRIPT_SERVICE_NAME!"=="" set "service_name=!LIBSCRIPT_SERVICE_NAME!"
    echo Restarting !service_name!...
    sc stop "!service_name!"
    timeout /t 2 /nobreak >nul
    sc start "!service_name!"
    exit /b !errorlevel!
) else if /i "!ACTION!"=="health" (
    set "service_name=libscript_!PACKAGE_NAME!"
    if not "!LIBSCRIPT_SERVICE_NAME!"=="" set "service_name=!LIBSCRIPT_SERVICE_NAME!"
    set "json_file=libscript.json"
    set "healthcheck="
    if exist "!json_file!" jq --version >nul 2>&1 && (
        for /f "delims=" %%H in ('jq -c "if (.deps[\"!PACKAGE_NAME!\"] | type) == \"object\" and .deps[\"!PACKAGE_NAME!\"].healthcheck != null then .deps[\"!PACKAGE_NAME!\"].healthcheck else empty end" "!json_file!" 2^>nul') do (
            set "healthcheck=%%H"
        )
    )
    if not "!healthcheck!"=="" (
        for /f "delims=" %%C in ('echo !healthcheck! ^| jq -r "if type == \"string\" then . elif type == \"object\" and .test then (if (.test | type) == \"array\" then (if .test[0] == \"CMD-SHELL\" then .test[1] else .test | join(\" \") end) else .test end) else empty end" 2^>nul') do (
            set "test_cmd=%%C"
        )
        if not "!test_cmd!"=="" if not "!test_cmd!"=="null" (
            cmd /c "!test_cmd!"
            if !errorlevel! equ 0 (
                echo Status: healthy
                exit /b 0
            ) else (
                echo Status: unhealthy
                exit /b 1
            )
        )
    )
    echo No healthcheck defined, checking status...
    call "%~f0" status !PACKAGE_NAME! !VERSION! %*
    exit /b !errorlevel!
) else if /i "!ACTION!"=="status" (
    set "service_name=libscript_!PACKAGE_NAME!"
    if not "!LIBSCRIPT_SERVICE_NAME!"=="" set "service_name=!LIBSCRIPT_SERVICE_NAME!"
    sc query "!service_name!"
    exit /b !errorlevel!
) else if /i "!ACTION!"=="logs" (
    set "service_name=libscript_!PACKAGE_NAME!"
    if not "!LIBSCRIPT_SERVICE_NAME!"=="" set "service_name=!LIBSCRIPT_SERVICE_NAME!"
    if not "!LOGS_DIR!"=="" (
        set "LOGS_DIR=!LOGS_DIR!"
    ) else if not "!logs_dir!"=="" (
        set "LOGS_DIR=!logs_dir!"
    ) else (
        set "LOGS_DIR=!LIBSCRIPT_ROOT_DIR!\logs"
    )
    set "log_file=!LOGS_DIR!\!service_name!.log"
    set "follow=0"
    set "args=%*"
    echo !args! | findstr /i "\-f" >nul && set "follow=1"
    echo !args! | findstr /i "\-\-follow" >nul && set "follow=1"
    if exist "!log_file!" (
        if "!follow!"=="1" (
        powershell -NoProfile -Command "Get-Content '!log_file!' -Wait -Tail 50"
    ) else (
        powershell -NoProfile -Command "Get-Content '!log_file!' -Tail 50"
    )
    ) else (
        echo No logs found at !log_file!
    )
    exit /b 0
exit /b 0

:run_uninstall
if exist "%SCRIPT_DIR%uninstall.cmd" (
    call "%SCRIPT_DIR%uninstall.cmd"
) else if exist "%LIBSCRIPT_ROOT_DIR%\_lib\_common\uninstall.cmd" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\uninstall.cmd"
) else (
    echo Error: Uninstallation is not natively supported for this package yet. 1^>^&2
    exit /b 1
)
exit /b !errorlevel!
exit /b 0

:run_setup
if /i "!ACTION!"=="install" goto do_install
if /i "!ACTION!"=="install_daemon" goto do_install
if /i "!ACTION!"=="install_service" goto do_install
goto do_run_setup

:do_install
if "!LIBSCRIPT_ROOT_DIR!"=="" (
    set "d=!SCRIPT_DIR!"
    :find_root
    if exist "!d!\ROOT" (
        set "LIBSCRIPT_ROOT_DIR=!d!"
    ) else (
        if not "!d!"=="" (
            for %%I in ("!d!\..") do set "d=%%~fI"
            if not "!d!"=="!SCRIPT_DIR!" goto find_root
        )
    )
    if "!LIBSCRIPT_ROOT_DIR!"=="" set "LIBSCRIPT_ROOT_DIR=."
)

if exist "%SCHEMA_FILE%" (
    jq -r ".properties | to_entries[] | select(.value.is_libscript_dependency == true) | \"\(.key)|\(.value.default // \"\")|\(if .value.enum then .value.enum | join(\",\") else \"\" end)\"" "%SCHEMA_FILE%" > "%temp%\schema_deps.txt" 2^>nul
    for /f "tokens=1,2,3 delims=|" %%K in (%temp%\schema_deps.txt) do (
        set "dep_key=%%K"
        set "dep_default=%%L"
        set "dep_enum=%%M"
        
        call set "dep_val=%%!dep_key!%%"
        if "!dep_val!"=="" (
            set "dep_val=!dep_default!"
            set "!dep_key!=!dep_val!"
        )
        if not "!dep_val!"=="" (
            call set "strategy_val=%%!dep_key!_STRATEGY%%"
            if "!strategy_val!"=="" (
                set "strategy_val=reuse"
                set "!dep_key!_STRATEGY=!strategy_val!"
            )
            echo Checking dependency !dep_val! for !dep_key! ^(strategy: !strategy_val!^)...
            set "is_installed=0"
            where "!dep_val!" >nul 2>&1
            if not errorlevel 1 set "is_installed=1"
            if "!is_installed!"=="0" (
                call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" which "!dep_val!" "latest" >nul 2>&1
                if not errorlevel 1 set "is_installed=1"
            )
            
            if "!is_installed!"=="1" (
                set "do_install=0"
                if /i "!strategy_val!"=="overwrite" set "do_install=1"
                if /i "!strategy_val!"=="upgrade" set "do_install=1"
                if /i "!strategy_val!"=="downgrade" set "do_install=1"
                if /i "!strategy_val!"=="install-alongside" set "do_install=1"
                
                if "!do_install!"=="1" (
                    echo Re-installing/installing-alongside dependency !dep_val!...
                    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install "!dep_val!" "latest"
                    if errorlevel 1 (
                        echo Error: Failed to install dependency !dep_val! 1^>^&2
                        exit /b 1
                    )
                ) else (
                    echo Reusing existing dependency !dep_val!.
                )
            ) else (
                echo Installing missing dependency !dep_val!...
                call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install "!dep_val!" "latest"
                if errorlevel 1 (
                    echo Error: Failed to install dependency !dep_val! 1^>^&2
                    exit /b 1
                )
            )
        )
    )
    del "%temp%\schema_deps.txt" 2^>nul
)

if not "!LIBSCRIPT_SECRETS!"=="" (
    call :do_run_setup
    
    echo !LIBSCRIPT_SECRETS! | findstr /i "^http" >nul
    if not errorlevel 1 (
        echo Warning: HTTP secrets saving to Vault is not fully implemented in batch script yet. 1^>^&2
    ) else (
        if not exist "!LIBSCRIPT_SECRETS!" mkdir "!LIBSCRIPT_SECRETS!"
        set "FORMAT=sh"
        call "%~dp0cli.cmd" env !PACKAGE_NAME! !VERSION! >> "!LIBSCRIPT_SECRETS!\env.sh"
        set "FORMAT=csh"
        call "%~dp0cli.cmd" env !PACKAGE_NAME! !VERSION! >> "!LIBSCRIPT_SECRETS!\env.csh"
        set "FORMAT=powershell"
        call "%~dp0cli.cmd" env !PACKAGE_NAME! !VERSION! >> "!LIBSCRIPT_SECRETS!\env.ps1"
        set "FORMAT=docker"
        call "%~dp0cli.cmd" env !PACKAGE_NAME! !VERSION! >> "!LIBSCRIPT_SECRETS!\env.docker"
        set "FORMAT=docker_compose"
        call "%~dp0cli.cmd" env !PACKAGE_NAME! !VERSION! >> "!LIBSCRIPT_SECRETS!\env.env"
        set "FORMAT=cmd"
        call "%~dp0cli.cmd" env !PACKAGE_NAME! !VERSION! >> "!LIBSCRIPT_SECRETS!\env.cmd"
    )
    exit /b 0
)

:do_run_setup
if exist "%SCRIPT_DIR%setup.cmd" (
    call "%SCRIPT_DIR%setup.cmd"
) else (
    echo Error: setup.cmd not found in %SCRIPT_DIR%
    exit /b 1
)
if /i "!ACTION!"=="install_service" (
    if exist "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_win.ps1" (
        call set "CURRENT_DATA_DIR=%%!pkg_upper!_DATA_DIR%%"
        call set "CURRENT_RUN_AS_USER=%%!pkg_upper!_SERVICE_RUN_AS_USER%%"
        call set "CURRENT_RUN_AS_PASSWORD=%%!pkg_upper!_SERVICE_RUN_AS_PASSWORD%%"
        call set "CURRENT_SERVICE_NAME=%%!pkg_upper!_SERVICE_NAME%%"
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_win.ps1" -PackageName "!PACKAGE_NAME!" -DataDir "!CURRENT_DATA_DIR!" -RunAsUser "!CURRENT_RUN_AS_USER!" -RunAsPassword "!CURRENT_RUN_AS_PASSWORD!" -BinPath "!BIN_PATH!.exe" -CustomServiceName "!CURRENT_SERVICE_NAME!"
    )
)
exit /b 0
