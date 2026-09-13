@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where kotlinc >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\kotlin"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "URL=https://github.com/JetBrains/kotlin/releases/download/v2.1.10/kotlin-compiler-2.1.10.zip"
set "TEMP_ZIP=%TEMP%\kotlin.zip"

echo Downloading Kotlin compiler from %URL%...
curl -sSL "%URL%" -o "%TEMP_ZIP%"
if errorlevel 1 (
    echo Failed to download Kotlin compiler.
    exit /b 1
)

tar -xf "%TEMP_ZIP%" -C "%DEST_DIR%"
del "%TEMP_ZIP%" >nul 2>&1

if exist "%DEST_DIR%\kotlinc\bin\kotlinc.bat" (
    (
        echo @echo off
        echo "%DEST_DIR%\kotlinc\bin\kotlinc.bat" %%*
    ) > "%USERPROFILE%\.local\bin\kotlinc.cmd"
    echo Kotlin compiler installed successfully.
    exit /b 0
)

exit /b 1
