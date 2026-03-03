@echo off
rem dos_setup_script_deps.bat
rem MS-DOS compatibility script for dependencies

if not exist tools\NUL mkdir tools
set PATH=tools;%PATH%

if exist tools\curl.exe goto have_curl
if exist curl.exe goto have_curl

echo Fetching curl...
cd tools
ftp http://mik.dyndns.pro/dos-stuff/bin/curl.exe
cd ..

:have_curl

if exist tools\jq.exe goto have_jq
if exist jq.exe goto have_jq

echo Fetching jq...
cd tools
curl.exe -L -o jq.exe https://github.com/jqlang/jq/releases/download/jq-1.8.1/jq-windows-i386.exe
cd ..

:have_jq

echo DOS Dependencies Setup Complete.
