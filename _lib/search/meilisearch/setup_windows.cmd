@echo off
:: # setup_windows.cmd
::
:: ## Overview
:: Windows setup entry point for Meilisearch.

::
:: ## Usage
:: Call this script to trigger setup for meilisearch on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0setup_generic.cmd" %*
