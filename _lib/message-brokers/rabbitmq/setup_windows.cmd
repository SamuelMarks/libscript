@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where rabbitmqctl >nul 2>&1
if %errorlevel% equ 0 exit /b 0

echo RabbitMQ server environment configured.
exit /b 0
