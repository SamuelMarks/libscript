@echo off
set "PATH=%USERPROFILE%\.pyenv\pyenv-win\bin;%USERPROFILE%\.pyenv\pyenv-win\shims;%PATH%"
where pyenv >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  pyenv --version || echo pyenv found
) else (
  echo pyenv skipped (not found)
)
exit /b 0
