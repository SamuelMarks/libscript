@echo off
:: # vagrantfile.cmd
::
:: ## Overview
:: Network control library module for vagrantfile on Windows.
:: 
:: ## Usage
:: call vagrantfile.cmd :netctl_emit_vagrantfile [state_file]

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
    call :%*
    exit /b %errorlevel%
)
exit /b 0

:: ## netctl_emit_vagrantfile
:: Emits Vagrantfile port forward configurations from JSON state file.
:netctl_emit_vagrantfile
set "state_file=%~1"
if "%state_file%"=="" set "state_file=%NETCTL_STATE_FILE%"

if not exist "%state_file%" (
    echo Error: State file '%state_file%' not found. 1>&2
    exit /b 1
)

where jq >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%P in ('jq -r ".listen[]" "%state_file%" 2^>nul') do (
        set "listen_str=%%P"
        if not "!listen_str:~0,5!"=="unix:" (
            for /f "tokens=2 delims=:" %%Q in ("!listen_str!") do set "port=%%Q"
            if "!port!"=="" set "port=!listen_str!"
            echo   config.vm.network "forwarded_port", guest: !port!, host: !port!, auto_correct: true
        )
    )
    exit /b 0
)

powershell -NoProfile -Command "$json = Get-Content '%state_file%' | ConvertFrom-Json; foreach ($l in $json.listen) { if (!$l.StartsWith('unix:')) { $port = $l.Split(':')[-1]; Write-Output ('  config.vm.network \"forwarded_port\", guest: ' + $port + ', host: ' + $port + ', auto_correct: true') } }"
exit /b %errorlevel%
