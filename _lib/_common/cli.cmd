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
            set "pkg_upper=!PACKAGE_NAME!"
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
echo   status ^<package_name^> [version]
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
        echo Starting !service_name! in background...
        start "" /b cmd /c ""!BIN_PATH!" %* > "!log_file!" 2>&1"
        echo Logs: !log_file!
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
exit /b 0
