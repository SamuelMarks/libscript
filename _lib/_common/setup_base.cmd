@echo off
:: # setup_base.cmd
setlocal EnableDelayedExpansion
:: # LibScript Common Setup Entrypoint (Windows Batch)
::
:: ## Overview
:: Standardized entrypoint for component installation on Windows.
:: Resolves root, checks privileges, and delegates to setup scripts.
::
:: ## Usage
:: Your component's `setup.cmd` should call this.
::
:: ```batch
:: @echo off
:: call "%~dp0\..\..\..\_lib\_common\setup_base.cmd"
:: ```

set "CALLER_FILE=!THIS_FILE!"
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2^>^&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" ^>^&2
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
    set "_SB_SUB=%~1"
    if "!_SB_SUB:~0,1!"==":" (
        shift
        call !_SB_SUB! "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
        exit /b !errorlevel!
    )
)

:: Source logging
set "LOG_CMD=!LIBSCRIPT_ROOT_DIR!\_lib\_common\log.cmd"

:: Resolve target component directory
set "TARGET_DIR="
if not "%CALLER_FILE%"=="" (
    for %%I in ("%CALLER_FILE%") do set "TARGET_DIR=%%~dpI"
)
if "%TARGET_DIR:~-1%"=="\" set "TARGET_DIR=%TARGET_DIR:~0,-1%"
if "%TARGET_DIR%"=="" set "TARGET_DIR=%CD%"
if /i "%TARGET_DIR%"=="!LIBSCRIPT_ROOT_DIR!\_lib\_common" set "TARGET_DIR=%CD%"

:: Privilege Check
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\priv.cmd" :check_admin
if errorlevel 1 (
    call "!LOG_CMD!" :log_info "Elevating to administrator..."
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\priv.cmd" :priv "%~f0"
    exit /b %errorlevel%
)

:: Delegate to specific setup script
set "SETUP_ERR=1"
if exist "%TARGET_DIR%\setup_windows.cmd" (
    call "%TARGET_DIR%\setup_windows.cmd" %*
    set "SETUP_ERR=!errorlevel!"
) else if exist "%TARGET_DIR%\setup_generic.cmd" (
    call "%TARGET_DIR%\setup_generic.cmd" %*
    set "SETUP_ERR=!errorlevel!"
) else if exist "%TARGET_DIR%\setup.ps1" (
    set "COMMON_DIR=!LIBSCRIPT_ROOT_DIR!\_lib\_common"
    powershell -ExecutionPolicy Bypass -Command "& { . '!COMMON_DIR!\log.ps1'; . '!COMMON_DIR!\pkg_mgr.ps1'; & '%TARGET_DIR%\setup.ps1' }"
    set "SETUP_ERR=!errorlevel!"
) else (
    call "!LOG_CMD!" :log_error "No setup script found in %TARGET_DIR%"
    exit /b 1
)

if !SETUP_ERR! equ 0 exit /b 0

:: Resolve package name for fallback
if "%PACKAGE_NAME%"=="" (
    for %%I in ("%TARGET_DIR%") do set "PACKAGE_NAME=%%~nxI"
)

:: Fallback to Windows Package Managers via pkg_mgr.cmd
call "!LOG_CMD!" :log_info "Native setup failed. Attempting package manager fallback for !PACKAGE_NAME!..."
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends "!PACKAGE_NAME!"
if not errorlevel 1 exit /b 0

exit /b !SETUP_ERR!

:: Helper functions (reachable via call :label)
goto :eof

:: ## libscript_install_binary
:: Performs the libscript_install_binary operation and updates component state.
:libscript_install_binary
set "src_path=%~1"
set "bin_name=%~2"

if "%PREFIX%"=="" (
    set "dest_dir=%USERPROFILE%\.local\bin"
) else (
    set "dest_dir=%PREFIX%"
)

if not exist "%dest_dir%" mkdir "%dest_dir%"

:: Try SystemRoot if requested and admin
copy /y "%src_path%" "%SystemRoot%\" >nul 2>&1
if not errorlevel 1 (
    call "!LOG_CMD!" :log_info "%bin_name% installed to %SystemRoot%"
    exit /b 0
)

:: Fallback to user bin
copy /y "%src_path%" "%dest_dir%\%bin_name%" >nul 2>&1
if not errorlevel 1 (
    call "!LOG_CMD!" :log_info "%bin_name% installed to %dest_dir%"
    
    REM Check if dest_dir is in PATH
    echo %PATH% | findstr /i /c:"%dest_dir%" >nul
    if errorlevel 1 (
        call "!LOG_CMD!" :log_warn "%dest_dir% is not in your PATH."
    )
    exit /b 0
)

call "!LOG_CMD!" :log_error "Failed to install %bin_name% to %dest_dir%"
exit /b 1

:: ## libscript_handle_generic_action
:: Delegates generic component lifecycle actions to versioning.cmd.
:libscript_handle_generic_action
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_handle_generic_action "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
exit /b !errorlevel!
