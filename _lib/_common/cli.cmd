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
if /i "%verb%"=="ls" set "is_action=1"
if /i "%verb%"=="ls-remote" set "is_action=1"

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

if "%arg:~0,2%"=="--" (
    for /f "tokens=1,* delims==" %%a in ("%arg:~2%") do (
        set "key=%%a"
        set "val=%%b"
        set "!key!=!val!"
    )
) else (
    if /i "!ACTION!"=="run" goto run_action
    if /i "!ACTION!"=="exec" goto run_action
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
echo   --help, -h, /?                      Show this help message
echo   --version, -v                       Show version
echo.
exit /b 0

:run_action
if /i "!ACTION!"=="run" goto do_cmd
if /i "!ACTION!"=="which" goto do_cmd
if /i "!ACTION!"=="exec" goto do_cmd
if /i "!ACTION!"=="ls" goto do_cmd
if /i "!ACTION!"=="ls-remote" goto do_cmd

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
if /i "!ACTION!"=="ls" (
    if exist "!INSTALLED_DIR!" (
        echo Installed at !INSTALLED_DIR!:
        dir /b "!INSTALLED_DIR!"
    ) else (
        echo No installed versions found at !INSTALLED_DIR!
    )
    exit /b 0
)
if /i "!ACTION!"=="ls-remote" (
    echo Remote listing not natively supported for generic packages yet.
    exit /b 0
)
exit /b 0

:run_setup
if exist "%SCRIPT_DIR%setup.cmd" (
    call "%SCRIPT_DIR%setup.cmd"
) else (
    echo Error: setup.cmd not found in %SCRIPT_DIR%
    exit /b 1
)
