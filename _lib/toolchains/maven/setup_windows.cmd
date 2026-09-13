@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where mvn >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\maven"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "URL=https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.zip"
set "TEMP_ZIP=%TEMP%\maven.zip"

echo Downloading Maven from %URL%...
curl -sSL "%URL%" -o "%TEMP_ZIP%"
if errorlevel 1 (
    echo Failed to download Maven.
    exit /b 1
)

tar -xf "%TEMP_ZIP%" -C "%DEST_DIR%"
del "%TEMP_ZIP%" >nul 2>&1

for /d %%M in ("%DEST_DIR%\apache-maven-*") do (
    if exist "%%M\bin\mvn.cmd" (
        (
            echo @echo off
            echo "%%M\bin\mvn.cmd" %%*
        ) > "%USERPROFILE%\.local\bin\mvn.cmd"
        echo Maven installed successfully.
        exit /b 0
    )
)

exit /b 1
