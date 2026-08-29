@echo off
:: # cli.cmd
::
:: ## Overview
:: Provides the command-line interface logic for the Actix+Diesel authentication scaffold stack.
:: 
:: ## Usage
:: Execute this script to trigger the CLI behavior for serve-actix-diesel-auth-scaffold.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=serve-actix-diesel-auth-scaffold"
call "%~dp0..\..\..\_lib\_common\component_core.cmd" %*
