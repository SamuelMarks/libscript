@echo off
:: # assemble.cmd
::
:: ## Overview
:: Orchestrates FreeBSD distribution synthesis from a JSON profile specification
:: on Windows host environments.
::
:: ## Usage
:: assemble.cmd [profile_json_path] [target_sysroot]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

SET "searchVal=;%THIS_FILE%;"
IF NOT DEFINED STACK (
    SET "STACK=;%THIS_FILE%;"
    echo [CONTINUE] processing "%THIS_FILE%"
) ELSE (
    IF NOT "!STACK:%searchVal%=!"=="!STACK!" (
        echo [STOP]     processing "%THIS_FILE%"
        SET ERRORLEVEL=0
        goto :eof
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

if "%~1"=="--help" (
    echo Usage: %~nx0 [profile_json_path] [target_sysroot]
    echo Orchestrates FreeBSD distribution assembly.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [profile_json_path] [target_sysroot]
    echo Orchestrates FreeBSD distribution assembly.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "PROFILE=%~1"
if "%PROFILE%"=="" set "PROFILE=%REPO_ROOT%\profiles\freebsd\minimal-server.json"
set "SYSROOT=%~2"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\freebsd-sysroot"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\assembled.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"

if exist "%STAMP_FILE%" (
    echo [SKIP]     FreeBSD distribution already assembled in %SYSROOT%
    exit /b 0
)

echo [ASSEMBLE] Synthesizing FreeBSD distribution using profile: %PROFILE%...

call "%SCRIPT_DIR%base.cmd" "%SYSROOT%" "14.1-RELEASE" "amd64"
call "%SCRIPT_DIR%config.cmd" "%SYSROOT%" "freebsd-distro" "ufs2"
call "%SCRIPT_DIR%pkg.cmd" "%SYSROOT%" "quarterly"
call "%SCRIPT_DIR%users.cmd" "%SYSROOT%" "vagrant"
call "%SCRIPT_DIR%init.cmd" "%SYSROOT%" "bsd-rc" "sshd,cron,devd"
call "%SCRIPT_DIR%display.cmd" "%SYSROOT%" "none" "none"
call "%SCRIPT_DIR%desktop.cmd" "%SYSROOT%" "none" "vagrant"
call "%SCRIPT_DIR%dm.cmd" "%SYSROOT%" "none" ""
call "%SCRIPT_DIR%audio.cmd" "%SYSROOT%" "none"

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       FreeBSD distribution assembly complete.
exit /b 0
