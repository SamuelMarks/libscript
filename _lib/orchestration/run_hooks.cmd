@echo off
:: # run_hooks.cmd
::
:: ## Overview
:: Executes defined lifecycle hooks from an install manifest on Windows.
:: Supports both .hooks and .lifecycle_hooks, working_dir, OS filtering, cmd_windows, and conditions.
::
:: ## Usage
:: Run `run_hooks.cmd <json_file> <hook_type>` (e.g. pre_install, post_install, build, db_migrate, pre_start).

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

set "json_file=%~1"
set "hook_type=%~2"

if "!json_file!"=="" exit /b 0
if "!hook_type!"=="" exit /b 0
if not exist "!json_file!" exit /b 0

for %%P in ("!json_file!") do set "MANIFEST_DIR=%%~dpP"
if "!MANIFEST_DIR:~-1!"=="\" set "MANIFEST_DIR=!MANIFEST_DIR:~0,-1!"

if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" --hydrate "!json_file!"
)

for /f "delims=" %%i in ('jq -c --arg ht "!hook_type!" "((.hooks[$ht] // []) + (.lifecycle_hooks[$ht] // []))[]?" "!json_file!" 2^>nul') do (
    set "hook=%%i"
    call :exec_single_hook
)
exit /b 0

:: ## exec_single_hook
:: Evaluates and executes an individual hook item.
:exec_single_hook
set "first_char=!hook:~0,1!"
if not "!first_char!"=="{" (
    set "raw_cmd=!hook:~1,-1!"
    if not "!raw_cmd!"=="" (
        echo Executing hook: !raw_cmd!
        pushd "!MANIFEST_DIR!"
        call !raw_cmd!
        popd
    )
    exit /b 0
)

set "name=unnamed_hook"
set "cmd="
set "cond="
set "raw_wd=."
set "os_match=1"

for /f "delims=" %%n in ('echo !hook! ^| jq -r ".name // \"unnamed_hook\"" 2^>nul') do set "name=%%n"
for /f "delims=" %%c in ('echo !hook! ^| jq -r ".cmd_windows // .command_windows // .command // empty" 2^>nul') do set "cmd=%%c"
for /f "delims=" %%d in ('echo !hook! ^| jq -r ".condition // empty" 2^>nul') do set "cond=%%d"
for /f "delims=" %%w in ('echo !hook! ^| jq -r ".working_dir // .cwd // \".\"" 2^>nul') do set "raw_wd=%%w"
for /f "delims=" %%o in ('echo !hook! ^| jq -r "(.os // .platform) as $p | if $p == null then \"1\" elif ($p | type) == \"string\" then (if ($p | ascii_downcase) == \"windows\" or ($p | ascii_downcase) == \"all\" then \"1\" else \"0\" end) elif ($p | type) == \"array\" then (if ([ $p[] | ascii_downcase ] | index(\"windows\") != null or index(\"all\") != null) then \"1\" else \"0\" end) else \"1\" end" 2^>nul') do set "os_match=%%o"

if "!os_match!"=="0" (
    echo Skipping hook '!name!': OS filter does not match windows
    exit /b 0
)

set "hook_wd=!MANIFEST_DIR!"
if not "!raw_wd!"=="." (
    if "!raw_wd:~1,1!"==":" (
        set "hook_wd=!raw_wd!"
    ) else (
        set "hook_wd=!MANIFEST_DIR!\!raw_wd:/=\!"
    )
)

set "skip=0"
if not "!cond!"=="" (
    echo !cond! | findstr /b /c:"unless_exists " >nul
    if not errorlevel 1 (
        set "file=!cond:unless_exists =!"
        set "file_win=!file:/=\!"
        if exist "!hook_wd!\!file_win!" set "skip=1"
        if exist "!file_win!" set "skip=1"
        if "!skip!"=="1" echo Skipping hook '!name!': !file! exists
    )
    echo !cond! | findstr /b /c:"if_exists " >nul
    if not errorlevel 1 (
        set "file=!cond:if_exists =!"
        set "file_win=!file:/=\!"
        set "exists_flag=0"
        if exist "!hook_wd!\!file_win!" set "exists_flag=1"
        if exist "!file_win!" set "exists_flag=1"
        if "!exists_flag!"=="0" (
            echo Skipping hook '!name!': !file! does not exist
            set "skip=1"
        )
    )
    echo !cond! | findstr /b /c:"unless_command " >nul
    if not errorlevel 1 (
        set "chk_cmd=!cond:unless_command =!"
        where "!chk_cmd!" >nul 2>nul
        if not errorlevel 1 (
            echo Skipping hook '!name!': command !chk_cmd! already in PATH
            set "skip=1"
        )
    )
)

if "!skip!"=="1" exit /b 0
if "!cmd!"=="" exit /b 0

echo Executing hook '!name!' (in !hook_wd!): !cmd!
pushd "!hook_wd!"
call !cmd!
popd
exit /b 0
