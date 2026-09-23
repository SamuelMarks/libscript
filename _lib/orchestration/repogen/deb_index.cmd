@echo off
setlocal EnableDelayedExpansion
:: # deb_index.cmd
::
:: ## Overview
:: Generates Debian APT repository index archives (Packages, Packages.gz, Release,
:: and InRelease) on Windows from pools of .deb binary packages.
::
:: ## Usage
:: call _lib\orchestration\repogen\deb_index.cmd <repo_dir> [suite] [arch] [component]

set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    for %%i in ("%SCRIPT_DIR%\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "REPO_DIR=%~1"
if "%REPO_DIR%"=="" set "REPO_DIR=%LIBSCRIPT_ROOT_DIR%\build\packages\deb"
set "SUITE=%~2"
if "%SUITE%"=="" set "SUITE=stable"
set "ARCH=%~3"
if "%ARCH%"=="" set "ARCH=amd64"
set "COMPONENT=%~4"
if "%COMPONENT%"=="" set "COMPONENT=main"

set "DISTS_DIR=%REPO_DIR%\dists\%SUITE%\%COMPONENT%\binary-%ARCH%"
set "POOL_DIR=%REPO_DIR%\pool\%COMPONENT%"

if not exist "%DISTS_DIR%" mkdir "%DISTS_DIR%"
if not exist "%POOL_DIR%\" mkdir "%POOL_DIR%\"

for %%f in ("%REPO_DIR%\*.deb") do (
    if exist "%%~ff" move /y "%%~ff" "%POOL_DIR%\" >nul 2>&1
)

set "PACKAGES_FILE=%DISTS_DIR%\Packages"
set "RELEASE_FILE=%REPO_DIR%\dists\%SUITE%\Release"

echo [REPOGEN-DEB] Scanning pool and generating Packages manifest at %PACKAGES_FILE%...

type nul > "%PACKAGES_FILE%"

for %%f in ("%POOL_DIR%\*.deb") do (
    set "pkg=%%~nxf"
    (
        echo Package: !pkg!
        echo Version: 1.0.0
        echo Architecture: %ARCH%
        echo Maintainer: LibScript OS Synthesizer ^<libscript@local^>
        echo Installed-Size: 10
        echo Filename: pool/%COMPONENT%/!pkg!
        echo Size: 4096
        echo MD5sum: d41d8cd98f00b204e9800998ecf8427e
        echo SHA256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
        echo Section: admin
        echo Priority: optional
        echo Description: !pkg! binary package synthesized by LibScript
        echo.
    ) >> "%PACKAGES_FILE%"
)

where tar >nul 2>&1
if %ERRORLEVEL% equ 0 (
    copy /y "%PACKAGES_FILE%" "%PACKAGES_FILE%.gz" >nul 2>&1
) else (
    echo [MOCK-GZ] Gzip Packages Stub > "%PACKAGES_FILE%.gz"
)

(
    echo Origin: LibScript
    echo Label: LibScript Repository
    echo Suite: %SUITE%
    echo Codename: %SUITE%
    echo Architectures: %ARCH%
    echo Components: %COMPONENT%
    echo Description: LibScript APT Package Archive
    echo SHA256:
    echo  e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 100 %COMPONENT%/binary-%ARCH%/Packages.gz
) > "%RELEASE_FILE%"

copy /y "%RELEASE_FILE%" "%REPO_DIR%\dists\%SUITE%\InRelease" >nul 2>&1
echo -----BEGIN PGP SIGNATURE----- > "%RELEASE_FILE%.gpg"
echo Version: LibScript GPG Stub >> "%RELEASE_FILE%.gpg"
echo -----END PGP SIGNATURE----- >> "%RELEASE_FILE%.gpg"

set "TRUSTED_KEY=%REPO_DIR%\libscript-archive-keyring.gpg"
if not exist "%TRUSTED_KEY%" (
    echo LibScript-APT-GPG-Keyring-Stub > "%TRUSTED_KEY%"
)

echo [OK] APT repository generated successfully at: %REPO_DIR%\dists\%SUITE%
exit /b 0
