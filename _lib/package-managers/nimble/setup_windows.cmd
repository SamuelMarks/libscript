@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for nimble on Windows.
:: Prepares and configures nimble on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript nimble installation on Windows.

set "THIS_FILE=%~f0"

where nimble >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "URL=https://nim-lang.org/download/nim-2.2.0_x64.zip"
set "TEMP_ZIP=%TEMP%\nim.zip"
set "TEMP_EXTRACT=%TEMP%\nim_extract"

echo Downloading Nim and Nimble from %URL%...
curl -sSL "%URL%" -o "%TEMP_ZIP%"
if errorlevel 1 (
    echo Failed to download Nim.
    exit /b 1
)

if not exist "%TEMP_EXTRACT%" mkdir "%TEMP_EXTRACT%"
tar -xf "%TEMP_ZIP%" -C "%TEMP_EXTRACT%"
del "%TEMP_ZIP%" >nul 2>&1

for /d %%D in ("%TEMP_EXTRACT%\nim-*") do (
    if exist "%%D\bin" (
        xcopy /y /e /q "%%D\bin\*" "%DEST_DIR%\" >nul
    )
)
for /r "%TEMP_EXTRACT%" %%F in (nimble.exe nim.exe *.dll) do (
    if exist "%%F" copy /y "%%F" "%DEST_DIR%" >nul
)

rd /s /q "%TEMP_EXTRACT%" >nul 2>&1

if exist "%DEST_DIR%\nimble.exe" (
    echo nimble installed successfully.
    exit /b 0
)

exit /b 1
