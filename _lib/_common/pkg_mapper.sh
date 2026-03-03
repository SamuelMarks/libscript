#!/bin/sh

map_package() {
  pkg="${1}"
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
    'c_compiler')
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
    'cpp_compiler')
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
    'python')
      case "${PKG_MGR}" in
        'apk') printf 'python3 py3-pip\n' ;;
        'apt-get') printf 'python3 python3-pip python3-venv\n' ;;
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
        'brew') printf 'wait4x/wait4x/wait4x\n' ;;
        *) return 1 ;;
      esac
      ;;
    'nginx')
      case "${PKG_MGR}" in
        'winget') printf 'Nginx.Nginx\n' ;;
        'emerge') printf 'www-servers/nginx\n' ;;
        *) printf 'nginx\n' ;;
      esac
      ;;
    'etcd')
      case "${PKG_MGR}" in
        'winget') printf 'etcd.etcd\n' ;;
        'emerge') printf 'dev-db/etcd\n' ;;
        *) printf 'etcd\n' ;;
      esac
      ;;
    'rabbitmq')
      case "${PKG_MGR}" in
        'apk') printf 'rabbitmq-server\n' ;;
        'apt-get') printf 'rabbitmq-server\n' ;;
        'dnf') printf 'rabbitmq-server\n' ;;
        'yum') printf 'rabbitmq-server\n' ;;
        'zypper') printf 'rabbitmq-server\n' ;;
        'winget') printf 'RabbitMQ.RabbitMQ\n' ;;
        'emerge') printf 'net-misc/rabbitmq-server\n' ;;
        *) printf 'rabbitmq-server\n' ;;
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
    'postgresql')
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
        'emerge') printf 'dev-db/postgresql\n' ;;
        *) printf 'postgresql\n' ;;
      esac
      ;;
    *)
      printf '%s\n' "${pkg}"
      ;;
  esac
}
