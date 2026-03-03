@echo off
setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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
if /i "%cmd%"=="search" goto search_components

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
if /i "%cmd%"=="test" set "is_action=1"
if /i "%cmd%"=="run" ( set "is_action=1" & set "req_version=1" )
if /i "%cmd%"=="which" ( set "is_action=1" & set "req_version=1" )
if /i "%cmd%"=="exec" ( set "is_action=1" & set "req_version=1" )
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
echo   install ^<package_name^> ^<version^>
echo   remove ^<package_name^> [version]
echo   uninstall ^<package_name^> [version]
echo   install_daemon ^<package_name^> ^<version^>
echo   install_service ^<package_name^> ^<version^>
echo   uninstall_daemon ^<package_name^> ^<version^>
echo   run ^<package_name^> ^<version^> [args...]
echo   which ^<package_name^> ^<version^>
echo   exec ^<package_name^> ^<version^> ^<cmd^> [args...]
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