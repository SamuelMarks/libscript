@echo off
:: # setup.cmd
::
:: ## Overview
:: Primary setup script for Bento Builder stack on Windows.
::
:: ## Usage
:: Call this script to set up Bento Builder on Windows.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\..\_lib\_common\setup_base.cmd" %*
