@echo off
:: # setup.cmd
:: Primary setup script for Bento Builder stack on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\..\_lib\_common\setup_base.cmd" %*
