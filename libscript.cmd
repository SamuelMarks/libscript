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

    echo if .deps then .deps ^| to_entries[] ^| "\(.key) \(if (.value ^| type) == \"string\" then .value else (.value.version // \"latest\") end) \(if (.value ^| type) == \"object\" and .value.override then .value.override else \"\" end)" else empty end > "%temp%\libscript_deps.jq"
    
    REM Parallel Download Phase
    echo Downloading dependencies in parallel...
    for /f "tokens=1,2,3" %%a in ('jq -r -f "%temp%\libscript_deps.jq" "!json_file!" 2^>nul') do (
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
    for /f "tokens=1,2,3" %%a in ('jq -r -f "%temp%\libscript_deps.jq" "!json_file!" 2^>nul') do (
        if not "%%c"=="" if not "%%c"=="null" (
            echo Skipping installation of %%a ^(override provided: %%c^)
        ) else (
            echo Installing %%a %%b...
            call "%~dp0libscript.cmd" install "%%a" "%%b"
        )
    )
    if exist "%temp%\libscript_deps.jq" del "%temp%\libscript_deps.jq"
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
if /i "%~2"=="docker" (
    echo FROM debian:bookworm-slim
    echo ENV LC_ALL=C.UTF-8 LANG=C.UTF-8
    echo COPY . /opt/libscript
    echo WORKDIR /opt/libscript
    shift
    shift
    :docker_loop
    if not "%~1"=="" (
        set "pkg=%~1"
        set "ver=%~2"
        if "!ver!"=="" set "ver=latest"
        echo RUN ./libscript.sh install !pkg! !ver!
        
        REM Call libscript.sh env to get docker formatted ENV vars, not cmd because we're emitting a linux dockerfile
        set "PREFIX=/opt/libscript/installed/!pkg!"
        for /f "delims=" %%i in ('call "%~dp0libscript.cmd" env !pkg! !ver! --format=docker 2^>nul') do (
            echo %%i | findstr /b /v "ENV STACK=" | findstr /b /v "ENV SCRIPT_NAME="
        )
        
        if not "%~2"=="" (
            shift
            shift
        ) else (
            shift
        )
        goto docker_loop
    ) else (
        if exist "libscript.json" (
            jq --version >nul 2>&1
            if not errorlevel 1 (
                echo if .deps then .deps ^| to_entries[] ^| "\(.key) \(if (.value ^| type) == \"string\" then .value else (.value.version // \"latest\") end) \(if (.value ^| type) == \"object\" and .value.override then .value.override else \"\" end)" else empty end > "%temp%\libscript_deps.jq"
                for /f "tokens=1,2,3" %%a in ('jq -r -f "%temp%\libscript_deps.jq" "libscript.json" 2^>nul') do (
                    if not "%%c"=="" if not "%%c"=="null" (
                        set "pkg_up=%%a"
                        for %%A in ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z" "-=_") do set "pkg_up=!pkg_up:%%~A!"
                        echo ENV !pkg_up!_URL="%%c"
                    ) else (
                        echo RUN ./libscript.sh install %%a %%b
                        set "PREFIX=/opt/libscript/installed/%%a"
                        for /f "delims=" %%i in ('call "%~dp0libscript.cmd" env %%a %%b --format=docker 2^>nul') do (
                            echo %%i | findstr /b /v "ENV STACK=" | findstr /b /v "ENV SCRIPT_NAME="
                        )
                    )
                )
                if exist "%temp%\libscript_deps.jq" del "%temp%\libscript_deps.jq"
            ) else (
                echo RUN ./install_gen.sh
            )
        ) else (
            echo RUN ./install_gen.sh
        )
    )
    exit /b 0
) else if /i "%~2"=="docker_compose" (
    echo version: '3.8'
    echo services:
    echo   libscript-app:
    echo     build:
    echo       context: .
    echo       dockerfile: Dockerfile
    
    if not "%~3"=="" (
        echo     environment:
        shift
        shift
        :docker_compose_loop
        if not "%~1"=="" (
            set "pkg=%~1"
            set "ver=%~2"
            if "!ver!"=="" set "ver=latest"
            
            set "PREFIX=/opt/libscript/installed/!pkg!"
            for /f "delims=" %%i in ('call "%~dp0libscript.cmd" env !pkg! !ver! --format=docker_compose 2^>nul') do (
                echo %%i | findstr /b /v "STACK=" | findstr /b /v "SCRIPT_NAME=" > "%temp%\libscript_dc.txt"
                for /f "delims=" %%j in (%temp%\libscript_dc.txt) do echo       - %%j
            )
            
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
                echo     environment:
                echo if .deps then .deps ^| to_entries[] ^| "\(.key) \(if (.value ^| type) == \"string\" then .value else (.value.version // \"latest\") end) \(if (.value ^| type) == \"object\" and .value.override then .value.override else \"\" end)" else empty end > "%temp%\libscript_deps_dc.jq"
                for /f "tokens=1,2,3" %%a in ('jq -r -f "%temp%\libscript_deps_dc.jq" "libscript.json" 2^>nul') do (
                    if not "%%c"=="" if not "%%c"=="null" (
                        set "pkg_up=%%a"
                        for %%A in ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z" "-=_") do set "pkg_up=!pkg_up:%%~A!"
                        echo       - !pkg_up!_URL="%%c"
                    ) else (
                        set "PREFIX=/opt/libscript/installed/%%a"
                        for /f "delims=" %%i in ('call "%~dp0libscript.cmd" env %%a %%b --format=docker_compose 2^>nul') do (
                            echo %%i | findstr /b /v "STACK=" | findstr /b /v "SCRIPT_NAME=" > "%temp%\libscript_dc.txt"
                            for /f "delims=" %%j in (%temp%\libscript_dc.txt) do echo       - %%j
                        )
                    )
                )
                if exist "%temp%\libscript_deps_dc.jq" del "%temp%\libscript_deps_dc.jq"
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
                echo if .deps then .deps ^| to_entries[] ^| "\(.key) \(if (.value ^| type) == \"string\" then .value else (.value.version // \"latest\") end)" else empty end > "%temp%\libscript_deps_tui.jq"
                for /f "tokens=1,2" %%a in ('jq -r -f "%temp%\libscript_deps_tui.jq" "libscript.json" 2^>nul') do (
                    echo set "ps_script=^!ps_script^![pscustomobject]@{Name='%%a';Version='%%b'},"
                )
                if exist "%temp%\libscript_deps_tui.jq" del "%temp%\libscript_deps_tui.jq"
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
    
    echo set "ps_script=^!ps_script:~0,-1^!); $selected = $items | Out-GridView -Title 'LibScript Installer - Select components' -PassThru; foreach ($s in $selected) { Write-Output \"$($s.Name) $($s.Version)\" }"
    echo for /f "tokens=1,2" %%%%a in ^('powershell -Command "^!ps_script^!"'^) do ^(
    echo     if not "%%%%a"=="" ^(
    echo         echo Installing %%%%a %%%%b...
    echo         call "%%~dp0libscript.cmd" install "%%%%a" "%%%%b"
    echo     ^)
    echo ^)
    exit /b 0
) else if /i "%~2"=="msi" (
    goto install_gen_common
) else if /i "%~2"=="innosetup" (
    goto install_gen_common
) else if /i "%~2"=="nsis" (
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
exit /b 1

:generate_msi
echo ^<?xml version="1.0" encoding="UTF-8"?^>
echo ^<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi"^>
echo   ^<Product Id="*" Name="!APP_NAME!" Language="1033" Version="!APP_VERSION!" Manufacturer="!APP_PUBLISHER!" UpgradeCode="!UPGRADE_CODE!"^>
echo     ^<Package InstallerVersion="200" Compressed="yes" InstallScope="!install_scope!" Description="!WELCOME_TEXT!" /^>
echo     ^<Media Id="1" Cabinet="media1.cab" EmbedCab="yes" /^>
if not "!ICON_PATH!"=="" (
    echo     ^<Icon Id="AppIcon.ico" SourceFile="!ICON_PATH!"/^>
    echo     ^<Property Id="ARPPRODUCTICON" Value="AppIcon.ico" /^>
)
if not "!APP_URL!"=="" echo     ^<Property Id="ARPURLINFOABOUT" Value="!APP_URL!" /^>
echo     ^<Directory Id="TARGETDIR" Name="SourceDir"^>
echo       ^<Directory Id="ProgramFilesFolder"^>
echo         ^<Directory Id="INSTALLFOLDER" Name="!APP_NAME!" /^>
echo       ^<Directory/^>
echo     ^</Directory/^>
echo     ^<Feature Id="MainFeature" Title="Main Feature" Level="1"^>
echo       ^<ComponentGroupRef Id="ProductComponents" /^>
echo     ^</Feature/^>
echo     ^<!-- Custom Actions for Installation --^>
if not "%~1"=="" (
    :msi_loop
    if not "%~1"=="" (
        set "pkg=%~1"
        set "ver=%~2"
        if "!ver!"=="" set "ver=latest"
        echo     ^<CustomAction Id="Install!pkg!" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c libscript.cmd install !pkg! !ver!" Execute="deferred" Return="check" Impersonate="no" /^>
        if not "%~2"=="" ( shift & shift ) else ( shift )
        goto msi_loop
    )
) else (
    if exist "libscript.json" (
        jq --version >nul 2>&1
        if not errorlevel 1 (
            echo if .deps then .deps ^| to_entries[] ^| "\(.key) \(if (.value ^| type) == \"string\" then .value else (.value.version // \"latest\") end)" else empty end > "%temp%\libscript_deps_msi.jq"
            for /f "tokens=1,2" %%a in ('jq -r -f "%temp%\libscript_deps_msi.jq" "libscript.json" 2^>nul') do (
                echo     ^<CustomAction Id="Install%%a" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c libscript.cmd install %%a %%b" Execute="deferred" Return="check" Impersonate="no" /^>
            )
            if exist "%temp%\libscript_deps_msi.jq" del "%temp%\libscript_deps_msi.jq"
        )
    )
)
echo     ^<InstallExecuteSequence^>
echo       ^<Custom Action="InstallMain" After="InstallFiles"^>NOT Installed^</Custom^>
echo     ^</InstallExecuteSequence^>
echo   ^</Product^>
echo   ^<Fragment^>
echo     ^<ComponentGroup Id="ProductComponents" Directory="INSTALLFOLDER"^>
echo       ^<!-- Add your files here --^>
echo     ^</ComponentGroup^>
echo   ^</Fragment^>
echo ^</Wix^>
exit /b 0

:generate_inno
echo [Setup]
echo AppName=!APP_NAME!
echo AppVersion=!APP_VERSION!
echo AppPublisher=!APP_PUBLISHER!
if not "!APP_URL!"=="" (
    echo AppPublisherURL=!APP_URL!
    echo AppSupportURL=!APP_URL!
    echo AppUpdatesURL=!APP_URL!
)
echo DefaultDirName={autopf}\!APP_NAME!
echo PrivilegesRequired=!inno_priv!
echo OutputDir=.
echo OutputBaseFilename=!OUT_FILE!
if not "!UPGRADE_CODE!"=="PUT-GUID-HERE" echo AppId=!UPGRADE_CODE!
if not "!ICON_PATH!"=="" echo SetupIconFile=!ICON_PATH!
if not "!IMAGE_PATH!"=="" echo WizardImageFile=!IMAGE_PATH!
if not "!LICENSE_PATH!"=="" echo LicenseFile=!LICENSE_PATH!
echo.
echo [Run]
if not "%~1"=="" (
    :inno_loop
    if not "%~1"=="" (
        set "pkg=%~1"
        set "ver=%~2"
        if "!ver!"=="" set "ver=latest"
        echo Filename: "cmd.exe"; Parameters: "/c libscript.cmd install !pkg! !ver!"; Flags: runhidden
        if not "%~2"=="" ( shift & shift ) else ( shift )
        goto inno_loop
    )
) else (
    if exist "libscript.json" (
        jq --version >nul 2>&1
        if not errorlevel 1 (
            echo if .deps then .deps ^| to_entries[] ^| "\(.key) \(if (.value ^| type) == \"string\" then .value else (.value.version // \"latest\") end)" else empty end > "%temp%\libscript_deps_inno.jq"
            for /f "tokens=1,2" %%a in ('jq -r -f "%temp%\libscript_deps_inno.jq" "libscript.json" 2^>nul') do (
                echo Filename: "cmd.exe"; Parameters: "/c libscript.cmd install %%a %%b"; Flags: runhidden
            )
            if exist "%temp%\libscript_deps_inno.jq" del "%temp%\libscript_deps_inno.jq"
        )
    )
)
exit /b 0

:generate_nsis
echo !define APP_NAME "!APP_NAME!"
echo !define APP_VERSION "!APP_VERSION!"
echo !define APP_PUBLISHER "!APP_PUBLISHER!"
echo Name "!APP_NAME! !APP_VERSION!"
echo OutFile "!OUT_FILE!.exe"
echo InstallDir "$PROGRAMFILES\!APP_NAME!"
echo RequestExecutionLevel !nsis_admin!
echo.
echo VIProductVersion "!APP_VERSION!"
echo VIAddVersionKey "ProductName" "!APP_NAME!"
echo VIAddVersionKey "CompanyName" "!APP_PUBLISHER!"
echo VIAddVersionKey "FileDescription" "!WELCOME_TEXT!"
echo VIAddVersionKey "FileVersion" "!APP_VERSION!"
if not "!ICON_PATH!"=="" echo Icon "!ICON_PATH!"
echo.
if not "!LICENSE_PATH!"=="" echo Page license "" "!LICENSE_PATH!"
echo Page instfiles
echo.
echo Section "MainSection" SEC01
if not "%~1"=="" (
    :nsis_loop
    if not "%~1"=="" (
        set "pkg=%~1"
        set "ver=%~2"
        if "!ver!"=="" set "ver=latest"
        echo   ExecWait 'cmd.exe /c libscript.cmd install !pkg! !ver!'
        if not "%~2"=="" ( shift & shift ) else ( shift )
        goto nsis_loop
    )
) else (
    if exist "libscript.json" (
        jq --version >nul 2>&1
        if not errorlevel 1 (
            echo if .deps then .deps ^| to_entries[] ^| "\(.key) \(if (.value ^| type) == \"string\" then .value else (.value.version // \"latest\") end)" else empty end > "%temp%\libscript_deps_nsis.jq"
            for /f "tokens=1,2" %%a in ('jq -r -f "%temp%\libscript_deps_nsis.jq" "libscript.json" 2^>nul') do (
                echo   ExecWait 'cmd.exe /c libscript.cmd install %%a %%b'
            )
            if exist "%temp%\libscript_deps_nsis.jq" del "%temp%\libscript_deps_nsis.jq"
        )
    )
)
echo SectionEnd
exit /b 0
) else (
    echo Error: Unsupported package format '%~2'. 1^>&2
    exit /b 1
)