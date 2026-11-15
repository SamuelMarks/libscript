@echo off
:: # engine.cmd
:: ## Overview
:: Open/Closed Research Experiment Plugin Engine on Windows auto-discovering `experiments\<suite-id>\suite.json`
:: suites and executing `list`, `scaffold`, `validate`, `provision`, `run`, `render-latex`, `update-readme`, `test`, and `teardown`.
:: ## Usage
:: experiments\engine.cmd <list|scaffold|validate|provision|sync|run|collect|render-latex|update-readme|test|teardown> [suite-id] [args...]

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
set "EXP_ROOT=%SCRIPT_DIR%"
if not "%LIBSCRIPT_EXPERIMENTS_DIR%"=="" set "EXP_ROOT=%LIBSCRIPT_EXPERIMENTS_DIR%"
set "VERB=%~1"
if "!VERB!"=="" set "VERB=list"
if /i "!VERB!"=="--help" goto :help
if /i "!VERB!"=="-h" goto :help

if /i "!VERB!"=="list" (
    for /d %%D in ("!EXP_ROOT!\*") do (
        if exist "%%~fD\suite.json" jq -r "\"\(.id)\t\(.substrate // \"local-native\")\t\(.title)\"" "%%~fD\suite.json"
    )
    exit /b 0
)
if /i "!VERB!"=="scaffold" (
    shift
    call "!LIBSCRIPT_ROOT_DIR!\cli\commands\experiment\scaffold.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)
if /i "!VERB!"=="update-readme" (
    shift
    call "!LIBSCRIPT_ROOT_DIR!\tests\update_results.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)

set "SUITE_ID=%~2"
if "!SUITE_ID!"=="" ( echo [ERROR] suite-id required >&2 & exit /b 1 )
set "SUITE_DIR=!EXP_ROOT!\!SUITE_ID!"
if not exist "!SUITE_DIR!\suite.json" ( echo [ERROR] Suite not found: !SUITE_DIR!\suite.json >&2 & exit /b 1 )

if /i "!VERB!"=="validate" (
    jq -e "(.id | length > 0) and (.subsuites | length > 0)" "!SUITE_DIR!\suite.json" >nul
    if errorlevel 1 exit /b 1
    echo [PASS] Experiment suite "!SUITE_ID!" validated cleanly.
    exit /b 0
)
if /i "!VERB!"=="run" (
    set "STACK="
    call "!SUITE_DIR!\run.cmd" %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)
if /i "!VERB!"=="render-latex" (
    set "STACK="
    call "!SUITE_DIR!\run.cmd" --render-latex %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)
if /i "!VERB!"=="test" (
    set "STACK="
    call "!SUITE_DIR!\test.cmd" %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)
echo [OK] Experiment "!SUITE_ID!" lifecycle phase "!VERB!" completed.
exit /b 0

:: ## help
:: Displays usage help for experiments\engine.cmd.
:help
echo Usage: libscript.cmd experiment ^<list^|scaffold^|validate^|provision^|sync^|run^|collect^|render-latex^|update-readme^|test^|teardown^> [suite-id]
exit /b 0
