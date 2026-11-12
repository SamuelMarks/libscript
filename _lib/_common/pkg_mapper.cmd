@echo off
:: # pkg_mapper.cmd
::
:: ## Overview
:: Cross-platform package name translation dictionary across native OS package managers.
::
:: ## Usage
:: Maps generic dependency names to platform-specific package identifiers.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

:: ## Labels
::
:: ### :map_package <generic_name>
:: Maps the provided generic name to a manager-specific ID.
::
:: Parameters:
::   %~2 - Generic package name (e.g., 'git', 'nodejs', 'php')
::
:: Returns:
::   MAPPED_PKG - The resulting package ID(s).
::   errorlevel - 0 if mapping found, 1 if not supported.


:: Prevent accidental direct execution
if "%~1"=="" (
    echo This is a LibScript library module and should be called via 'call'.
    exit /b 1
)

:: Dispatch to label
goto %1

:: -----------------------------------------------------------------------------
:: :map_package <generic_name>
:: -----------------------------------------------------------------------------
:: ## map_package
:: Translates a generic package identifier into the native OS package manager name.
:map_package
set "PKG=%~2"
set "MAPPED_PKG="

:: Default PKG_MGR to winget if not defined, as it's built into modern Windows
if "!PKG_MGR!"=="" set "PKG_MGR=winget"

:: --- Mapping Logic ---
:: This follows the patterns established in pkg_mapper.sh

if "!PKG!"=="bun" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Oven-sh.Bun"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=bun"
) else if "!PKG!"=="postgres" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=PostgreSQL.PostgreSQL"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=postgresql"
) else if "!PKG!"=="postgresql" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=PostgreSQL.PostgreSQL"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=postgresql"
) else if "!PKG!"=="mariadb" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=MariaDB.MariaDB"
) else if "!PKG!"=="c_compiler" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=MSYS2.MSYS2"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=mingw"
) else if "!PKG!"=="cpp_compiler" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=MSYS2.MSYS2"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=mingw"
) else if "!PKG!"=="gcc" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=MSYS2.MSYS2"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=mingw"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=gcc"
) else if "!PKG!"=="g++" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=MSYS2.MSYS2"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=mingw"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=gcc"
) else if "!PKG!"=="clang" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=LLVM.LLVM"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=llvm"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=llvm"
) else if "!PKG!"=="llvm" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=LLVM.LLVM"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=llvm"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=llvm"
) else if "!PKG!"=="lld" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=LLVM.LLVM"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=llvm"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=llvm"
) else if "!PKG!"=="tcc" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Bellard.TCC"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=tcc"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=tcc"
) else if "!PKG!"=="tinycc" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Bellard.TCC"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=tcc"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=tcc"
) else if "!PKG!"=="binutils" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=MSYS2.MSYS2"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=mingw"
) else if "!PKG!"=="flex" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=WinFlexBison.win_flex_bison"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=winflexbison3"
) else if "!PKG!"=="bison" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=WinFlexBison.win_flex_bison"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=winflexbison3"
) else if "!PKG!"=="zstd" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Facebook.zstd"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=zstandard"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=zstd"
) else if "!PKG!"=="sqlite" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=SQLite.SQLite"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=sqlite"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=sqlite"
    if "!PKG_MGR!"=="vcpkg" set "MAPPED_PKG=sqlite3"
) else if "!PKG!"=="sqlite3" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=SQLite.SQLite"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=sqlite"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=sqlite"
    if "!PKG_MGR!"=="vcpkg" set "MAPPED_PKG=sqlite3"
) else if "!PKG!"=="make" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=GnuWin32.Make"
) else if "!PKG!"=="git" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Git.Git"
) else if "!PKG!"=="curl" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=cURL.cURL"
) else if "!PKG!"=="tar" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=GnuWin32.Tar"
) else if "!PKG!"=="unzip" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Info-ZIP.UnZip"
) else if "!PKG!"=="csharp" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Microsoft.DotNet.SDK.8"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=dotnet-8.0-sdk"
) else if "!PKG!"=="deno" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=DenoLand.Deno"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=deno"
) else if "!PKG!"=="go" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=GoLang.Go"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=golang"
) else if "!PKG!"=="java" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Microsoft.OpenJDK.17"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=openjdk"
) else if "!PKG!"=="jq" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=jqlang.jq"
) else if "!PKG!"=="kotlin" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=JetBrains.Kotlin"
) else if "!PKG!"=="nodejs" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=OpenJS.NodeJS"
) else if "!PKG!"=="php" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=PHP.PHP"
) else if "!PKG!"=="python" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Python.Python.3.11"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=python3"
) else if "!PKG!"=="ruby" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=RubyInstallerTeam.Ruby"
) else if "!PKG!"=="rust" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Rustlang.Rustup"
) else if "!PKG!"=="httpd" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Apache.HTTPD"
) else if "!PKG!"=="apache2" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Apache.HTTPD"
) else if "!PKG!"=="caddy" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=caddy.caddy"
) else if "!PKG!"=="nginx" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Nginx.Nginx"
) else if "!PKG!"=="certbot" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=EFF.Certbot"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=certbot"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=certbot"
    if "!PKG_MGR!"=="vcpkg" set "MAPPED_PKG=certbot"
) else if "!PKG!"=="etcd" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=etcd.etcd"
) else if "!PKG!"=="rabbitmq" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=RabbitMQ.RabbitMQ"
) else if "!PKG!"=="memcached" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=memcached"
) else if "!PKG!"=="mysql" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Oracle.MySQL"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=mysql"
) else if "!PKG!"=="mysql-server" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Oracle.MySQL"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=mysql"
) else if "!PKG!"=="mysql-client" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Oracle.MySQL"
) else if "!PKG!"=="geos" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=OSGeo.GEOS"
) else if "!PKG!"=="gettext" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=GNU.Gettext"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=gettext"
) else if "!PKG!"=="graphviz" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Graphviz.Graphviz"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=graphviz"
) else if "!PKG!"=="7zip" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=7zip.7zip"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=7zip"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=7zip"
) else if "!PKG!"=="qemu" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=SoftwareFreedomConservancy.QEMU"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=qemu"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=qemu"
) else if "!PKG!"=="virtualbox" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Oracle.VirtualBox"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=virtualbox"
) else if "!PKG!"=="packer" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=HashiCorp.Packer"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=packer"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=packer"
) else if "!PKG!"=="vagrant" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=HashiCorp.Vagrant"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=vagrant"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=vagrant"
) else if "!PKG!"=="openvpn" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=OpenVPNTechnologies.OpenVPN"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=openvpn"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=openvpn"
) else if "!PKG!"=="c" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=LLVM.LLVM"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=llvm"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=llvm"
) else if "!PKG!"=="cc" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=LLVM.LLVM"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=llvm"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=llvm"
) else if "!PKG!"=="cpp" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=LLVM.LLVM"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=llvm"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=llvm"
) else if "!PKG!"=="sh" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=MSYS2.MSYS2"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=msys2"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=busybox"
) else if "!PKG!"=="shellcheck" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=koalaman.shellcheck"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=shellcheck"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=shellcheck"
) else if "!PKG!"=="ninja" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Ninja-build.Ninja"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=ninja"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=ninja"
) else if "!PKG!"=="ccache" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Ccache.Ccache"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=ccache"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=ccache"
) else if "!PKG!"=="sccache" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Mozilla.sccache"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=sccache"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=sccache"
) else if "!PKG!"=="meson" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=mesonbuild.meson"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=meson"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=meson"
) else if "!PKG!"=="nasm" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=NASM.NASM"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=nasm"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=nasm"
) else if "!PKG!"=="yasm" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=yasm"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=yasm"
) else if "!PKG!"=="xmake" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=xmake-io.xmake"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=xmake"
) else if "!PKG!"=="wasmtime" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=BytecodeAlliance.Wasmtime"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=wasmtime"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=wasmtime"
) else if "!PKG!"=="protobuf" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Google.Protobuf"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=protoc"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=protobuf"
) else if "!PKG!"=="pkgconfig" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=pkgconfiglite"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=pkg-config"
) else if "!PKG!"=="make" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=ezwinports.make"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=make"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=make"
) else if "!PKG!"=="swig" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=SWIG.SWIG"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=swig"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=swig"
) else if "!PKG!"=="vcpkg-tool" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=vcpkg"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=vcpkg"
) else if "!PKG!"=="msbuild" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Microsoft.BuildTools"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=visualstudio2022buildtools"
) else if "!PKG!"=="clojure" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=clojure"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=clojure"
) else if "!PKG!"=="crystal" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=crystal"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=crystal"
) else if "!PKG!"=="dart" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Google.DartSDK"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=dart-sdk"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=dart"
) else if "!PKG!"=="erlang" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Erlang.ErlangOTP"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=erlang"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=erlang"
) else if "!PKG!"=="fortran" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=BrechtSanders.WinLibs.POSIX.UCRT"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=mingw"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=gcc"
) else if "!PKG!"=="gleam" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Gleam.Gleam"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=gleam"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=gleam"
) else if "!PKG!"=="groovy" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=groovy"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=groovy"
) else if "!PKG!"=="haskell" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Haskell.GHCup"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=ghc"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=ghc"
) else if "!PKG!"=="lua" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=DEVCOM.Lua"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=lua"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=lua"
) else if "!PKG!"=="nim" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=NimLang.Nim"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=nim"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=nim"
) else if "!PKG!"=="ocaml" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=OCaml.opam"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=ocaml"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=ocaml"
) else if "!PKG!"=="odin" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=odin"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=odin"
) else if "!PKG!"=="perl" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=StrawberryPerl.StrawberryPerl"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=strawberryperl"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=perl"
) else if "!PKG!"=="prolog" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=SWI-Prolog.SWI-Prolog"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=swi-prolog"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=swi-prolog"
) else if "!PKG!"=="racket" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Racket.Racket"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=racket"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=racket"
) else if "!PKG!"=="scala" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=VirtusLab.ScalaCli"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=scala"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=scala"
) else if "!PKG!"=="scheme" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Cisco.ChezScheme"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=chezscheme"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=chezscheme"
) else if "!PKG!"=="tcl" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=magicsplat-tcl-tk"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=tcl"
) else if "!PKG!"=="vala" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=vala"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=vala"
) else if "!PKG!"=="vlang" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=vlang"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=vlang"
) else if "!PKG!"=="maven-wrapper" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=maven"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=maven"
) else if "!PKG!"=="apache" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Apache.HTTPD"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=apache-httpd"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=apache"
) else if "!PKG!"=="cassandra" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=cassandra"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=cassandra"
) else if "!PKG!"=="clickhouse" (
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=clickhouse"
) else if "!PKG!"=="cockroachdb" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=cockroachdb"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=cockroachdb"
) else if "!PKG!"=="couchdb" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Apache.CouchDB"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=couchdb"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=couchdb"
) else if "!PKG!"=="ferretdb" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=FerretDB.FerretDB"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=ferretdb"
) else if "!PKG!"=="firebird" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=FirebirdProject.Firebird"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=firebird"
) else if "!PKG!"=="influxdb" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=InfluxData.InfluxDB"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=influxdb"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=influxdb"
) else if "!PKG!"=="lmdb" (
    if "!PKG_MGR!"=="vcpkg" set "MAPPED_PKG=lmdb"
) else if "!PKG!"=="mssql" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Microsoft.Sqlcmd"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=sqlserver-cmdlineutils"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=sqlcmd"
) else if "!PKG!"=="neo4j" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Neo4j.Neo4j"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=neo4j-community"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=neo4j"
) else if "!PKG!"=="questdb" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=questdb"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=questdb"
) else if "!PKG!"=="rethinkdb" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=rethinkdb"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=rethinkdb"
) else if "!PKG!"=="rocksdb" (
    if "!PKG_MGR!"=="vcpkg" set "MAPPED_PKG=rocksdb"
) else if "!PKG!"=="surrealdb" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=SurrealDB.SurrealDB"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=surreal"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=surreal"
) else if "!PKG!"=="opensearch" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=opensearch"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=opensearch"
) else if "!PKG!"=="solr" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=solr"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=solr"
) else if "!PKG!"=="activemq" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=activemq"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=activemq"
) else if "!PKG!"=="redpanda" (
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=rpk"
) else if "!PKG!"=="zeromq" (
    if "!PKG_MGR!"=="vcpkg" set "MAPPED_PKG=zeromq"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=zeromq"
) else if "!PKG!"=="openresty" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=openresty"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=openresty"
) else if "!PKG!"=="tomcat" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Apache.Tomcat.10"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=tomcat"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=tomcat"
) else if "!PKG!"=="traefik" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=TraefikLabs.Traefik"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=traefik"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=traefik"
) else if "!PKG!"=="glassfish" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=glassfish"
) else if "!PKG!"=="jboss" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=wildfly"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=wildfly"
) else if "!PKG!"=="wildfly" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=wildfly"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=wildfly"
) else if "!PKG!"=="jetty" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=jetty"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=jetty"
) else if "!PKG!"=="payara" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=payara"
) else if "!PKG!"=="fd" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=sharkdp.fd"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=fd"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=fd"
) else if "!PKG!"=="ffmpeg" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Gyan.FFmpeg"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=ffmpeg"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=ffmpeg"
) else if "!PKG!"=="fzf" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=junegunn.fzf"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=fzf"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=fzf"
) else if "!PKG!"=="imagemagick" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=ImageMagick.ImageMagick"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=imagemagick"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=imagemagick"
) else if "!PKG!"=="openssl" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=ShiningLight.OpenSSL.Light"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=openssl"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=openssl"
    if "!PKG_MGR!"=="vcpkg" set "MAPPED_PKG=openssl"
) else if "!PKG!"=="pandoc" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=JohnMacFarlane.Pandoc"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=pandoc"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=pandoc"
) else if "!PKG!"=="ripgrep" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=BurntSushi.ripgrep.MSVC"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=ripgrep"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=ripgrep"
) else if "!PKG!"=="rsync" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=rsync"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=rsync"
) else if "!PKG!"=="sqlite-tools" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=SQLite.SQLite"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=sqlite"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=sqlite"
) else if "!PKG!"=="tree" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=GnuWin32.Tree"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=tree"
) else if "!PKG!"=="vim" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=vim.vim"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=vim"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=vim"
) else if "!PKG!"=="xz" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=tukaani.xz"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=xz"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=xz"
) else if "!PKG!"=="yq" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=MikeFarah.yq"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=yq"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=yq"
) else if "!PKG!"=="zip" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=GnuWin32.Zip"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=zip"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=zip"
) else if "!PKG!"=="crowdsec" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=CrowdSecurity.CrowdSec"
) else if "!PKG!"=="keycloak" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=keycloak"
) else if "!PKG!"=="step-ca" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Smallstep.step-ca"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=step-ca"
) else if "!PKG!"=="vault" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Hashicorp.Vault"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=vault"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=vault"
) else if "!PKG!"=="wireguard" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=WireGuard.WireGuard"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=wireguard"
) else if "!PKG!"=="grafana" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=GrafanaLabs.Grafana.OSS"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=grafana"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=grafana"
) else if "!PKG!"=="loki" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=loki"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=loki"
) else if "!PKG!"=="otel-collector" (
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=otelcol"
) else if "!PKG!"=="prometheus" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Prometheus.Prometheus"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=prometheus"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=prometheus"
) else if "!PKG!"=="vector" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Datadog.Vector"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=vector"
) else if "!PKG!"=="juicefs" (
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=juicefs"
) else if "!PKG!"=="seaweedfs" (
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=seaweedfs"
) else if "!PKG!"=="forgejo" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=forgejo"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=forgejo"
) else if "!PKG!"=="coredns" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=CoreDNS.CoreDNS"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=coredns"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=coredns"
) else if "!PKG!"=="tailscale" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Tailscale.Tailscale"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=tailscale"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=tailscale"
) else if "!PKG!"=="jack" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=JACKAudio.JACK2"
) else if "!PKG!"=="multipass" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Canonical.Multipass"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=multipass"
) else if "!PKG!"=="wsl" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Microsoft.WSL"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=wsl2"
) else if "!PKG!"=="cilium" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Cilium.CiliumCLI"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=cilium-cli"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=cilium-cli"
) else if "!PKG!"=="consul" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=HashiCorp.Consul"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=consul"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=consul"
) else if "!PKG!"=="kubeadm" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Kubernetes.kubeadm"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=kubeadm"
) else if "!PKG!"=="podman" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=RedHat.Podman"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=podman-cli"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=podman"
) else if "!PKG!"=="pulumi" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Pulumi.Pulumi"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=pulumi"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=pulumi"
) else if "!PKG!"=="rancher" (
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=rancher"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=rancher"
) else if "!PKG!"=="terraform" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Hashicorp.Terraform"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=terraform"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=terraform"
) else if "!PKG!"=="tofu" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=OpenTofu.tofu"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=opentofu"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=opentofu"
) else if "!PKG!"=="oci" (
    if "!PKG_MGR!"=="winget" set "MAPPED_PKG=Oracle.OCICLI"
    if "!PKG_MGR!"=="choco" set "MAPPED_PKG=oci-cli"
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=oci-cli"
) else if "!PKG!"=="ovh" (
    if "!PKG_MGR!"=="scoop" set "MAPPED_PKG=ovhcloud-cli"
)

:: If no mapping found, return the original name
if "!MAPPED_PKG!"=="" set "MAPPED_PKG=!PKG!"

:: End with MAPPED_PKG available to caller
endlocal & set "MAPPED_PKG=%MAPPED_PKG%"
exit /b 0
