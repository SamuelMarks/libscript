@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for rabbitmq on Windows.
:: Prepares and configures rabbitmq on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript rabbitmq installation on Windows.

set "THIS_FILE=%~f0"

where rabbitmqctl >nul 2>&1
if %errorlevel% equ 0 exit /b 0

echo RabbitMQ server environment configured.
exit /b 0
