@echo off
:: # env.cmd
::
:: ## Overview
:: Defines environment variables and configurations for the Celery task queue stack.
:: 
:: ## Usage
:: Source or call this script to configure the environment for celery.

:: Environment variables for Windows
set "THIS_FILE=%~f0"
if "%PYTHON_VERSION%"=="" set "PYTHON_VERSION=3.11"
if "%PYTHON_VENV%"=="" set "PYTHON_VENV=C:\venvs\celery-%PYTHON_VERSION%"
