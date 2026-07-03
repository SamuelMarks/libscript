@echo off
:: # deprovision.cmd
::
:: ## Overview
:: Tears down and deprovisions cloud infrastructure resources.
:: 
:: ## Usage
:: Execute this script to destroy cloud resources.

setlocal EnableDelayedExpansion
shift
call "%~dp0scripts\teardown_cloud.cmd" %*
goto :eof


