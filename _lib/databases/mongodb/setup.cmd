@echo off
:: # setup.cmd
::
:: ## Overview
:: Primary setup script for MongoDB on Windows.
::
:: ## Usage
:: Routes to generic setup via `setup_base.cmd`.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\setup_base.cmd" %*
