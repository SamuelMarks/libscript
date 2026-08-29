@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for cabal on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for cabal.

:: Windows env stub for cabal
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%CABAL_VERSION%"=="" (
    set "CABAL_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\cabal\%CABAL_VERSION%\bin;%PATH%"
