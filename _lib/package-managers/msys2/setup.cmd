@echo off
setlocal
where pacman >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

set "MSYS2_ROOT=C:\msys64"
if exist "%MSYS2_ROOT%\usr\bin\pacman.exe" (
    echo [INFO] MSYS2 pacman found at %MSYS2_ROOT%. Adding to PATH...
    set "PATH=%MSYS2_ROOT%\usr\bin;%PATH%"
    goto :eof
)

echo [INFO] Bootstrapping MSYS2 environment natively for Windows...
set "MSYS2_URL=https://github.com/msys2/msys2-installer/releases/download/2024-01-13/msys2-base-x86_64-20240113.sfx.exe"
set "MSYS2_OUT=%TEMP%\msys2-installer.exe"

certutil -urlcache -split -f "%MSYS2_URL%" "%MSYS2_OUT%" >nul
if exist "%MSYS2_OUT%" (
    echo [INFO] Extracting MSYS2 base to %MSYS2_ROOT%...
    "%MSYS2_OUT%" -y -o"C:\"
    echo [INFO] Updating core packages (requires network)...
    "%MSYS2_ROOT%\usr\bin\bash.exe" -lc "pacman --noconfirm -Syuu"
    echo [INFO] MSYS2 successfully installed to %MSYS2_ROOT%.
) else (
    echo [ERROR] Failed to download MSYS2 installer.
)
