@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where gradle >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\gradle"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "URL=https://services.gradle.org/distributions/gradle-8.10.2-bin.zip"
set "TEMP_ZIP=%TEMP%\gradle.zip"

echo Downloading Gradle from %URL%...
curl -sSL "%URL%" -o "%TEMP_ZIP%"
if errorlevel 1 (
    echo Failed to download Gradle.
    exit /b 1
)

tar -xf "%TEMP_ZIP%" -C "%DEST_DIR%"
del "%TEMP_ZIP%" >nul 2>&1

for /d %%G in ("%DEST_DIR%\gradle-*") do (
    if exist "%%G\bin\gradle.bat" (
        (
            echo @echo off
            echo "%%G\bin\gradle.bat" %%*
        ) > "%USERPROFILE%\.local\bin\gradle.cmd"
        echo Gradle installed successfully.
        exit /b 0
    )
)

exit /b 1
