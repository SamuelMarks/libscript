@echo off
mosquitto -h
if %errorlevel% neq 0 exit /b %errorlevel%