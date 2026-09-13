@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where etcdctl >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "URL=https://github.com/etcd-io/etcd/releases/download/v3.7.1/etcd-v3.7.1-windows-amd64.zip"
set "TEMP_ZIP=%TEMP%\etcd.zip"
set "TEMP_EXTRACT=%TEMP%\etcd_extract"

echo Downloading etcd from %URL%...
curl -sSL "%URL%" -o "%TEMP_ZIP%"
if errorlevel 1 (
    echo Failed to download etcd.
    exit /b 1
)

if not exist "%TEMP_EXTRACT%" mkdir "%TEMP_EXTRACT%"
tar -xf "%TEMP_ZIP%" -C "%TEMP_EXTRACT%"
del "%TEMP_ZIP%" >nul 2>&1

for /r "%TEMP_EXTRACT%" %%F in (etcd.exe etcdctl.exe etcdutl.exe) do (
    if exist "%%F" copy /y "%%F" "%DEST_DIR%" >nul
)

rd /s /q "%TEMP_EXTRACT%" >nul 2>&1

if exist "%DEST_DIR%\etcdctl.exe" (
    echo etcd installed successfully to %DEST_DIR%.
    exit /b 0
)

exit /b 1
