@echo off
:: # create_docker_builder.cmd
::
:: ## Overview
:: Creates Docker builder scripts (`docker_builder.cmd`, `docker_builder_parallel.cmd`, `docker_builder.sh`, `docker_builder_parallel.sh`) on Windows with full CLI option parity (`-p`, `-s`, `-i`, `-v`, `-h`).
::
:: ## Usage
:: docker\create_docker_builder.cmd [-p <prefix>] [-s <suffix>] [-i <input_dir>] [-v] [-h]

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

set "PREFIX=%DOCKER_IMAGE_PREFIX%"
if "!PREFIX!"=="" set "PREFIX=deploysh-"
set "SUFFIX=%DOCKER_IMAGE_SUFFIX%"
if "!SUFFIX!"=="" set "SUFFIX=-latest"
set "INPUT_DIRECTORY="
set "VERBOSE=0"
goto :parse_args

:: ## parse_args
:: Parses command-line flags matching create_docker_builder.sh.
:parse_args
if "%~1"=="" goto :args_done
if /I "%~1"=="--help" goto :show_help_ok
if /I "%~1"=="-?" goto :show_help_ok
if /I "%~1"=="/?" goto :show_help_ok
if /I "%~1"=="-h" goto :show_help_err
if "%~1"=="-p" ( set "PREFIX=%~2" & shift & shift & goto :parse_args )
if "%~1"=="-s" ( set "SUFFIX=%~2" & shift & shift & goto :parse_args )
if "%~1"=="-i" ( set "INPUT_DIRECTORY=%~2" & shift & shift & goto :parse_args )
if "%~1"=="-v" ( set /a "VERBOSE+=1" & shift & goto :parse_args )
shift
goto :parse_args

:: ## args_done
:: Generates idempotent serial and parallel Docker builder scripts in the target directory.
:args_done
if not "!INPUT_DIRECTORY!"=="" pushd "!INPUT_DIRECTORY!"

set "DOCKER_BUILD_ARGS_VAL=%DOCKER_BUILD_ARGS%"
if "!DOCKER_BUILD_ARGS_VAL!"=="" set "DOCKER_BUILD_ARGS_VAL=--progress="plain" --no-cache"

set "BUILDER_SH=docker_builder.sh"
set "BUILDER_PAR_SH=docker_builder_parallel.sh"
set "BUILDER_CMD=docker_builder.cmd"
set "BUILDER_PAR_CMD=docker_builder_parallel.cmd"

(
    echo #^^!/bin/sh
    echo set -feu
    echo.
) > "!BUILDER_SH!"
(
    echo #^^!/bin/sh
    echo set -feu
    echo.
) > "!BUILDER_PAR_SH!"
(
    echo @echo off
    echo :: Auto-generated docker build script
    echo.
) > "!BUILDER_CMD!"
(
    echo @echo off
    echo :: Auto-generated parallel docker build script
    echo.
) > "!BUILDER_PAR_CMD!"

for %%F in (docker\*Dockerfile) do (
    if exist "%%~F" (
        set "_df_win=%%~F"
        set "_df_sh=!_df_win:\=/!"
        set "_base=%%~nxF"
        for /f "tokens=1,2 delims=." %%A in ("!_base!") do (
            set "_tag=%%A"
            set "_name=%%B"
        )
        if "!_name!"=="Dockerfile" set "_name="
        if "!_tag!"=="Dockerfile" (
            set "_name="
            set "_tag="
        )
        >> "!BUILDER_SH!" echo docker build --file '!_df_sh!' !DOCKER_BUILD_ARGS_VAL! --tag '!PREFIX!!_name!':'!_tag!!SUFFIX!' .
        >> "!BUILDER_PAR_SH!" echo docker build --file '!_df_sh!' !DOCKER_BUILD_ARGS_VAL! --tag '!PREFIX!!_name!':'!_tag!!SUFFIX!' . ^&
        >> "!BUILDER_CMD!" echo docker build --file "!_df_win!" !DOCKER_BUILD_ARGS_VAL! --tag "!PREFIX!!_name!":"!_tag!!SUFFIX!" .
        >> "!BUILDER_PAR_CMD!" echo start "" /b docker build --file "!_df_win!" !DOCKER_BUILD_ARGS_VAL! --tag "!PREFIX!!_name!":"!_tag!!SUFFIX!" .
    )
)
>> "!BUILDER_PAR_SH!" echo wait

if not "!INPUT_DIRECTORY!"=="" popd
if "!VERBOSE!" GEQ "1" echo Generated !BUILDER_CMD!, !BUILDER_PAR_CMD!, !BUILDER_SH!, and !BUILDER_PAR_SH!.
exit /b 0

:: ## show_help_ok
:: Displays usage instructions and exits with status 0.
:show_help_ok
call :print_usage
exit /b 0

:: ## show_help_err
:: Displays usage instructions and exits with status 2 matching getopts -h.
:show_help_err
call :print_usage
exit /b 2

:: ## print_usage
:: Prints CLI flags for create_docker_builder.cmd.
:print_usage
echo Usage: %~nx0 [-p prefix] [-s suffix] [-i input_dir] [-v] [-h] >&2
exit /b 0
