@echo off
:: # ch11_jumpbox_to_nodes.cmd
::
:: ## Overview
:: Automates Ch11 of Kubernetes the Hard Way.
::
:: ## Usage
:: Executes the steps for Ch11.

setlocal EnableDelayedExpansion

set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: Traverse up to find libscript.cmd
set "d=%SCRIPT_DIR%"
:find_root
if exist "%d%\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=%d%"
    goto root_found
)
for %%a in ("%d%") do set "parent=%%~dpa"
if "%parent:~-1%"=="\" set "parent=%parent:~0,-1%"
if "%d%"=="%parent%" (
    set "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%"
    goto root_found
)
set "d=%parent%"
goto find_root
:root_found
set "DIR=%SCRIPT_DIR%"

set MACHINES_TXT=%DIR%\\kubernetes-the-hard-way\machines.txt
set NODES=
for /f "tokens=1,3,4" %%a in ('type "%MACHINES_TXT%" ^| findstr "node-"') do (
  set NODES=!NODES! %%b
  set IP_%%b=%%a
  set SUBNET_%%b=%%c
)
if "!NODES!"=="" (
  set NODES=node-0 node-1
  set IP_node-0=192.168.56.21
  set SUBNET_node-0=10.200.0.0/24
  set IP_node-1=192.168.56.22
  set SUBNET_node-1=10.200.1.0/24
)

for %%H in (%NODES%) do (
  set "NODE_IP=!IP_%%H!"
  set "NODE_SUBNET=!SUBNET_%%H!"
  ssh root@server "ip route add !NODE_SUBNET! via !NODE_IP! || true"
  
  for %%O in (%NODES%) do (
    if not "%%H"=="%%O" (
      set "OTHER_IP=!IP_%%O!"
      set "OTHER_SUBNET=!SUBNET_%%O!"
      ssh root@%%H "ip route add !OTHER_SUBNET! via !OTHER_IP! || true"
    )
  )
)
