@echo off
:: # cli.cmd
::
:: ## Overview
:: Provides the command-line interface logic for the JupyterHub data science platform stack.
:: 
:: ## Usage
:: Execute this script to trigger the CLI behavior for jupyterhub.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=jupyterhub"
call "%~dp0..\..\..\_lib\_common\component_core.cmd" %*
