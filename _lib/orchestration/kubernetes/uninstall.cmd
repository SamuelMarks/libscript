@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for Kubernetes on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up Kubernetes.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
