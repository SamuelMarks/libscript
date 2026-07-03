@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for RabbitMQ on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up RabbitMQ.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
