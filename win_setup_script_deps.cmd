@echo on

:: SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

SET SCRIPT_ROOT_DIR=%~dp0
SET TOOLS_DIR=%~dp0\tools
SET PATH=%TOOLS_DIR%;%PATH%
SET previous_wd=%cd%

WHERE curl >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
  ECHO "TODO: Fallback as per WINDOWS.md, to download curl.exe" && exit %ERRORLEVEL%
  IF NOT EXIST %TOOLS_DIR% md %TOOLS_DIR%
  cd %TOOLS_DIR%
  :: [x86] https://github.com/lordmulder/cURL-build-win32/releases/download/2024-12-14/curl-8.11.1-windows-x86.2024-12-14.zip
  :: [x86_64] https://github.com/lordmulder/cURL-build-win32/releases/download/2024-12-14/curl-8.11.1-windows-x64.2024-12-14.zip
  cd %previous_wd%
)

WHERE tar >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
  ECHO "TODO: Install tar.exe" && exit %ERRORLEVEL%
  IF NOT EXIST %TOOLS_DIR% md %TOOLS_DIR%
  cd %TOOLS_DIR%
  :: [x86] https://sourceforge.net/projects/bsdtar/files/bsdtar-3.2.0_win32.zip/download
  :: [x86_64] https://github.com/aspect-build/bsdtar-prebuilt/releases/download/v3.7.5-2/tar_windows_x86_64.exe
  cd %previous_wd%
)

WHERE bash >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
    WHERE sh >nul 2>nul
    IF %ERRORLEVEL% NEQ 0 (
      WHERE busybox >nul 2>nul
      IF %ERRORLEVEL% NEQ 0 (
        ECHO "TODO: Install busybox.exe as per WINDOWS.md" && exit %ERRORLEVEL%
        IF NOT EXIST %TOOLS_DIR% md %TOOLS_DIR%
        cd %TOOLS_DIR%
        :: [x86] https://frippery.org/files/busybox/busybox.exe
        :: [x86_64] https://frippery.org/files/busybox/busybox64u.exe
        :: [ARM] https://frippery.org/files/busybox/busybox64a.exe
        cd %previous_wd%
        doskey sh=busybox
      ) else doskey sh=busybox
    )
) else doskey sh=bash

WHERE jq >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
  ECHO "TODO: Install jq.exe" && exit %ERRORLEVEL%
  IF NOT EXIST %TOOLS_DIR% md %TOOLS_DIR%
  cd %TOOLS_DIR%
  :: [x86] https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-windows-i386.exe
  :: [x86_64] https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-windows-amd64.exe
  cd %previous_wd%
)

WHERE envsubst >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
  IF NOT EXIST %TOOLS_DIR% md %TOOLS_DIR%
  cd %TOOLS_DIR%
  curl -OL https://github.com/SamuelMarks/win-bin/releases/download/0th/envsubst.zip && tar -xf envsubst.zip
  cd %previous_wd%
)

:end
@%COMSPEC% /C exit %ERRORLEVEL% >nul
