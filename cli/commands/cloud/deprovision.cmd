@echo off
:: # deprovision.cmd
::
:: ## Overview
:: Tears down and deprovisions cloud infrastructure resources.
:: 
:: ## Usage
:: Execute this script to destroy cloud resources.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
shift
call "%~dp0scripts\teardown_cloud.cmd" %*
goto :eof


