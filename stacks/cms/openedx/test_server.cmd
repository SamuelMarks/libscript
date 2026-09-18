@echo off
:: # test_server.cmd
::
:: ## Overview
:: Mock HTTP/WSGI test server for Open edX registration and authentication testing on Windows.
:: Dispatches to PowerShell System.Net.HttpListener implementation or Python mock listener.
::
:: ## Usage
:: call "%~dp0test_server.cmd" [PORT]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0test_server.ps1" %*
exit /b %ERRORLEVEL%
