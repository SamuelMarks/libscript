@echo off
:: # versioning.cmd
::
:: ## Overview
:: Provides common utilities for managing component versions on Windows.
:: It includes subroutines to resolve component version directories,
:: create NTFS directory junctions (`mklink /J`) for version aliases,
:: and inspect existing installations (`:libscript_check_installed_version`).
:: 
:: ## Usage
:: Call subroutines like `:libscript_symlink_alias` or `:libscript_check_installed_version` from other batch scripts.

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

if not "%~1"=="" (
    set "_VER_SUB=%~1"
    if "!_VER_SUB:~0,1!"==":" (
        shift
        call !_VER_SUB! "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
        exit /b !errorlevel!
    )
)
goto :eof

:: ## libscript_get_version_dir
:: Performs the libscript_get_version_dir operation and updates component state.
:libscript_get_version_dir
set "component=%~1"
set "version=%~2"
if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_BASE_DIR=%USERPROFILE%\.libscript"
) else (
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_HOME%"
)
set "LIBSCRIPT_VERSION_DIR=%LIBSCRIPT_BASE_DIR%\%component%\%version%"
goto :eof

:: ## libscript_symlink_alias
:: Performs the libscript_symlink_alias operation and updates component state.
:libscript_symlink_alias
set "component=%~1"
set "alias_name=%~2"
set "exact_version=%~3"

if "%alias_name%"=="%exact_version%" goto :eof

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_BASE_DIR=%USERPROFILE%\.libscript"
) else (
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_HOME%"
)
set "base_dir=%LIBSCRIPT_BASE_DIR%\%component%"

if not exist "%base_dir%" mkdir "%base_dir%"

set "alias_path=%base_dir%\%alias_name%"
set "exact_path=%base_dir%\%exact_version%"

if exist "%alias_path%" (
    dir /al "%alias_path%" >nul 2>&1
    if not errorlevel 1 (
        rmdir "%alias_path%" >nul 2>&1
    ) else (
        dir /b "%alias_path%" 2>nul | findstr "." >nul 2>&1
        if errorlevel 1 rmdir "%alias_path%" >nul 2>&1
    )
)
if not exist "%alias_path%" mklink /J "%alias_path%" "%exact_path%" >nul
goto :eof

:: ## libscript_check_installed_version
:: Checks whether a component satisfying the requested version is already installed in LIBSCRIPT_HOME or system PATH on Windows.
:libscript_check_installed_version
set "_civ_comp=%~1"
set "_civ_req=%~2"
if "!_civ_req!"=="" set "_civ_req=latest"
if "%LIBSCRIPT_HOME%"=="" (
    set "_civ_home=%USERPROFILE%\.libscript"
) else (
    set "_civ_home=%LIBSCRIPT_HOME%"
)
set "_civ_prefix=!_civ_req:.x=!"
set "_civ_prefix=!_civ_prefix:.*=!"
if /i "!_civ_comp!"=="nodejs" (
    if exist "!_civ_home!\nodejs\!_civ_req!\node.exe" exit /b 0
    if exist "!_civ_home!\nodejs\!_civ_req!\bin\node.exe" exit /b 0
    if exist "!_civ_home!\nodejs" (
        for /d %%D in ("!_civ_home!\nodejs\*") do (
            if exist "%%~fD\node.exe" (
                for /f "delims=" %%V in ('"%%~fD\node.exe" -v 2^>nul') do (
                    set "_nv=%%V"
                    set "_nv=!_nv:v=!"
                    if /i "!_civ_req!"=="latest" exit /b 0
                    echo !_nv! | findstr /b /c:"!_civ_prefix!." >nul 2>&1
                    if not errorlevel 1 exit /b 0
                )
            )
        )
    )
    where node >nul 2>&1
    if not errorlevel 1 (
        for /f "delims=" %%V in ('node -v 2^>nul') do (
            set "_nv=%%V"
            set "_nv=!_nv:v=!"
            if /i "!_civ_req!"=="latest" exit /b 0
            echo !_nv! | findstr /b /c:"!_civ_prefix!." >nul 2>&1
            if not errorlevel 1 exit /b 0
        )
    )
    exit /b 1
)
if /i "!_civ_comp!"=="python" (
    if exist "!_civ_home!\python\!_civ_req!\python.exe" exit /b 0
    if exist "!_civ_home!\python\!_civ_req!\bin\python.exe" exit /b 0
    for /f "delims=" %%P in ('where python 2^>nul') do (
        echo "%%~fP" | findstr /i "WindowsApps" >nul 2>&1
        if errorlevel 1 (
            if /i "!_civ_req!"=="latest" exit /b 0
            for /f "tokens=2" %%V in ('"%%~fP" --version 2^>^&1') do (
                echo %%V | findstr /b /c:"!_civ_prefix!." >nul 2>&1
                if not errorlevel 1 exit /b 0
                if "%%V"=="!_civ_prefix!" exit /b 0
            )
        )
    )
    exit /b 1
)
if /i "!_civ_comp!"=="valkey" (
    where valkey-server >nul 2>&1
    if not errorlevel 1 exit /b 0
    where redis-server >nul 2>&1
    if not errorlevel 1 exit /b 0
    if exist "!_civ_home!\valkey\!_civ_req!\bin" exit /b 0
    exit /b 1
)
if /i "!_civ_comp!"=="redis" (
    where redis-server >nul 2>&1
    if not errorlevel 1 exit /b 0
    where valkey-server >nul 2>&1
    if not errorlevel 1 exit /b 0
    if exist "!_civ_home!\redis\!_civ_req!\bin" exit /b 0
    exit /b 1
)
if /i "!_civ_comp!"=="postgres" (
    where psql >nul 2>&1
    if not errorlevel 1 exit /b 0
    exit /b 1
)
if exist "!_civ_home!\!_civ_comp!\!_civ_req!\bin" exit /b 0
where !_civ_comp! >nul 2>&1
if not errorlevel 1 exit /b 0
exit /b 1

:: ## libscript_handle_generic_action
:: Centralizes common version manager lifecycle actions (ls, ls-remote, use, download, service, install-service, uninstall-service, uninstall) for setup_generic.cmd scripts.
:libscript_handle_generic_action
set "_hga_comp=%~1"
set "_hga_act=%~2"
set "_hga_ver=%~3"
set "_hga_method=%~4"
set "_hga_dl=%~5"
set "_hga_rel=%~6"
set "_hga_repo=%~7"
set "_hga_exec=%~8"
set "_hga_wd=%~9"

if "!_hga_ver!"=="" set "_hga_ver=latest"
if "!_hga_method!"=="" set "_hga_method=libscript_native"
if "%LIBSCRIPT_HOME%"=="" (
    set "_hga_home=%USERPROFILE%\.libscript"
) else (
    set "_hga_home=%LIBSCRIPT_HOME%"
)
if "%DOWNLOAD_DIR%"=="" (
    set "_hga_dldir=%TEMP%\libscript_downloads"
) else (
    set "_hga_dldir=%DOWNLOAD_DIR%"
)
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "_hga_svc=libscript_!_hga_comp!"
    ) else (
        set "_hga_svc=libscript_%PACKAGE_NAME%"
    )
) else (
    set "_hga_svc=%LIBSCRIPT_SERVICE_NAME%"
)
if "!_hga_wd!"=="" set "_hga_wd=!_hga_home!\!_hga_comp!\!_hga_ver!"
if "!_hga_exec!"=="" set "_hga_exec=\"!_hga_wd!\bin\!_hga_comp!.exe\""

if /i "!_hga_act!"=="ls" (
    if /i "!_hga_method!"=="system" (
        echo System package manager does not support ls directly here.
        exit /b 0
    )
    if exist "!_hga_home!\!_hga_comp!" dir /b "!_hga_home!\!_hga_comp!"
    exit /b 0
)
if /i "!_hga_act!"=="ls-remote" (
    if /i "!_hga_method!"=="system" (
        echo System package manager does not support ls-remote directly here.
        exit /b 0
    )
    if not "!_hga_rel!"=="" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "!_hga_rel!"
        exit /b 0
    )
    if not "!_hga_repo!"=="" (
        git ls-remote --tags "!_hga_repo!" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
        exit /b 0
    )
    echo No versions found
    exit /b 0
)
if /i "!_hga_act!"=="use" (
    if /i "!_hga_method!"=="system" (
        echo Cannot 'use' specific version with system package manager.
        exit /b 0
    )
    set "_hga_exact=!EXACT_VERSION!"
    if "!_hga_exact!"=="" set "_hga_exact=!_hga_ver!"
    call :libscript_symlink_alias "!_hga_comp!" "!_hga_ver!" "!_hga_exact!"
    call :libscript_symlink_alias "!_hga_comp!" "default" "!_hga_exact!"
    exit /b 0
)
if /i "!_hga_act!"=="download" (
    if /i "!_hga_method!"=="libscript_native" (
        echo Downloading !_hga_comp! !_hga_ver! to !_hga_dldir!\!_hga_comp!...
        if not exist "!_hga_dldir!\!_hga_comp!" mkdir "!_hga_dldir!\!_hga_comp!"
        if not "!_hga_dl!"=="" (
            set "STACK="
            call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "!_hga_dl!" "!_hga_dldir!\!_hga_comp!\!_hga_comp!-!_hga_ver!.zip"
        ) else (
            echo Download URL is not defined for !_hga_comp!. Skipping.
        )
    )
    exit /b 0
)
for %%S in (start stop restart status health logs up down) do (
    if /i "!_hga_act!"=="%%S" (
        if exist "!SCRIPT_DIR!\service.cmd" (
            set "STACK="
            call "!SCRIPT_DIR!\service.cmd" "!_hga_act!"
            exit /b !errorlevel!
        )
        if /i "!_hga_method!"=="libscript_native" (
            set "STACK="
            call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" "!_hga_act!" "!_hga_svc!"
        ) else if /i "!_hga_method!"=="system" (
            set "STACK="
            call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" "!_hga_act!" "!_hga_svc!"
        ) else (
            echo !_hga_act! not natively implemented for !_hga_method!.
        )
        exit /b 0
    )
)
if /i "!_hga_act!"=="install-service" (
    if /i "!_hga_method!"=="libscript_native" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" install "!_hga_svc!" "!_hga_exec!" "!_hga_wd!" "!_hga_comp! service"
    ) else if /i "!_hga_method!"=="system" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" install "!_hga_svc!" "!_hga_exec!" "!_hga_wd!" "!_hga_comp! service"
    ) else (
        echo install-service not implemented for !_hga_method!.
    )
    exit /b 0
)
if /i "!_hga_act!"=="uninstall-service" (
    if /i "!_hga_method!"=="libscript_native" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" uninstall "!_hga_svc!"
    ) else if /i "!_hga_method!"=="system" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" uninstall "!_hga_svc!"
    ) else (
        echo uninstall-service not implemented for !_hga_method!.
    )
    exit /b 0
)
if /i "!_hga_act!"=="uninstall" (
    if /i "!_hga_method!"=="libscript_native" (
        echo Uninstalling !_hga_comp! !_hga_ver!...
        if exist "!_hga_home!\!_hga_comp!\!_hga_ver!" (
            rmdir /s /q "!_hga_home!\!_hga_comp!\!_hga_ver!" 2>nul
        )
    ) else (
        echo Uninstall not implemented or supported for !_hga_method!.
    )
    exit /b 0
)
exit /b 1
