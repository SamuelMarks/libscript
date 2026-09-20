@echo off
set "THIS_FILE=%~f0"
:: # capture_openedx_screenshots.cmd
::
:: ## Overview
:: Captures pixel-perfect screenshots of every step and enumeration in the Open edX
:: Windows Installer (.msi) wizard using Vagrant Windows 11 and QEMU screendump.
::
:: ## Usage
:: Call devtools\capture_openedx_screenshots.cmd [--help]

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage and help information for the screenshot capture tool.
:show_help
echo Usage: %~nx0 [--help]
echo.
echo Automates capturing pixel-perfect screenshots of the Open edX MSI installer.
echo.
echo Options:
echo   --help, -h, /?, -?  Show this help message and exit.
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
setlocal EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"
call "%SCRIPT_DIR%capture_openedx_vagrant_screenshots.cmd" %*
exit /b %ERRORLEVEL%
