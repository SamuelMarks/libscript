@echo off
:: # regen_all_screenshots.cmd
::
:: ## Overview
:: Regenerates all packaging and browser verification screenshots for Open edX Windows Installer (.msi).
::
:: ## Usage
:: call devtoolsegen_all_screenshots.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: ## find_root
:: Finds the root directory of the libscript repository.
for %%I in ("%SCRIPT_DIR%\..") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

:: ## find_root_loop
:: Iterates upward through the directory tree looking for libscript.cmd.
:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop

:: ## found_root
:: Target label reached once the libscript root directory is located.
:found_root

:: ## show_help
:: Displays command-line usage when help flags are passed.
if /I "%~1"=="--help" goto :help
if /I "%~1"=="-h" goto :help
if /I "%~1"=="/?" goto :help
if /I "%~1"=="-?" goto :help
goto :main

:help
:: ## help
:: Prints the help message and exits.
echo Usage: %~nx0
echo Regenerates WiX installer and browser verification screenshots.
exit /b 0

:: ## main
:: Executes screenshot regeneration via PowerShell script companion.
:main
set "PS_SCRIPT=%SCRIPT_DIR%egen_all_screenshots.ps1"

where powershell.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
    exit /b %ERRORLEVEL%
)

where pwsh.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
    exit /b %ERRORLEVEL%
)

where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    pwsh -NoProfile -File "%PS_SCRIPT%" %*
    exit /b %ERRORLEVEL%
)

echo [ERROR] PowerShell or pwsh is required to regenerate screenshots on Windows. >&2
exit /b 1
