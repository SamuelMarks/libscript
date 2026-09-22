@echo off
:: # harvest_payload.cmd
::
:: ## Overview
:: Harvests the complete LibScript repository into a deployment staging directory or WiX
:: manifest fragment while strictly respecting .gitignore exclusion rules.
:: Embeds the core execution engine, library recipes, stacks, CLIs, and utilities
:: required for standalone, self-contained installation on Windows targets.
:: Delegates to harvest_payload.ps1 with complete argument passthrough.
::
:: ## Usage
:: call packaging\harvest_payload.cmd [OPTIONS]
::
:: Options:
::   --output-dir <dir>       Target staging directory where harvested files will be copied
::   --manifest-file <path>   Path to output newline-delimited list of harvested relative paths
::   --wix-fragment <path>    Path to output WiX XML (<Fragment>) file with components and files
::   --component-group <id>   WiX ComponentGroup ID (default: LibscriptHarvestedComponents)
::   --directory-id <id>      WiX Directory ID for root of payload (default: LIBSCRIPT_FOLDER)
::   --root-dir <path>        Root directory of repository (default: auto-detected)
::   --help, -h               Show this help text

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

if "%~1"=="--help" goto show_help
if "%~1"=="-h" goto show_help
if "%~1"=="/?" goto show_help
goto run_script

:show_help
echo Usage: %~nx0 [OPTIONS]
echo.
echo Options:
echo   --output-dir ^<dir^>       Target staging directory for harvested files
echo   --manifest-file ^<path^>   Output file containing relative paths list
echo   --wix-fragment ^<path^>    Output file containing WiX XML fragment
echo   --component-group ^<id^>   WiX ComponentGroup ID (default: LibscriptHarvestedComponents)
echo   --directory-id ^<id^>      WiX Directory ID (default: LIBSCRIPT_FOLDER)
echo   --root-dir ^<path^>        Root repository directory
echo   --include-cache ^<dir^>    Include hydrated offline cache directory into payload
echo   --help, -h               Show this help text
exit /b 0

:run_script
set "PS1_FILE=%SCRIPT_DIR%\harvest_payload.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%" %*
exit /b %ERRORLEVEL%
