@echo off
:: # preload_assets.cmd
::
:: ## Overview
:: Offline preload asset manager on Windows staging LibScript orchestrator and component payloads into a target root.
::
:: ## Usage
:: _lib\package-managers\msi-rs\preloader\preload_assets.cmd [target_dir] [component_list...]

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

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help
goto :main

:: ## show_help
:: Displays usage instructions and supported options.
:show_help
echo Usage: %~nx0 [target_dir] [component_list...]
echo Stages offline components and LibScript orchestrator into target sysroot on Windows.
echo.
echo Options:
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:: ## main
:: Copies libscript.cmd and stages each requested component into the target cache directory idempotently.
:main
set "REPO_ROOT=!LIBSCRIPT_ROOT_DIR!"
set "TARGET_DIR=%~1"
if "!TARGET_DIR!"=="" set "TARGET_DIR=C:\libscript_target"
if not "%~1"=="" shift

set "CACHE_DIR=!TARGET_DIR!\opt\libscript\cache"
set "BIN_STAGE=!TARGET_DIR!\usr\local\bin"
if not exist "!CACHE_DIR!" mkdir "!CACHE_DIR!"
if not exist "!BIN_STAGE!" mkdir "!BIN_STAGE!"

echo [PRELOAD] Staging offline LibScript payloads into !CACHE_DIR!...
if exist "!REPO_ROOT!\libscript.cmd" copy /y "!REPO_ROOT!\libscript.cmd" "!BIN_STAGE!\libscript.cmd" >nul
if exist "!REPO_ROOT!\libscript.sh" copy /y "!REPO_ROOT!\libscript.sh" "!BIN_STAGE!\libscript.sh" >nul
goto :stage_loop

:: ## stage_loop
:: Iterates remaining CLI arguments and stages matching component recipes.
:stage_loop
if "%~1"=="" goto :stage_done
set "_COMP=%~1"
echo           Preloading component: !_COMP!...
if not exist "!CACHE_DIR!\!_COMP!" mkdir "!CACHE_DIR!\!_COMP!"
if exist "!REPO_ROOT!\_lib\!_COMP!" (
    xcopy /E /I /Y /Q "!REPO_ROOT!\_lib\!_COMP!" "!CACHE_DIR!\!_COMP!" >nul 2>&1
) else (
    for /d %%C in ("!REPO_ROOT!\_lib\*") do (
        if exist "%%~fC\!_COMP!\manifest.json" (
            xcopy /E /I /Y /Q "%%~fC\!_COMP!" "!CACHE_DIR!\!_COMP!" >nul 2>&1
        )
    )
)
shift
goto :stage_loop

:: ## stage_done
:: Writes completion status after all requested components are staged.
:stage_done
> "!TARGET_DIR!\.libscript_preloaded.stamp" echo preloaded
echo [OK] Offline component staging completed in !TARGET_DIR!.
exit /b 0
