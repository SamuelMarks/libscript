@echo off
where opam >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  opam --version || echo opam found
) else (
  echo opam skipped (not found)
)
exit /b 0
