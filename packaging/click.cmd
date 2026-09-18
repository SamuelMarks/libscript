@echo off
:: # click.cmd
::
:: ## Overview
:: Automated GUI control clicker for installer automation on Windows.
:: Locates target controls and sends BM_CLICK messages via click_button.ps1.
::
:: ## Usage
:: click.cmd [button_text]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "PS_SCRIPT=%SCRIPT_DIR%\click_button.ps1"
if not exist "%PS_SCRIPT%" set "PS_SCRIPT=C:\libscript\click_button.ps1"

set "LOG_FILE=%TEMP%\libscript_click.log"
if not exist "%TEMP%" set "LOG_FILE=%SCRIPT_DIR%\click.log"

if not "%~1"=="" (
  echo %~1> "%TEMP%\target_btn.txt"
)

powershell.exe -ExecutionPolicy Bypass -File "%PS_SCRIPT%" > "%LOG_FILE%" 2>&1
exit /b %ERRORLEVEL%
