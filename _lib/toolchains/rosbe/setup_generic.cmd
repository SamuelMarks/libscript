@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Generic Windows setup module for ReactOS Build Environment (rosbe).
:: Composes cmake and ninja via libscript.cmd and provisions isolated i386/amd64 toolchain directories.
::
:: ## Usage
:: _lib\toolchains\rosbe\setup_generic.cmd

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

if "%ACTION%"=="" set "ACTION=install"
if "%ROSBE_VERSION%"=="" (
    if not "%LIBSCRIPT_ROSBE_VERSION%"=="" (
        set "ROSBE_VERSION=%LIBSCRIPT_ROSBE_VERSION%"
    ) else (
        set "ROSBE_VERSION=2.2.1"
    )
)
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if /i "%ACTION%"=="ls" goto :action_generic
if /i "%ACTION%"=="use" goto :action_generic
if /i "%ACTION%"=="ls-remote" goto :action_ls_remote
if /i "%ACTION%"=="download" goto :action_download
if /i "%ACTION%"=="install" goto :action_install
goto :action_generic

:: ## action_ls_remote
:: Lists known RosBE versions.
:action_ls_remote
echo 2.2.0
echo 2.2.1
exit /b 0

:: ## action_download
:: Downloads custom RosBE archive when configured and online.
:action_download
if "%LIBSCRIPT_OFFLINE%"=="1" exit /b 0
set "_URL=%ROSBE_DOWNLOAD_URL%"
if "!_URL!"=="" set "_URL=%LIBSCRIPT_ROSBE_URL%"
if "!_URL!"=="" exit /b 0
if "%DOWNLOAD_DIR%"=="" set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
if not exist "%DOWNLOAD_DIR%\rosbe" mkdir "%DOWNLOAD_DIR%\rosbe"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!_URL!" "%DOWNLOAD_DIR%\rosbe\RosBE-%ROSBE_VERSION%.7z" "SKIP"
exit /b 0

:: ## action_install
:: Stages isolated RosBE directories and wrapper script idempotently.
:action_install
set "_VER=%ROSBE_VERSION%"
if /i "!_VER!"=="latest" set "_VER=2.2.1"
set "_INST_DIR=%LIBSCRIPT_ROSBE_INSTALL_DIR%"
if "!_INST_DIR!"=="" set "_INST_DIR=%LIBSCRIPT_HOME%\rosbe\!_VER!"
set "_STAMP=!_INST_DIR!\.stamp.rosbe"
if exist "!_INST_DIR!\bin\rosbe.cmd" if exist "!_STAMP!" (
    echo [SKIP] rosbe !_VER! is already installed at !_INST_DIR!.
    exit /b 0
)
if not "%LIBSCRIPT_OFFLINE%"=="1" (
    where cmake >nul 2>&1
    if errorlevel 1 call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install cmake latest
    where ninja >nul 2>&1
    if errorlevel 1 call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install ninja latest
)
if not exist "!_INST_DIR!\bin" mkdir "!_INST_DIR!\bin"
if not exist "!_INST_DIR!\i386\bin" mkdir "!_INST_DIR!\i386\bin"
if not exist "!_INST_DIR!\amd64\bin" mkdir "!_INST_DIR!\amd64\bin"
echo i686-w64-mingw32> "!_INST_DIR!\targets.list"
(
    echo @echo off
    echo if /i "%%~1"=="--version" ^( echo RosBE !_VER! ^& exit /b 0 ^)
    echo call "%LIBSCRIPT_ROOT_DIR%\_lib\toolchains\rosbe\cli.cmd" %%*
) > "!_INST_DIR!\bin\rosbe.cmd"
if not exist "%LIBSCRIPT_HOME%\bin" mkdir "%LIBSCRIPT_HOME%\bin"
copy /y "!_INST_DIR!\bin\rosbe.cmd" "%LIBSCRIPT_HOME%\bin\rosbe.cmd" >nul 2>&1
echo installed> "!_STAMP!"
echo [OK] Installed rosbe !_VER! to !_INST_DIR!.
exit /b 0

:: ## action_generic
:: Delegates generic lifecycle actions to versioning.cmd.
:action_generic
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_handle_generic_action "rosbe" "%ACTION%" "%ROSBE_VERSION%" "libscript_native"
exit /b !errorlevel!
