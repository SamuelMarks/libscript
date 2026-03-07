@echo off
set "PATH=%USERPROFILE%\.ghcup\bin;%PATH%"
where cabal >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  cabal --version || echo cabal found
) else (
  echo cabal skipped (not found)
)
exit /b 0
