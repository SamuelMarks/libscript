@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
:: # publish_release.cmd
::
:: ## Overview
:: Publishes built release packages, installer artifacts, and cryptographic
:: SHA256 checksums to GitHub Releases on Windows.
::
:: ## Usage
:: devtools\ci\publish_release.cmd --tag <tag> [--dist-dir <dir>] [--title <title>] [--draft] [--prerelease]

if "%~1"=="" goto :no_args
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :parse_args

:: ## show_help
:: Displays usage instructions and supported command-line options.
:show_help
echo Usage: %~nx0 --tag ^<tag^> [OPTIONS]
echo Publishes installer artifacts and checksums to GitHub Releases.
echo.
echo Options:
echo   --tag ^<tag^>         Release tag name (required, e.g. v1.0.0).
echo   --dist-dir ^<dir^>    Directory containing built release assets (default: dist).
echo   --title ^<title^>     Release title (default: matches tag name).
echo   --draft             Publish release as a draft.
echo   --prerelease        Publish release as a pre-release.
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:: ## no_args
:: Handles missing arguments error.
:no_args
echo [ERROR] Missing required arguments. >&2
call :show_help >&2
exit /b 1

:: ## parse_args
:: Parses command-line flags and parameters.
:parse_args
set "REL_TAG="
set "DIST_DIR=dist"
set "REL_TITLE="
set "IS_DRAFT=false"
set "IS_PRERELEASE=false"

:args_loop
if "%~1"=="" goto :validate_args
if /I "%~1"=="--tag" (
    set "REL_TAG=%~2"
    shift
    shift
    goto :args_loop
)
if /I "%~1"=="--dist-dir" (
    set "DIST_DIR=%~2"
    shift
    shift
    goto :args_loop
)
if /I "%~1"=="--title" (
    set "REL_TITLE=%~2"
    shift
    shift
    goto :args_loop
)
if /I "%~1"=="--draft" (
    set "IS_DRAFT=true"
    shift
    goto :args_loop
)
if /I "%~1"=="--prerelease" (
    set "IS_PRERELEASE=true"
    shift
    goto :args_loop
)
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
echo [ERROR] Unknown option: %~1 >&2
exit /b 1

:: ## validate_args
:: Checks required parameters and paths.
:validate_args
if not defined REL_TAG (
    echo [ERROR] Missing required parameter: --tag ^<tag^> >&2
    exit /b 1
)

if not defined REL_TITLE set "REL_TITLE=%REL_TAG%"

if not exist "%DIST_DIR%" (
    echo [ERROR] Distribution directory not found: %DIST_DIR% >&2
    exit /b 1
)

:: ## execute_publish
:: Dispatches to GitHub CLI or PowerShell.
:execute_publish
echo [INFO] Publishing release assets for tag "%REL_TAG%" from "%DIST_DIR%"...

where gh >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] GitHub CLI (gh) not found in PATH. >&2
    exit /b 1
)

gh release view "%REL_TAG%" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo [INFO] Release "%REL_TAG%" already exists. Uploading assets with clobber...
    gh release upload "%REL_TAG%" "%DIST_DIR%\*" --clobber
    if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
) else (
    echo [INFO] Creating new release "%REL_TAG%"...
    if "%IS_DRAFT%"=="true" if "%IS_PRERELEASE%"=="true" (
        gh release create "%REL_TAG%" --title "%REL_TITLE%" --generate-notes --draft --prerelease "%DIST_DIR%\*"
        if !ERRORLEVEL! neq 0 exit /b !ERRORLEVEL!
    ) else if "%IS_DRAFT%"=="true" (
        gh release create "%REL_TAG%" --title "%REL_TITLE%" --generate-notes --draft "%DIST_DIR%\*"
        if !ERRORLEVEL! neq 0 exit /b !ERRORLEVEL!
    ) else if "%IS_PRERELEASE%"=="true" (
        gh release create "%REL_TAG%" --title "%REL_TITLE%" --generate-notes --prerelease "%DIST_DIR%\*"
        if !ERRORLEVEL! neq 0 exit /b !ERRORLEVEL!
    ) else (
        gh release create "%REL_TAG%" --title "%REL_TITLE%" --generate-notes "%DIST_DIR%\*"
        if !ERRORLEVEL! neq 0 exit /b !ERRORLEVEL!
    )
)

echo [SUCCESS] Release assets successfully published for %REL_TAG%
exit /b 0
