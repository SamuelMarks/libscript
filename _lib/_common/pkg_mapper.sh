#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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
# ## Overview
# This module translates generic package names (e.g., 'php', 'postgres') into 
# specific package IDs used by different OS package managers (apt, yum, pacman, etc.).
#
# ## Usage
# Call the `map_package` function with the generic package name. The package manager
# will be determined from the `PKG_MGR` environment variable.

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
        'pkg') printf 'postgresql14-server postgresql14-client\n' ;;
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
    'default-libmysqlclient-dev')
      case "${PKG_MGR}" in
        'brew') printf 'mysql-client\n' ;;
        *) printf 'default-libmysqlclient-dev\n' ;;
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
        'pkg') printf 'gcc\n' ;;
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
        'pkg') printf 'gcc\n' ;;
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
        *) printf 'gcc\n' ;;
      esac
      ;;
    'g++')
      case "${PKG_MGR}" in
        'apk') printf 'g++ musl-dev\n' ;;
        'apt-get') printf 'build-essential\n' ;;
        'winget') printf 'MSYS2.MSYS2\n' ;;
        'brew') printf 'gcc\n' ;;
        *) printf 'g++\n' ;;
      esac
      ;;
    'make')
      case "${PKG_MGR}" in
        'winget') printf 'GnuWin32.Make\n' ;;
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
        'apk') printf 'sqlite\n' ;;
        'apt-get'|'dnf'|'yum'|'zypper'|'pacman') printf 'sqlite3\n' ;;
        'brew') printf 'sqlite\n' ;;
        *) printf 'sqlite3\n' ;;
      esac
      ;;
    'tar')
      case "${PKG_MGR}" in
        'brew') printf 'gnu-tar\n' ;;
        'winget') printf 'GnuWin32.Tar\n' ;;
        *) printf 'tar\n' ;;
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
        'pkg') printf 'dotnet-sdk\n' ;;
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
        'apt-get') printf 'default-jdk\n' ;;
        'dnf') printf 'java-17-openjdk-devel\n' ;;
        'yum') printf 'java-17-openjdk-devel\n' ;;
        'zypper') printf 'java-17-openjdk\n' ;;
        'pacman') printf 'jre-openjdk\n' ;;
        'pkg') printf 'openjdk17\n' ;;
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
        *) printf 'jq\n' ;;
      esac
      ;;
    'kotlin')
      case "${PKG_MGR}" in
        'winget') printf 'JetBrains.Kotlin\n' ;;
        *) printf 'kotlin\n' ;;
      esac
      ;;
    'nodejs')
      case "${PKG_MGR}" in
        'apk') printf 'nodejs npm\n' ;;
        'apt-get') printf 'nodejs npm\n' ;;
        'pacman') printf 'nodejs npm\n' ;;
        'winget') printf 'OpenJS.NodeJS\n' ;;
        'emerge') printf 'net-libs/nodejs\n' ;;
        *) printf 'nodejs\n' ;;
      esac
      ;;
    'php')
      case "${PKG_MGR}" in
        'apk') printf 'php82 php82-cli\n' ;;
        'apt-get') printf 'php-cli\n' ;;
        'dnf') printf 'php-cli\n' ;;
        'yum') printf 'php-cli\n' ;;
        'pkg') printf 'php82\n' ;;
        'winget') printf 'PHP.PHP\n' ;;
        'emerge') printf 'dev-lang/php\n' ;;
        *) printf 'php\n' ;;
      esac
      ;;
    'pip')
      case "${PKG_MGR}" in
        "apk") printf "py3-pip\n" ;;
        "apt-get") printf "python3-pip\n" ;;
        "dnf"|"yum"|"zypper") printf "python3-pip\n" ;;
        "pacman") printf "python-pip\n" ;;
        *) printf "pip\n" ;;
      esac ;;

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
        'pkg') printf 'python3\n' ;;
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
        *) return 1 ;;
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
        *) printf 'apache2\n' ;;
      esac
      ;;
    'ansible-galaxy')
      case "${PKG_MGR}" in
        'apk'|'apt-get'|'dnf'|'yum'|'pacman') printf 'ansible\n' ;;
        *) printf 'ansible-galaxy\n' ;;
      esac
      ;;
    'apt')
      case "${PKG_MGR}" in
        *) printf 'apt\n' ;;
      esac
      ;;
    'awscli')
      case "${PKG_MGR}" in
        'apk') printf 'aws-cli\n' ;;
        *) printf 'awscli\n' ;;
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
        'apk') printf 'ruby-bundler\n' ;;
        *) printf 'bundler\n' ;;
      esac
      ;;
    'cabal')
      case "${PKG_MGR}" in
        'apk') printf 'cabal\n' ;;
        *) printf 'cabal\n' ;;
      esac
      ;;
    'cargo')
      case "${PKG_MGR}" in
        'apk') printf 'cargo\n' ;;
        *) printf 'cargo\n' ;;
      esac
      ;;
    'composer')
      case "${PKG_MGR}" in
        'apk') printf 'composer\n' ;;
        *) printf 'composer\n' ;;
      esac
      ;;
    'cpanm')
      case "${PKG_MGR}" in
        'apk') printf 'perl-app-cpanminus\n' ;;
        *) printf 'cpanminus\n' ;;
      esac
      ;;
    'docker')
      case "${PKG_MGR}" in
        'apk') printf 'docker docker-cli\n' ;;
        'apt-get') printf 'docker.io docker-buildx-plugin docker-compose-plugin\n' ;;
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
