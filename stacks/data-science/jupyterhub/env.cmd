@echo off
:: # env.cmd
::
:: ## Overview
:: Defines environment variables and configurations for the JupyterHub data science platform stack.
:: 
:: ## Usage
:: Source or call this script to configure the environment for jupyterhub.

:: Environment variables for Windows
set "THIS_FILE=%~f0"
if "%PYTHON_VERSION%"=="" set "PYTHON_VERSION=3.10"
if "%JUPYTERHUB_NOTEBOOK_DIR%"=="" set "JUPYTERHUB_NOTEBOOK_DIR=C:\notebooks"
if "%JUPYTERHUB_IP%"=="" set "JUPYTERHUB_IP=127.0.0.1"
if "%JUPYTERHUB_PORT%"=="" set "JUPYTERHUB_PORT=8888"
