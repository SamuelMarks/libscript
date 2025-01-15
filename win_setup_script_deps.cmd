@echo on

:: Note: This is only used for generating Dockerfiles, shell scripts, and cmd scripts.
:: The scripts generated are fully native and need no executables not found in PATH.
:: (though `tar` and `curl` have only been there since ~2017 / by-default since 2019)

:: SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

SET SCRIPT_ROOT_DIR=%~dp0
IF NOT DEFINED %TOOLS_DIR% SET TOOLS_DIR=%~dp0\tools
SET PATH=%TOOLS_DIR%;%PATH%
SET previous_wd=%cd%

:: Fallback for IA64, EM64T, X86
SET ARCH="x86"
IF %PROCESSOR_ARCHITECTURE% EQ "AMD64" (
  SET ARCH="x86_64"
) ELSE IF %PROCESSOR_ARCHITECTURE% EQ "ARM64" (
  SET ARCH=%PROCESSOR_ARCHITECTURE%
)

WHERE curl >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
  ECHO "TODO: Fallback as per WINDOWS.md, to download curl.exe" && exit %ERRORLEVEL%
  IF NOT EXIST %TOOLS_DIR% md %TOOLS_DIR%
  cd %TOOLS_DIR%
  IF %ARCH% EQ "x86_64" (
    curl -L -o curl.zip https://github.com/lordmulder/cURL-build-win32/releases/download/2024-12-14/curl-8.11.1-windows-x64.2024-12-14.zip
  ) ELSE (
    curl -L -o curl.zip https://github.com/lordmulder/cURL-build-win32/releases/download/2024-12-14/curl-8.11.1-windows-x86.2024-12-14.zip
  )
  tar -xf curl.zip
  cd %previous_wd%
)

WHERE tar >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
  ECHO "TODO: Install tar.exe" && exit %ERRORLEVEL%
  IF NOT EXIST %TOOLS_DIR% md %TOOLS_DIR%
  cd %TOOLS_DIR%
  IF %ARCH% EQ "x86_64" (
      curl -L -o tar.exe https://github.com/aspect-build/bsdtar-prebuilt/releases/download/v3.7.5-2/tar_windows_x86_64.exe
    ) ELSE (
      curl -L -o bsdtar.zip https://sourceforge.net/projects/bsdtar/files/bsdtar-3.2.0_win32.zip/download
      tar -xf bsdtar.zip
    )
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
        IF %ARCH% EQ "x86_64" (
          curl -L -o busybox.exe https://frippery.org/files/busybox/busybox64u.exe
        ) ELSE IF %ARCH% EQ "ARM64" (
          curl -L -o busybox.exe https://frippery.org/files/busybox/busybox64a.exe
        ) ELSE (
          curl -L -o busybox.exe https://frippery.org/files/busybox/busybox.exe
        )
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
  IF %ARCH% EQ "x86_64" (
    curl -L -o jq.exe https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-windows-amd64.exe
  ) ELSE (
    curl -L -o jq.exe https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-windows-i386.exe
  )
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
