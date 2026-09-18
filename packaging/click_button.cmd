@echo off
:: # click_button.cmd
::
:: ## Overview
:: Automates finding and clicking UI controls (buttons, checkboxes, radio buttons) by text in Windows GUI sessions.
::
:: ## Usage
:: call "%~dp0click_button.cmd" [button_text]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: ## setup_target
:: Configures target button text and log location.
:setup_target
set "PS_SCRIPT=%SCRIPT_DIR%\click_button.ps1"
if not exist "%PS_SCRIPT%" set "PS_SCRIPT=C:\libscript\click_button.ps1"

set "LOG_FILE=%TEMP%\libscript_click.log"
if not exist "%TEMP%" set "LOG_FILE=%SCRIPT_DIR%\click.log"

if not "%~1"=="" (
  echo %~1> "%TEMP%\target_btn.txt"
)

:: ## run_click
:: Executes the click automation via PowerShell Win32 API bridge.
:run_click
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" > "%LOG_FILE%" 2>&1
exit /b %ERRORLEVEL%
