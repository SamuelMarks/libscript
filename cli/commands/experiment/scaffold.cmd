@echo off
:: # scaffold.cmd
:: ## Overview
:: Scaffolds a compliant `experiments\<suite-id>\` research plugin directory on Windows.
:: ## Usage
:: scaffold.cmd <suite-id> [--title=<title>] [--substrate=<substrate>] [--out-root=<dir>]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
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
if exist "!d!\libscript.cmd" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
if exist "!d!\ROOT" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" ( echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2 & exit /b 1 )
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found
where sh >nul 2>&1
if not errorlevel 1 (
    sh "!SCRIPT_DIR!\scaffold.sh" %*
    exit /b !errorlevel!
)
set "SUITE_ID=%~1"
if "!SUITE_ID!"=="" ( echo [ERROR] suite-id required >&2 & exit /b 1 )
set "SDIR=!LIBSCRIPT_ROOT_DIR!\experiments\!SUITE_ID!"
if not exist "!SDIR!" mkdir "!SDIR!"
jq -n --arg id "!SUITE_ID!" "{id:$id,title:(\"Empirical Suite: \" + $id),protocol_version:\"1.0.0\",substrate:\"local-native\",subsuites:[{id:\"E0\",title:\"Baseline\"}]}" > "!SDIR!\suite.json"
echo {} > "!SDIR!\vars.schema.json"
echo # !SUITE_ID! > "!SDIR!\README.md"
exit /b 0
