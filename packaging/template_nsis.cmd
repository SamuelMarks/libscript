@echo off
:: # template_nsis.cmd
::
:: ## Overview
:: Template file for NSIS installer generation on Windows.
:: Supports component sections, shortcuts, and uninstallation logic.
:: 
:: ## Usage
:: This file is processed during the build phase and not executed directly.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

where sh.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    sh "%SCRIPT_DIR%\template_nsis.sh" %*
    exit /b %ERRORLEVEL%
)

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
if not "%BANNER_TOP_PATH%"=="" (
    echo ^^!define MUI_HEADERIMAGE
    echo ^^!define MUI_HEADERIMAGE_BITMAP "%BANNER_TOP_PATH%"
)
if not "%BANNER_SIDE_PATH%"=="" echo ^^!define MUI_WELCOMEFINISHPAGE_BITMAP "%BANNER_SIDE_PATH%"
echo.
echo Section "Core Files" SEC01
echo   SetOutPath "$INSTDIR"
if defined LIBSCRIPT_ROOT_DIR (
    echo   File /r "%LIBSCRIPT_ROOT_DIR%\*.*"
) else (
    echo   File /r "*.*"
)
echo   ExecWait 'cmd.exe /c "$INSTDIR\stacks\cms\openedx\healthcheck.cmd"'
echo SectionEnd

echo.
echo Section /o "Celery Background Workers & Scheduler" SEC_openedx_workers
echo   ExecWait 'cmd.exe /c "$INSTDIR\stacks\cms\openedx\workers.cmd" start'
echo SectionEnd

echo.
echo Section /o "Import Demo Courseware & Content Libraries" SEC_openedx_demo
echo   ExecWait 'cmd.exe /c "$INSTDIR\stacks\cms\openedx\import_demo.cmd" course'
echo SectionEnd

echo.
echo Section /o "Deploy Micro-Frontends (MFEs)" SEC_openedx_mfes
echo   ExecWait 'cmd.exe /c "$INSTDIR\stacks\cms\openedx\mfe.cmd" build all && "$INSTDIR\stacks\cms\openedx\mfe.cmd" deploy all'
echo SectionEnd

echo.
echo Section "Administrative Shortcuts" SEC_openedx_shortcuts
echo   CreateDirectory "$SMPROGRAMS\%APP_NAME%"
echo   CreateShortcut "$SMPROGRAMS\%APP_NAME%\%APP_NAME% Management Console.lnk" "$INSTDIR\stacks\cms\openedx\cli.cmd"
echo   CreateShortcut "$SMPROGRAMS\%APP_NAME%\%APP_NAME% Healthcheck.lnk" "$INSTDIR\stacks\cms\openedx\healthcheck.cmd"
echo   CreateShortcut "$SMPROGRAMS\%APP_NAME%\%APP_NAME% Database Console.lnk" "$INSTDIR\stacks\cms\openedx\dbshell.cmd" "mysql"
echo   CreateShortcut "$SMPROGRAMS\%APP_NAME%\%APP_NAME% Backup and Restore.lnk" "$INSTDIR\stacks\cms\openedx\backup.cmd"
echo SectionEnd

echo.
echo Section "Uninstall"
echo   ExecWait 'cmd.exe /c "$INSTDIR\stacks\cms\openedx\workers.cmd" stop'
echo   RMDir /r "$SMPROGRAMS\%APP_NAME%"
echo SectionEnd
exit /b 0
