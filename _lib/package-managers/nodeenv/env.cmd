@echo off
:: # env.cmd
::
:: ## Overview
:: Sets up environment variables for the nodeenv package manager on Windows.
::
:: ## Usage
:: Call or execute in the current command shell:
::   call env.cmd

set "THIS_FILE=%~f0"

if "%NODEENV_VERSION%"=="" set "NODEENV_VERSION=latest"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if exist "%LIBSCRIPT_HOME%/nodeenv/%NODEENV_VERSION%/Scripts" (
    set "PATH=%LIBSCRIPT_HOME%/nodeenv/%NODEENV_VERSION%/Scripts;%PATH%"
) else if exist "%LIBSCRIPT_HOME%/nodeenv/%NODEENV_VERSION%/bin" (
    set "PATH=%LIBSCRIPT_HOME%/nodeenv/%NODEENV_VERSION%/bin;%PATH%"
)
