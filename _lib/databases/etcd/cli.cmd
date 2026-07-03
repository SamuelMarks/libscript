@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for etcd on Windows.
::
:: ## Usage
:: Run `libscript databases/etcd [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=etcd"
call "%~dp0\..\..\_common\component_core.cmd" %*
