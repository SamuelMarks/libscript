@echo off
:: # generate_html_docs.cmd
::
:: ## Overview
:: Generates HTML documentation from markdown sources.
:: 
:: ## Usage
:: Execute this script to build the static HTML documentation site.

:: Windows batch equivalent

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:show_help
:: ## show_help
:: Executes show_help functionality.
echo Usage: %~nx0
echo Generates HTML documentation from markdown sources.
echo.
echo Options:
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:main
:: ## main
:: Executes main functionality.
exit /b 0
