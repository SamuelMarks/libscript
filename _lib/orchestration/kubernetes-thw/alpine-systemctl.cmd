@echo off
:: ## Overview
:: Alpine stub for systemctl functionality.
::
:: ## Usage
:: Used internally to mock systemd commands on Alpine Linux.
set "THIS_FILE=%~f0"

echo alpine-systemctl is not supported on Windows.
exit /b 1
