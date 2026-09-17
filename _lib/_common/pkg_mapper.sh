#!/bin/sh
# ## Overview
# Cross-platform package name translation dictionary across native OS package managers.
#
# ## Usage
# Maps generic dependency names to platform-specific package identifiers.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

# LibScript Package Mapper Module (POSIX)
#

# ## map_package
# Executes map_package functionality.
map_package() {
  pkg="${1}"
  
  if [ "${PKG_MGR}" = "apk" ]; then
    case "$pkg" in
      npm) printf "npm\n"; return 0 ;;
      nuget) printf "dotnet9-sdk\n"; return 0 ;;
      nimble) printf "nimble\n"; return 0 ;;
    esac
  fi
  
  case "${pkg}" in
    'sh')
      case "${PKG_MGR}" in
        *) printf 'bash\n' ;;
      esac
      ;;
    'bash')
      case "${PKG_MGR}" in
        *) printf 'bash\n' ;;
      esac
      ;;
    'dash')
      case "${PKG_MGR}" in
        *) printf 'dash\n' ;;
      esac
      ;;
    'bun')
      case "${PKG_MGR}" in
        'brew') printf 'oven-sh/bun/bun\n' ;;
        'winget') printf 'Oven-sh.Bun\n' ;;
        'choco') printf 'bun\n' ;;
        'apk') printf 'bun\n' ;;
        'pacman') printf 'bun-bin\n' ;;
        *) return 1 ;;
      esac
      ;;
    'postgres'|'postgresql')
      case "${PKG_MGR}" in
        'apk') printf 'postgresql14 postgresql14-contrib postgresql14-openrc\n' ;;
        'apt-get') printf 'postgresql-common postgresql-server-dev-14 postgresql-14\n' ;;
        'dnf') printf 'postgresql-server postgresql-contrib\n' ;;
        'yum') printf 'postgresql-server postgresql-contrib\n' ;;
        'zypper') printf 'postgresql-server\n' ;;
        'pacman') printf 'postgresql\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'ooce/database/postgresql-17 ooce/library/postgresql-17\n'
          else
            printf 'postgresql14-server postgresql14-client\n'
          fi
          ;;
        'brew') printf 'postgresql@14\n' ;;
        'winget') printf 'PostgreSQL.PostgreSQL\n' ;;
        'choco') printf 'postgresql\n' ;;
        'emerge') printf 'dev-db/postgresql\n' ;;
        *) printf 'postgresql\n' ;;
      esac
      ;;
    'mariadb')
      case "${PKG_MGR}" in
        'apk') printf 'mariadb mariadb-client\n' ;;
        'apt-get'|'dnf'|'yum'|'zypper'|'pacman') printf 'mariadb-server\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'ooce/database/mariadb-114 ooce/library/mariadb-114\n'
          else
            printf 'mariadb114-server mariadb114-client\n'
          fi
          ;;
        'winget') printf 'MariaDB.MariaDB\n' ;;
        *) printf 'mariadb\n' ;;
      esac
      ;;
    'mongodb')
      case "${PKG_MGR}" in
        'apt-get') return 1 ;;
        'brew') printf 'mongodb/brew/mongodb-community\n' ;;
        *) printf 'mongodb\n' ;;
      esac
      ;;
    'rabbitmq-server')
      case "${PKG_MGR}" in
        'brew') printf 'rabbitmq\n' ;;
        *) printf 'rabbitmq-server\n' ;;
      esac
      ;;
    'clang')
      case "${PKG_MGR}" in
        'brew') printf 'llvm\n' ;;
        *) printf 'clang\n' ;;
      esac
      ;;
    'libpq-dev')
      case "${PKG_MGR}" in
        'brew') printf 'libpq\n' ;;
        *) printf 'libpq-dev\n' ;;
      esac
      ;;
    'libsqlite3-dev')
      case "${PKG_MGR}" in
        'brew') printf 'sqlite\n' ;;
        *) printf 'libsqlite3-dev\n' ;;
      esac
      ;;
    'mysql'|'mysql-server')
      case "${PKG_MGR}" in
        'apk') printf 'mysql mysql-client\n' ;;
        'apt-get') printf 'default-mysql-server\n' ;;
        'dnf'|'yum') printf 'mysql-server\n' ;;
        'zypper') printf 'mysql-community-server\n' ;;
        'pacman') printf 'mariadb\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'database/mysql-80\n'
          else
            printf 'databases/mysql84-server\n'
          fi
          ;;
        'brew') printf 'mysql\n' ;;
        'winget') printf 'Oracle.MySQL\n' ;;
        'choco') printf 'mysql\n' ;;
        *) printf 'mysql-server\n' ;;
      esac
      ;;
    'mysql-client'|'mysqlclient'|'libmysqlclient-dev'|'default-libmysqlclient-dev')
      case "${PKG_MGR}" in
        'apk') printf 'mariadb-connector-c-dev mariadb-client\n' ;;
        'apt-get') printf 'default-libmysqlclient-dev default-mysql-client\n' ;;
        'dnf'|'yum') printf 'mysql-devel mysql\n' ;;
        'zypper') printf 'libmysqlclient-devel mysql-client\n' ;;
        'pacman') printf 'mariadb-libs mariadb-clients\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'database/mysql-80/client\n'
          else
            printf 'databases/mysql84-client\n'
          fi
          ;;
        'brew') printf 'mysql-client\n' ;;
        'winget') printf 'Oracle.MySQL\n' ;;
        *) printf 'mysql-client\n' ;;
      esac
      ;;
    'xmlsec1'|'libxmlsec1'|'libxmlsec1-dev'|'xmlsec')
      case "${PKG_MGR}" in
        'apk') printf 'xmlsec-dev libxml2-dev\n' ;;
        'apt-get') printf 'libxmlsec1-dev libxmlsec1-openssl libxml2-dev\n' ;;
        'dnf'|'yum') printf 'xmlsec1-devel xmlsec1-openssl-devel libxml2-devel\n' ;;
        'zypper') printf 'xmlsec1-devel xmlsec1-openssl-devel libxml2-devel\n' ;;
        'pacman') printf 'xmlsec libxml2\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'library/security/xmlsec\n'
          else
            printf 'security/xmlsec1 textproc/libxml2\n'
          fi
          ;;
        'brew') printf 'libxmlsec1 libxml2\n' ;;
        *) return 1 ;;
      esac
      ;;
    'geos'|'libgeos'|'libgeos-dev')
      case "${PKG_MGR}" in
        'apk') printf 'geos-dev\n' ;;
        'apt-get') printf 'libgeos-dev\n' ;;
        'dnf'|'yum') printf 'geos-devel\n' ;;
        'zypper') printf 'geos-devel\n' ;;
        'pacman') printf 'geos\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'library/geos\n'
          else
            printf 'graphics/geos\n'
          fi
          ;;
        'brew') printf 'geos\n' ;;
        'winget') printf 'OSGeo.GEOS\n' ;;
        *) printf 'geos\n' ;;
      esac
      ;;
    'gettext')
      case "${PKG_MGR}" in
        'apk') printf 'gettext gettext-dev\n' ;;
        'apt-get') printf 'gettext\n' ;;
        'dnf'|'yum') printf 'gettext gettext-devel\n' ;;
        'zypper') printf 'gettext-tools gettext-runtime\n' ;;
        'pacman') printf 'gettext\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'text/gnu-gettext\n'
          else
            printf 'devel/gettext\n'
          fi
          ;;
        'brew') printf 'gettext\n' ;;
        'winget') printf 'GNU.Gettext\n' ;;
        'choco') printf 'gettext\n' ;;
        *) printf 'gettext\n' ;;
      esac
      ;;
    'graphviz'|'graphviz-dev')
      case "${PKG_MGR}" in
        'apk') printf 'graphviz graphviz-dev\n' ;;
        'apt-get') printf 'graphviz graphviz-dev\n' ;;
        'dnf'|'yum') printf 'graphviz graphviz-devel\n' ;;
        'zypper') printf 'graphviz graphviz-devel\n' ;;
        'pacman') printf 'graphviz\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'image/graphviz\n'
          else
            printf 'graphics/graphviz\n'
          fi
          ;;
        'brew') printf 'graphviz\n' ;;
        'winget') printf 'Graphviz.Graphviz\n' ;;
        'choco') printf 'graphviz\n' ;;
        *) printf 'graphviz\n' ;;
      esac
      ;;
    'rdfind')
      case "${PKG_MGR}" in
        'apt-get') printf 'rdfind\n' ;;
        'dnf'|'yum') printf 'rdfind\n' ;;
        'zypper') printf 'rdfind\n' ;;
        'pacman') printf 'rdfind\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            return 1
          else
            printf 'sysutils/rdfind\n'
          fi
          ;;
        'brew') printf 'rdfind\n' ;;
        *) return 1 ;;
      esac
      ;;
    'exim'|'exim4')
      case "${PKG_MGR}" in
        'apt-get') printf 'exim4-daemon-light\n' ;;
        'apk') printf 'exim\n' ;;
        'dnf'|'yum') printf 'exim\n' ;;
        'zypper') printf 'exim\n' ;;
        'pacman') printf 'exim\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'service/network/smtp/sendmail\n'
          else
            printf 'mail/exim\n'
          fi
          ;;
        'brew') printf 'exim\n' ;;
        *) return 1 ;;
      esac
      ;;
    'c'|'cc'|'c_compiler')
      case "${PKG_MGR}" in
        'apk') printf 'gcc musl-dev\n' ;;
        'apt-get') printf 'build-essential\n' ;;
        'dnf') printf 'gcc\n' ;;
        'yum') printf 'gcc\n' ;;
        'zypper') printf 'gcc\n' ;;
        'pacman') printf 'gcc\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'developer/gcc14\n'
          else
            printf 'gcc\n'
          fi
          ;;
        'brew') printf 'gcc\n' ;;
        'port') printf 'gcc\n' ;;
        'winget') printf 'MSYS2.MSYS2\n' ;;
        'choco') printf 'mingw\n' ;;
        'emerge') printf 'sys-devel/gcc\n' ;;
        'xbps') printf 'gcc\n' ;;
        'swupd') printf 'c-basic\n' ;;
        'eopkg') printf 'c-compiler\n' ;;
        'apt-cyg') printf 'gcc-core\n' ;;
        *) printf 'gcc\n' ;;
      esac
      ;;
    'cpp'|'cpp_compiler')
      case "${PKG_MGR}" in
        'apk') printf 'g++ musl-dev\n' ;;
        'apt-get') printf 'build-essential\n' ;;
        'dnf') printf 'gcc-c++\n' ;;
        'yum') printf 'gcc-c++\n' ;;
        'zypper') printf 'gcc-c++\n' ;;
        'pacman') printf 'gcc\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'developer/gcc14\n'
          else
            printf 'gcc\n'
          fi
          ;;
        'brew') printf 'gcc\n' ;;
        'port') printf 'gcc\n' ;;
        'winget') printf 'MSYS2.MSYS2\n' ;;
        'choco') printf 'mingw\n' ;;
        'emerge') printf 'sys-devel/gcc\n' ;;
        'xbps') printf 'gcc\n' ;;
        'swupd') printf 'c-basic\n' ;;
        'eopkg') printf 'c-compiler\n' ;;
        'apt-cyg') printf 'gcc-g++\n' ;;
        *) printf 'g++\n' ;;
      esac
      ;;
    'gcc')
      case "${PKG_MGR}" in
        'apk') printf 'gcc musl-dev\n' ;;
        'apt-get') printf 'build-essential\n' ;;
        'winget') printf 'MSYS2.MSYS2\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'developer/gcc14\n'
          else
            printf 'gcc\n'
          fi
          ;;
        *) printf 'gcc\n' ;;
      esac
      ;;
    'g++')
      case "${PKG_MGR}" in
        'apk') printf 'g++ musl-dev\n' ;;
        'apt-get') printf 'build-essential\n' ;;
        'winget') printf 'MSYS2.MSYS2\n' ;;
        'brew') printf 'gcc\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'developer/gcc14\n'
          else
            printf 'gcc\n'
          fi
          ;;
        *) printf 'g++\n' ;;
      esac
      ;;
    'make')
      case "${PKG_MGR}" in
        'winget') printf 'GnuWin32.Make\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'developer/build/gnu-make\n'
          else
            printf 'gmake\n'
          fi
          ;;
        *) printf 'make\n' ;;
      esac
      ;;
    'git')
      case "${PKG_MGR}" in
        'winget') printf 'Git.Git\n' ;;
        *) printf 'git\n' ;;
      esac
      ;;
    'curl')
      case "${PKG_MGR}" in
        'winget') printf 'cURL.cURL\n' ;;
        *) printf 'curl\n' ;;
      esac
      ;;
    'sqlite'|'sqlite3')
      case "${PKG_MGR}" in
        'apk'|'dnf'|'yum') printf 'sqlite\n' ;;
        'apt-get'|'zypper'|'pacman') printf 'sqlite3\n' ;;
        'brew') printf 'sqlite\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'database/sqlite-3\n'
          else
            printf 'sqlite3\n'
          fi
          ;;
        *) printf 'sqlite3\n' ;;
      esac
      ;;
    'libicu')
      case "${PKG_MGR}" in
        'apt-get') printf 'libicu-dev\n' ;;
        'apk') printf 'icu-dev\n' ;;
        'dnf'|'yum'|'zypper') printf 'libicu-devel\n' ;;
        'pacman') printf 'icu\n' ;;
        *) printf 'libicu\n' ;;
      esac
      ;;
    'tar')
      case "${PKG_MGR}" in
        'brew') printf 'gnu-tar\n' ;;
        'winget') printf 'GnuWin32.Tar\n' ;;
        'pkg') printf '' ;;
        'apk') printf '' ;;
        *) printf 'tar\n' ;;
      esac
      ;;
    'packer')
      case "${PKG_MGR}" in
        'brew') printf 'packer\n' ;;
        'winget') printf 'Hashicorp.Packer\n' ;;
        'choco') printf 'packer\n' ;;
        'pacman') printf 'packer\n' ;;
        *) printf 'packer\n' ;;
      esac
      ;;
    'vagrant')
      case "${PKG_MGR}" in
        'brew') printf 'vagrant\n' ;;
        'winget') printf 'Hashicorp.Vagrant\n' ;;
        'choco') printf 'vagrant\n' ;;
        'pacman') printf 'vagrant\n' ;;
        *) printf 'vagrant\n' ;;
      esac
      ;;
    'qemu')
      case "${PKG_MGR}" in
        'apk') printf 'qemu-system-aarch64 qemu-system-x86_64 qemu-img\n' ;;
        'apt-get') printf 'qemu-system-x86 qemu-system-arm qemu-utils ovmf qemu-efi-aarch64 libvirt-daemon-system libvirt-clients bridge-utils virtinst swtpm swtpm-tools\n' ;;
        'dnf'|'yum') printf 'qemu-kvm qemu-img edk2-ovmf edk2-aarch64 libvirt virt-install swtpm\n' ;;
        'pacman') printf 'qemu-desktop edk2-ovmf edk2-arm virt-install libvirt swtpm\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'ooce/emulator/qemu ooce/util/qemu-img\n'
          else
            printf 'qemu\n'
          fi
          ;;
        'brew') printf 'qemu\n' ;;
        *) printf 'qemu\n' ;;
      esac
      ;;
    'virtualbox')
      case "${PKG_MGR}" in
        'apt-get') printf 'virtualbox-7.0\n' ;;
        'dnf'|'yum') printf 'VirtualBox-7.0\n' ;;
        'pacman') printf 'virtualbox\n' ;;
        'brew') printf 'virtualbox\n' ;;
        'winget') printf 'Oracle.VirtualBox\n' ;;
        'choco') printf 'virtualbox\n' ;;
        *) printf 'virtualbox\n' ;;
      esac
      ;;
    'wimtools')
      case "${PKG_MGR}" in
        'apt-get') printf 'wimtools\n' ;;
        'dnf'|'yum') printf 'wimlib-utils\n' ;;
        'pacman') printf 'wimlib\n' ;;
        'brew') printf 'wimlib\n' ;;
        *) printf 'wimtools\n' ;;
      esac
      ;;
    'xorriso')
      case "${PKG_MGR}" in
        'apt-get'|'dnf'|'yum'|'pacman'|'brew') printf 'xorriso\n' ;;
        *) printf 'xorriso\n' ;;
      esac
      ;;
    'swtpm')
      case "${PKG_MGR}" in
        'apt-get') printf 'swtpm swtpm-tools\n' ;;
        'dnf'|'yum'|'pacman') printf 'swtpm\n' ;;
        *) printf 'swtpm\n' ;;
      esac
      ;;
    'unzip')
      case "${PKG_MGR}" in
        'winget') printf 'Info-ZIP.UnZip\n' ;;
        *) printf 'unzip\n' ;;
      esac
      ;;
    'csharp')
      case "${PKG_MGR}" in
        'apk') printf 'dotnet8-sdk\n' ;;
        'apt-get') printf 'dotnet-sdk-8.0\n' ;;
        'dnf') printf 'dotnet-sdk-8.0\n' ;;
        'yum') printf 'dotnet-sdk-8.0\n' ;;
        'zypper') printf 'dotnet-sdk\n' ;;
        'pacman') printf 'dotnet-sdk\n' ;;
        'pkg') printf 'dotnet\n' ;;
        'brew') printf 'dotnet\n' ;;
        'winget') printf 'Microsoft.DotNet.SDK.8\n' ;;
        'choco') printf 'dotnet-8.0-sdk\n' ;;
        *) return 1 ;;
      esac
      ;;
    'deno')
      case "${PKG_MGR}" in
        'apk') printf 'deno\n' ;;
        'pacman') printf 'deno\n' ;;
        'brew') printf 'deno\n' ;;
        'pkg') printf 'deno\n' ;;
        'winget') printf 'DenoLand.Deno\n' ;;
        'choco') printf 'deno\n' ;;
        *) return 1 ;;
      esac
      ;;
    'go')
      case "${PKG_MGR}" in
        'apt-get') printf 'golang\n' ;;
        'dnf') printf 'golang\n' ;;
        'yum') printf 'golang\n' ;;
        'swupd') printf 'go-basic\n' ;;
        'winget') printf 'GoLang.Go\n' ;;
        'choco') printf 'golang\n' ;;
        'emerge') printf 'dev-lang/go\n' ;;
        'apt-cyg') printf 'golang\n' ;;
        *) printf 'go\n' ;;
      esac
      ;;
    'java')
      case "${PKG_MGR}" in
        'apk') printf 'openjdk17\n' ;;
        'apt-get') printf 'openjdk-17-jdk\n' ;;
        'dnf') printf 'java-17-openjdk-devel\n' ;;
        'yum') printf 'java-17-openjdk-devel\n' ;;
        'zypper') printf 'java-17-openjdk\n' ;;
        'pacman') printf 'jre-openjdk\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'ooce/runtime/java-17\n'
          else
            printf 'openjdk17\n'
          fi
          ;;
        'brew') printf 'openjdk\n' ;;
        'winget') printf 'Microsoft.OpenJDK.17\n' ;;
        'choco') printf 'openjdk\n' ;;
        'emerge') printf 'virtual/jdk\n' ;;
        'xbps') printf 'openjdk17\n' ;;
        *) printf 'java\n' ;;
      esac
      ;;
    'jq')
      case "${PKG_MGR}" in
        'winget') printf 'jqlang.jq\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'ooce/util/jq\n'
          else
            printf 'jq\n'
          fi
          ;;
        *) printf 'jq\n' ;;
      esac
      ;;
    'kotlin')
      case "${PKG_MGR}" in
        'winget') printf 'JetBrains.Kotlin\n' ;;
        *) printf 'kotlin\n' ;;
      esac
      ;;
    'nimble')
      case "${PKG_MGR}" in
        *) printf 'nim\n' ;;
      esac
      ;;
    'nuget')
      case "${PKG_MGR}" in
        'apk') return 1 ;;
        *) printf 'nuget\n' ;;
      esac
      ;;
    'nodejs')
      case "${PKG_MGR}" in
        'apk') printf 'nodejs npm\n' ;;
        'apt-get') printf 'nodejs npm\n' ;;
        'pacman') printf 'nodejs npm\n' ;;
        'pkg') printf 'node npm\n' ;;
        'winget') printf 'OpenJS.NodeJS\n' ;;
        'emerge') printf 'net-libs/nodejs\n' ;;
        *) printf 'nodejs\n' ;;
      esac
      ;;
    'php')
      case "${PKG_MGR}" in
        'apk') printf 'php84 php84-cli\n' ;;
        'apt-get') printf 'php-cli\n' ;;
        'dnf') printf 'php-cli\n' ;;
        'yum') printf 'php-cli\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'ooce/runtime/php-82\n'
          else
            printf 'php82\n'
          fi
          ;;
        'winget') printf 'PHP.PHP\n' ;;
        'emerge') printf 'dev-lang/php\n' ;;
        *) printf 'php\n' ;;
      esac
      ;;
    'pip')
      case "${PKG_MGR}" in
        "apk") printf "py3-pip
" ;;
        "apt-get") printf "python3-pip
" ;;
        "dnf"|"yum"|"zypper") printf "python3-pip
" ;;
        "pacman") printf "python-pip
" ;;
        "pkg") printf "py312-pip
" ;;
        *) printf "pip
" ;;
      esac ;;

    'python3-venv')
      case "${PKG_MGR}" in
        'apt-get') printf 'python3-venv\n' ;;
        'dnf'|'yum') printf 'python3\n' ;;
        'apk') printf 'python3\n' ;;
        'pacman') printf 'python\n' ;;
        'zypper') printf 'python3\n' ;;
        'pkg') printf '' ;;
        *) printf 'python3-venv\n' ;;
      esac
      ;;

    'r')
      case "${PKG_MGR}" in
        "apk") printf "R R-dev\n" ;;
        "apt-get") printf "r-base r-base-dev\n" ;;
        "dnf"|"yum"|"zypper") printf "R\n" ;;
        "pacman") printf "r\n" ;;
        *) printf "r\n" ;;
      esac ;;

    '7zip')
      case "${PKG_MGR}" in
        "apk") printf "7zip\n" ;;
        "apt-get") printf "p7zip-full\n" ;;
        "dnf"|"yum"|"zypper") printf "p7zip\n" ;;
        "pacman") printf "p7zip\n" ;;
        "pkg")
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf "compress/7zip\n"
          else
            printf "7-zip\n"
          fi
          ;;
        *) printf "7zip\n" ;;
      esac ;;

    'python')
      case "${PKG_MGR}" in
        'apk') printf 'python3 py3-pip\n' ;;
        'apt-get') printf 'python3 python3-pip python3-venv python-is-python3\n' ;;
        'dnf') printf 'python3 python3-pip\n' ;;
        'yum') printf 'python3 python3-pip\n' ;;
        'zypper') printf 'python3 python3-pip\n' ;;
        'pacman') printf 'python python-pip\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'runtime/python-313\n'
          else
            printf 'python3 py312-sqlite3\n'
          fi
          ;;
        'brew') printf 'python3\n' ;;
        'port') printf 'python39\n' ;;
        'winget') printf 'Python.Python.3.11\n' ;;
        'choco') printf 'python3\n' ;;
        'emerge') printf 'dev-lang/python\n' ;;
        'xbps') printf 'python3\n' ;;
        'swupd') printf 'python3-basic\n' ;;
        'apt-cyg') printf 'python3\n' ;;
        *) printf 'python3\n' ;;
      esac
      ;;
    'ruby')
      case "${PKG_MGR}" in
        'apt-get') printf 'ruby-full\n' ;;
        'winget') printf 'RubyInstallerTeam.Ruby\n' ;;
        'emerge') printf 'dev-lang/ruby\n' ;;
        *) printf 'ruby\n' ;;
      esac
      ;;
    'rust')
      case "${PKG_MGR}" in
        'apk') printf 'rust cargo\n' ;;
        'apt-get') printf 'rustc cargo\n' ;;
        'dnf') printf 'rust cargo\n' ;;
        'yum') printf 'rust cargo\n' ;;
        'zypper') printf 'rust cargo\n' ;;
        'winget') printf 'Rustlang.Rustup\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'ooce/developer/rust\n'
          else
            printf 'rust\n'
          fi
          ;;
        'emerge') printf 'dev-lang/rust\n' ;;
        'apt-cyg') printf 'rust\n' ;;
        *) printf 'rust\n' ;;
      esac
      ;;
    'swift')
      case "${PKG_MGR}" in
        'apt-get') printf 'swiftlang\n' ;;
        'dnf') printf 'swift-lang\n' ;;
        'yum') printf 'swift-lang\n' ;;
        'pacman') printf 'swift-language\n' ;;
        'brew') printf 'swift\n' ;;
        'pkg') printf 'swift510\n' ;;
        *) return 1 ;;
      esac
      ;;
    'poetry')
      case "${PKG_MGR}" in
        'pkg') printf 'py312-poetry\n' ;;
        *) printf 'poetry\n' ;;
      esac
      ;;
    'pipx')
      case "${PKG_MGR}" in
        'pkg') printf 'py312-pipx\n' ;;
        *) printf 'pipx\n' ;;
      esac
      ;;
    'stack')
      case "${PKG_MGR}" in
        'pkg') printf 'hs-stack\n' ;;
        *) printf 'stack\n' ;;
      esac
      ;;
    'wait4x')
      case "${PKG_MGR}" in
        'brew') printf 'wait4x\n' ;;
        *) return 1 ;;
      esac
      ;;
    'httpd'|'apache2')
      case "${PKG_MGR}" in
        'winget') printf 'Apache.HTTPD\n' ;;
        'apt-get') printf 'apache2\n' ;;
        'apk') printf 'apache2\n' ;;
        'dnf'|'yum'|'pacman') printf 'httpd\n' ;;
        'brew') printf 'httpd\n' ;;
        'pkg') printf 'apache24\n' ;;
        *) printf 'apache2\n' ;;
      esac
      ;;
    'ansible-galaxy')
      case "${PKG_MGR}" in
        'apk'|'apt-get'|'dnf'|'yum'|'pacman') printf 'ansible\n' ;;
        'pkg') printf 'py312-ansible\n' ;;
        *) printf 'ansible-galaxy\n' ;;
      esac
      ;;
    'apt')
      case "${PKG_MGR}" in
        *) printf 'apt\n' ;;
      esac
      ;;
    'awscli'|'aws')
      case "${PKG_MGR}" in
        'apk') printf 'aws-cli\n' ;;
        'pkg') printf 'py312-awscli\n' ;;
        *) printf 'awscli\n' ;;
      esac
      ;;
    'azure-cli')
      case "${PKG_MGR}" in
        'apt-get'|'dnf'|'yum'|'zypper') printf 'azure-cli\n' ;;
        'apk'|'pacman') return 1 ;;
        'pkg') printf 'py312-azure-cli\n' ;;
        *) printf 'azure-cli\n' ;;
      esac
      ;;
    'build-essential')
      case "${PKG_MGR}" in
        'apt-get') printf 'build-essential\n' ;;
        'dnf'|'yum') printf '@development-tools\n' ;;
        'zypper') printf '%s\n' '-t pattern devel_basis' ;;
        'pacman') printf 'base-devel\n' ;;
        'apk') printf 'build-base\n' ;;
        *) printf 'build-essential\n' ;;
      esac
      ;;
    'bun-pm')
      case "${PKG_MGR}" in
        'apk') printf 'bun\n' ;;
        *) printf 'bun\n' ;;
      esac
      ;;
    'bundler')
      case "${PKG_MGR}" in
        'pkg') printf 'rubygem-bundler\n' ;;
        'apk') printf 'ruby-bundler\n' ;;
        *) printf 'bundler\n' ;;
      esac
      ;;
    'cabal')
      case "${PKG_MGR}" in
        'pkg') printf 'hs-cabal-install\n' ;;
        'apt-get') printf 'cabal-install\n' ;;
        *) printf 'cabal\n' ;;
      esac
      ;;
    'cargo')
      case "${PKG_MGR}" in
        'apk') printf 'cargo\n' ;;
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'ooce/developer/rust\n'
          else
            printf 'rust\n'
          fi
          ;;
        *) printf 'cargo\n' ;;
      esac
      ;;
    'composer')
      case "${PKG_MGR}" in
        'apk') printf 'composer\n' ;;
        'pkg') printf 'php84-composer\n' ;;
        *) printf 'composer\n' ;;
      esac
      ;;
    'cpanm')
      case "${PKG_MGR}" in
        'apk') printf 'perl-app-cpanminus\n' ;;
        'pkg') printf 'p5-App-cpanminus\n' ;;
        *) printf 'cpanminus\n' ;;
      esac
      ;;
    'docker')
      case "${PKG_MGR}" in
        'apk') printf 'docker docker-cli\n' ;;
        'apt-get') printf 'docker.io docker-compose\n' ;;
        'dnf'|'yum')
          if command -v dnf >/dev/null 2>&1 && dnf info docker-ce >/dev/null 2>&1; then
            printf 'docker-ce docker-ce-cli containerd.io\n'
          else
            printf 'podman-docker\n'
          fi
          ;;
        'winget') printf 'Docker.DockerCli\n' ;;
        'brew') printf 'docker\n' ;;
        *) printf 'docker\n' ;;
      esac
      ;;
    'fluentbit')
      case "${PKG_MGR}" in
        'apk') printf 'fluent-bit\n' ;;
        *) printf 'fluent-bit\n' ;;
      esac
      ;;
    'tensorboard')
      case "${PKG_MGR}" in
        *) return 1 ;;
      esac
      ;;
    'deno-pm')
      case "${PKG_MGR}" in
        'apk') printf 'deno\n' ;;
        *) printf 'deno\n' ;;
      esac
      ;;
    'caddy')
      case "${PKG_MGR}" in
        'winget') printf 'caddy.caddy\n' ;;
        'brew') printf 'caddy\n' ;;
        'apt-get') printf 'debian-keyring debian-archive-keyring apt-transport-https caddy\n' ;;
        *) printf 'caddy\n' ;;
      esac
      ;;
    'nats')
      case "${PKG_MGR}" in
        'apk') printf 'nats-server\n' ;;
        'brew') printf 'nats-server\n' ;;
        'winget') printf 'NATS.nats-server\n' ;;
        *) printf 'nats-server\n' ;;
      esac
      ;;
    'nginx')
      case "${PKG_MGR}" in
        'winget') printf 'Nginx.Nginx\n' ;;
        'emerge') printf 'www-servers/nginx\n' ;;
        *) printf 'nginx\n' ;;
      esac
      ;;
    'openbao'|'bao')
      case "${PKG_MGR}" in
        'apt-get'|'apk'|'dnf'|'yum'|'zypper'|'pacman') return 1 ;;
        *) printf 'openbao\n' ;;
      esac
      ;;
    'etcd')
      case "${PKG_MGR}" in
        'apt-get') printf 'etcd-server etcd-client\n' ;;
        'pkg') printf 'coreos-etcd35\n' ;;
        'winget') printf 'etcd.etcd\n' ;;
        'emerge') printf 'dev-db/etcd\n' ;;
        *) printf 'etcd\n' ;;
      esac
      ;;
    'duckdb')
      case "${PKG_MGR}" in
        'apk') printf 'libstdc++\n' ;;
        *) printf 'duckdb\n' ;;
      esac
      ;;
    'elixir')
      case "${PKG_MGR}" in
        'pkg')
          if [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
            printf 'ooce/runtime/elixir\n'
          else
            printf 'elixir erlang\n'
          fi
          ;;
        *) printf 'elixir\n' ;;
      esac
      ;;
    'rabbitmq')
      case "${PKG_MGR}" in
        'apk') printf 'rabbitmq-server\n' ;;
        'apt-get') printf 'rabbitmq-server\n' ;;
        'dnf') printf 'rabbitmq-server\n' ;;
        'yum') printf 'rabbitmq-server\n' ;;
        'zypper') printf 'rabbitmq-server\n' ;;
        'brew') printf 'rabbitmq\n' ;;
        'winget') printf 'RabbitMQ.RabbitMQ\n' ;;
        'emerge') printf 'net-misc/rabbitmq-server\n' ;;
        *) printf 'rabbitmq-server\n' ;;
      esac
      ;;
    'gem')
      case "${PKG_MGR}" in
        'apk') printf 'ruby\n' ;;
        'apt-get') printf 'ruby\n' ;;
        'dnf'|'yum'|'zypper'|'pacman') printf 'rubygems\n' ;;
        'brew') printf 'ruby\n' ;;
        *) return 1 ;;
      esac
      ;;
    'ghcup'|'go-pm'|'google-cloud-sdk')
      case "${PKG_MGR}" in
        'brew') printf '%s\n' "${pkg}" ;;
        *) return 1 ;;
      esac
      ;;
    'guix')
      case "${PKG_MGR}" in
        'apk') printf 'guix\n' ;;
        *) return 1 ;;
      esac
      ;;
    'hatch'|'krew')
      case "${PKG_MGR}" in
        'brew') printf '%s\n' "${pkg}" ;;
        *) return 1 ;;
      esac
      ;;
    'helm'|'julia'|'luarocks')
      case "${PKG_MGR}" in
        'brew') printf '%s\n' "${pkg}" ;;
        'apk') 
           if [ "${pkg}" = "helm" ] || [ "${pkg}" = "luarocks" ]; then
             printf '%s\n' "${pkg}"
           else
             return 1
           fi
           ;;
        *) return 1 ;;
      esac
      ;;
    'valkey')
      case "${PKG_MGR}" in
        'winget') return 1 ;;
        'choco') return 1 ;;
        'apt-cyg') return 1 ;;
        *) printf 'valkey\n' ;;
      esac
      ;;
    'memcached')
      case "${PKG_MGR}" in
        'emerge') printf 'net-misc/memcached\n' ;;
        'winget') return 1 ;;
        'apt-cyg') return 1 ;;
        'choco') printf 'memcached\n' ;;
        *) printf 'memcached\n' ;;
      esac
      ;;
    'flatpak')
      case "${PKG_MGR}" in
        *) printf 'flatpak\n' ;;
      esac
      ;;
    'dnf')
      case "${PKG_MGR}" in
        'apk'|'apt-get'|'pacman') return 1 ;;
        *) printf 'dnf\n' ;;
      esac
      ;;
    'pacman')
      case "${PKG_MGR}" in
        'apt-get') printf 'pacman-package-manager\n' ;;
        'apk') return 1 ;;
        *) printf 'pacman\n' ;;
      esac
      ;;
    'emerge')
      case "${PKG_MGR}" in
        'apk'|'apt-get'|'dnf'|'yum'|'pacman'|'zypper') return 1 ;;
        *) printf 'emerge\n' ;;
      esac
      ;;
    'eopkg')
      case "${PKG_MGR}" in
        'apk'|'apt-get'|'dnf'|'yum'|'pacman'|'zypper') return 1 ;;
        *) printf 'eopkg\n' ;;
      esac
      ;;
    'xz')
      case "${PKG_MGR}" in
        'apt-get') printf 'xz-utils\n' ;;
        *) printf 'xz\n' ;;
      esac
      ;;
    'fnm')
      case "${PKG_MGR}" in
        *) return 1 ;;
      esac
      ;;

    *)
      printf '%s\n' "${pkg}"
      ;;
  esac
}
