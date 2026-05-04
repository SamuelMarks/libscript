@echo off
setlocal EnableDelayedExpansion
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
