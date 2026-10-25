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

if not "%~1"=="" (
    set "_VER_SUB=%~1"
    if "!_VER_SUB:~0,1!"==":" (
        shift
        call !_VER_SUB! "%~1" "%~2" "%~3" "%~4"
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

if exist "%alias_path%" rmdir "%alias_path%"
mklink /J "%alias_path%" "%exact_path%" >nul
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
    where python >nul 2>&1
    if not errorlevel 1 (
        if /i "!_civ_req!"=="latest" exit /b 0
        python -c "import sys; sys.exit(0 if f'{sys.version_info[0]}.{sys.version_info[1]}' == '!_civ_prefix!' else 1)" >nul 2>&1
        if not errorlevel 1 exit /b 0
    )
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
