@echo off
:: # prelude.cmd
::
:: ## Overview
:: Common preamble and initialization logic shared across scripts.
:: 
:: ## Usage
:: This script is intended to be sourced by other scripts, not executed directly.

setlocal EnableDelayedExpansion

:: Initialize STACK variable
set "THIS_FILE=%~f0"
IF NOT DEFINED STACK (
    SET "STACK=;%~nx0;"
) ELSE (
    SET "STACK=%STACK%%~nx0;"
)

SET "searchVal=;%~nx0;"
IF NOT "!STACK:%searchVal%=!"=="!STACK!" (
  echo [STOP]     processing "%~nx0"
  exit /b 0
) else (
  echo [CONTINUE] processing "%~nx0"
)

IF NOT DEFINED LIBSCRIPT_ROOT_DIR (
    SET "LIBSCRIPT_ROOT_DIR=%~dp0"
)

if "%~1"=="--help" goto show_help
if "%~1"=="-h" goto show_help
if "%~1"=="/?" goto show_help
if "%~1"=="-?" goto show_help

IF NOT DEFINED LIBSCRIPT_BUILD_DIR (
    SET "LIBSCRIPT_BUILD_DIR=%TEMP%\libscript_build"
)
IF NOT DEFINED LIBSCRIPT_DATA_DIR (
    SET "LIBSCRIPT_DATA_DIR=%TEMP%\libscript_data"
)

SET "PATH=%USERPROFILE%\.cargo\bin;%LIBSCRIPT_DATA_DIR%\bin;%PATH%"

IF NOT EXIST "%LIBSCRIPT_BUILD_DIR%" mkdir "%LIBSCRIPT_BUILD_DIR%"
IF NOT EXIST "%LIBSCRIPT_DATA_DIR%" mkdir "%LIBSCRIPT_DATA_DIR%"

exit /b 0

:: ## show_help
:: Executes show_help functionality.
:show_help
echo Usage: %0
exit /b 0
