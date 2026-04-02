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
