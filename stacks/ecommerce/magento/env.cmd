@echo off
:: # env.cmd
::
:: ## Overview
:: Defines environment variables and configurations for the Magento e-commerce platform stack.
:: 
:: ## Usage
:: Source or call this script to configure the environment for magento.

:: Environment variables for Windows
set "THIS_FILE=%~f0"
if not "%MAGENTO_LISTEN%"=="" set "LIBSCRIPT_LISTEN_PORT=%MAGENTO_LISTEN%"
