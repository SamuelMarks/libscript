@echo off
setlocal
where composer >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo [PASS] Composer found.
    composer --version
    exit /b 0
) else (
    echo [FAIL] Composer not found.
    exit /b 1
)
endlocal
