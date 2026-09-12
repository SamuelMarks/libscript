@echo off
:: # template_nsis.cmd
::
:: ## Overview
:: Template file for NSIS installer generation on Windows.
:: 
:: ## Usage
:: This file is processed during the build phase and not executed directly.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%APP_NAME%"=="" set "APP_NAME=MyApp"
if "%APP_VERSION%"=="" set "APP_VERSION=1.0.0"
if "%APP_PUBLISHER%"=="" set "APP_PUBLISHER=MyCompany"
if "%OUT_FILE%"=="" set "OUT_FILE=installer"
if "%nsis_admin%"=="" set "nsis_admin=admin"

echo !define APP_NAME "%APP_NAME%"
echo !define APP_VERSION "%APP_VERSION%"
echo !define APP_PUBLISHER "%APP_PUBLISHER%"
echo Name "%APP_NAME% %APP_VERSION%"
echo OutFile "%OUT_FILE%.exe"
echo InstallDir "$PROGRAMFILES\%APP_NAME%"
echo RequestExecutionLevel %nsis_admin%

echo VIProductVersion "%APP_VERSION%"
echo VIAddVersionKey "ProductName" "%APP_NAME%"
echo VIAddVersionKey "CompanyName" "%APP_PUBLISHER%"
if not "%WELCOME_TEXT%"=="" echo VIAddVersionKey "FileDescription" "%WELCOME_TEXT%"
echo VIAddVersionKey "FileVersion" "%APP_VERSION%"

if not "%ICON_PATH%"=="" echo Icon "%ICON_PATH%"

echo Section "MainSection" SEC01
echo   SetOutPath "$INSTDIR"
if defined LIBSCRIPT_ROOT_DIR (
    echo   File /r "%LIBSCRIPT_ROOT_DIR%\*.*"
) else (
    echo   File /r "*.*"
)
echo SectionEnd
exit /b 0
