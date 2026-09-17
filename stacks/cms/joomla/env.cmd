@echo off
:: # env.cmd
::
:: ## Overview
:: Defines environment variables and configurations for the Joomla CMS stack.
:: 
:: ## Usage
:: Source or call this script to configure the environment for joomla.

:: Environment variables for Windows
set "THIS_FILE=%~f0"
if not "%JOOMLA_LISTEN%"=="" set "LIBSCRIPT_LISTEN_PORT=%JOOMLA_LISTEN%"
