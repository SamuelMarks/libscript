@echo off
:: # setup.cmd
:: Primary setup script for VirtualBox on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\setup_base.cmd" %*
