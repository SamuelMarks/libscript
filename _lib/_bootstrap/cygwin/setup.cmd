@echo off
setlocal
where cygcheck >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

set "CYGWIN_ROOT=C:\cygwin64"
if exist "%CYGWIN_ROOT%\bin\cygcheck.exe" (
    echo [INFO] Cygwin found at %CYGWIN_ROOT%. Adding to PATH...
    set "PATH=%CYGWIN_ROOT%\bin;%PATH%"
    goto :eof
)

echo [INFO] Bootstrapping Cygwin environment natively for Windows...
set "CYGWIN_URL=https://cygwin.com/setup-x86_64.exe"
set "CYGWIN_OUT=%TEMP%\cygwin-setup.exe"

certutil -urlcache -split -f "%CYGWIN_URL%" "%CYGWIN_OUT%" >nul
if exist "%CYGWIN_OUT%" (
    echo [INFO] Running unattended Cygwin installation to %CYGWIN_ROOT%...
    "%CYGWIN_OUT%" --quiet-mode --root "%CYGWIN_ROOT%" --site http://mirrors.kernel.org/sourceware/cygwin/ --packages wget,curl,tar,gawk,bzip2,git
    echo [INFO] Cygwin successfully installed. Adding to PATH...
    set "PATH=%CYGWIN_ROOT%\bin;%PATH%"
) else (
    echo [ERROR] Failed to download Cygwin installer.
)
