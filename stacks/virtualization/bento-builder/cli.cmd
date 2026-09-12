@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Bento Builder stack on Windows.
::
:: ## Usage
:: Execute this script to perform CLI actions for Bento Builder.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=bento-builder"
call "%~dp0\..\..\..\_lib\_common\component_core.cmd" %*
