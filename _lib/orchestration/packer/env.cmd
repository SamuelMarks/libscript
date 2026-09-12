@echo off
:: # env.cmd
::
:: ## Overview
:: Environment export script for HashiCorp Packer on Windows.
::
:: ## Usage
:: Call this script to set Packer environment variables.

set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%PACKER_VERSION%"=="" (
    set "PACKER_VERSION=latest"
)
if exist "%LIBSCRIPT_HOME%\packer\%PACKER_VERSION%\bin" (
    set "PATH=%LIBSCRIPT_HOME%\packer\%PACKER_VERSION%\bin;%PATH%"
)
