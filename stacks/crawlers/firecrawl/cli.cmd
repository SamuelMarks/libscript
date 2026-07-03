@echo off
:: # cli.cmd
::
:: ## Overview
:: Provides the command-line interface logic for the Firecrawl crawler stack.
:: 
:: ## Usage
:: Execute this script to trigger the CLI behavior for firecrawl.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=firecrawl"
call "%~dp0..\..\..\_lib\_common\component_core.cmd" %*
