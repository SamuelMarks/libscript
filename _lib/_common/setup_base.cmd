@echo off
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

setlocal EnableDelayedExpansion

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%~dp0"
    :find_root
    if exist "!d!\ROOT" (set "LIBSCRIPT_ROOT_DIR=!d!") else (
        for %%P in ("!d!") do set "parent=%%~dpP"
        set "d=!parent:~0,-1!"
        if "!d!"=="" (
            echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
            exit /b 1
        )
        goto :find_root
    )
)

:: Source logging
set "LOG_CMD=%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd"

:: Privilege Check
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\priv.cmd" :check_admin
if errorlevel 1 (
    call "%LOG_CMD%" :log_info "Elevating to administrator..."
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\priv.cmd" :priv "%~f0"
    exit /b %errorlevel%
)

:: Delegate to PowerShell if setup_win.ps1 exists
if exist "%~dp0setup_win.ps1" (
    set "COMMON_DIR=%LIBSCRIPT_ROOT_DIR%\_lib\_common"
    powershell -ExecutionPolicy Bypass -Command "& { . '!COMMON_DIR!\log.ps1'; . '!COMMON_DIR!\pkg_mgr.ps1'; . '!COMMON_DIR!\validate_schema.ps1'; . '!COMMON_DIR!\service.ps1'; if (Test-Path '%~dp0vars.schema.json') { validate_schema '%~dp0vars.schema.json' }; & '%~dp0setup_win.ps1' }"
    exit /b !errorlevel!
) else if exist "%~dp0setup.ps1" (
    set "COMMON_DIR=%LIBSCRIPT_ROOT_DIR%\_lib\_common"
    powershell -ExecutionPolicy Bypass -Command "& { . '!COMMON_DIR!\log.ps1'; . '!COMMON_DIR!\pkg_mgr.ps1'; . '!COMMON_DIR!\validate_schema.ps1'; if (Test-Path '%~dp0vars.schema.json') { validate_schema '%~dp0vars.schema.json' }; & '%~dp0setup.ps1' }"
    exit /b !errorlevel!
) else (
    call "%LOG_CMD%" :log_error "No PowerShell setup script (setup_win.ps1 or setup.ps1) found in %~dp0"
    exit /b 1
)

:: Helper functions (reachable via call :label)
goto :eof

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
    call "%LOG_CMD%" :log_info "%bin_name% installed to %SystemRoot%"
    exit /b 0
)

:: Fallback to user bin
copy /y "%src_path%" "%dest_dir%\%bin_name%" >nul 2>&1
if not errorlevel 1 (
    call "%LOG_CMD%" :log_info "%bin_name% installed to %dest_dir%"
    
    :: Check if dest_dir is in PATH
    echo %PATH% | findstr /i /c:"%dest_dir%" >nul
    if errorlevel 1 (
        call "%LOG_CMD%" :log_warn "%dest_dir% is not in your PATH."
    )
    exit /b 0
)

call "%LOG_CMD%" :log_error "Failed to install %bin_name% to %dest_dir%"
exit /b 1
