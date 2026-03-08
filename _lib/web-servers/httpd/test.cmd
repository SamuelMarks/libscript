@echo off
set "PATH=%PATH%;C:\tools\apache24\bin;C:\Apache24\bin;C:\Program Files\Apache24\bin"
httpd -v
if %errorlevel% neq 0 exit /b %errorlevel%
