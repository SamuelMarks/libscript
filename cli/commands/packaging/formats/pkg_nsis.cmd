@echo off
:: # pkg_nsis.cmd
::
:: ## Overview
:: Implements packaging logic for the 'nsis' format on Windows.
:: 
:: ## Usage
:: Called by the packaging system to produce NSIS installer scripts.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%\..\..\..\.."
)

call "%SCRIPT_DIR%\_common_installer_args.cmd" %*

set "nsi_file=%OUT_FILE%.nsi"
> "%nsi_file%" (
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
    echo VIAddVersionKey "FileDescription" "%WELCOME_TEXT%"
    echo VIAddVersionKey "FileVersion" "%APP_VERSION%"
    if not "%ICON_PATH%"=="" echo Icon "%ICON_PATH%"
    echo Section "MainSection" SEC01
    echo   SetOutPath "$INSTDIR"
    echo   File /r "%LIBSCRIPT_ROOT_DIR%\*.*"
    echo SectionEnd
)

echo Generated %nsi_file%
where makensis >nul 2>&1
if %errorlevel% equ 0 (
    echo Compiling %nsi_file% with makensis...
    makensis "%nsi_file%"
)
exit /b %errorlevel%
