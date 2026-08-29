@echo off
:: # provision.cmd
::
:: ## Overview
:: Provisions necessary cloud infrastructure resources.
:: 
:: ## Usage
:: Execute this script to create cloud resources.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
shift
call "%~dp0scripts\deploy_cloud.cmd" %*
goto :eof

