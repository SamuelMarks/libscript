@echo off
:: # env.cmd
::
:: ## Overview
:: Defines environment variables and configurations for the PrestaShop e-commerce platform stack.
:: 
:: ## Usage
:: Source or call this script to configure the environment for prestashop.

:: Environment variables for Windows
set "THIS_FILE=%~f0"
if not "%PRESTASHOP_LISTEN%"=="" set "LIBSCRIPT_LISTEN_PORT=%PRESTASHOP_LISTEN%"
