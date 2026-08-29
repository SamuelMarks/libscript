@echo off
:: # route.cmd
::
:: ## Overview
:: Lifecycle script for route.cmd.
::
:: ## Usage
:: See route.cmd for implementation details.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "DOMAIN=%~1"
set "LOCATION=%~2"
set "DESTINATION=%~3"
if "%DOMAIN%"=="" goto usage
if "%LOCATION%"=="" goto usage
if "%DESTINATION%"=="" goto usage
if "!PREFIX!"=="" (
    set "NGINX_CONF_DIR=!LIBSCRIPT_ROOT_DIR!\installed\nginx\conf"
) else (
    set "NGINX_CONF_DIR=!PREFIX!\conf"
)
if not exist "%NGINX_CONF_DIR%\sites-available" mkdir "%NGINX_CONF_DIR%\sites-available"
if not exist "%NGINX_CONF_DIR%\sites-enabled" mkdir "%NGINX_CONF_DIR%\sites-enabled"
set "CONF_FILE=%NGINX_CONF_DIR%\sites-available\%DOMAIN%.conf"
if not exist "%CONF_FILE%" (
    echo server {> "%CONF_FILE%"
    echo     listen 80;>> "%CONF_FILE%"
    echo     server_name %DOMAIN%;>> "%CONF_FILE%"
    echo }>> "%CONF_FILE%"
)
set "VBS_FILE=%TEMP%\nginx_route_update_%RANDOM%.vbs"
if exist "%VBS_FILE%" del /q "%VBS_FILE%"
echo Set objFS = CreateObject("Scripting.FileSystemObject") > "%VBS_FILE%"
echo Set objFile = objFS.OpenTextFile("%CONF_FILE%", 1) >> "%VBS_FILE%"
echo strContent = objFile.ReadAll >> "%VBS_FILE%"
echo objFile.Close >> "%VBS_FILE%"
echo Set objRegEx = CreateObject("VBScript.RegExp") >> "%VBS_FILE%"
echo objRegEx.Global = True >> "%VBS_FILE%"
echo objRegEx.IgnoreCase = True >> "%VBS_FILE%"
echo objRegEx.MultiLine = True >> "%VBS_FILE%"
echo objRegEx.Pattern = "^[ \t]*location %LOCATION% \{[^}]*\}" >> "%VBS_FILE%"
echo newBlock = "    location %LOCATION% {" ^& vbCrLf ^& "        proxy_pass %DESTINATION%;" ^& vbCrLf ^& "        proxy_set_header Host $host;" ^& vbCrLf ^& "        proxy_set_header X-Real-IP $remote_addr;" ^& vbCrLf ^& "    }" >> "%VBS_FILE%"
echo If objRegEx.Test(strContent) Then >> "%VBS_FILE%"
echo     strContent = objRegEx.Replace(strContent, newBlock) >> "%VBS_FILE%"
echo Else >> "%VBS_FILE%"
echo     objRegEx.Pattern = "^}$" >> "%VBS_FILE%"
echo     strContent = objRegEx.Replace(strContent, newBlock ^& vbCrLf ^& "}") >> "%VBS_FILE%"
echo End If >> "%VBS_FILE%"
echo Set objFile = objFS.OpenTextFile("%CONF_FILE%.tmp", 2, True) >> "%VBS_FILE%"
echo objFile.Write strContent >> "%VBS_FILE%"
echo objFile.Close >> "%VBS_FILE%"

cscript //nologo "%VBS_FILE%"
move /y "%CONF_FILE%.tmp" "%CONF_FILE%" >nul
del "%VBS_FILE%"

copy /y "%CONF_FILE%" "%NGINX_CONF_DIR%\sites-enabled\%DOMAIN%.conf" >nul
echo Route updated: %DOMAIN%%LOCATION% -^> %DESTINATION%
exit /b 0
:: ## usage
:: Executes usage functionality.
:usage
echo Usage: libscript.cmd route nginx ^<version^> ^<domain^> ^<location^> ^<destination^> 1^>^&2
exit /b 1
