Dependencies
============

Basic POSIX utilities. They're usually included; unless you're on Windows. Also: `curl`, `jq`, and `envsubst`.
Optionally `sqlite3` for a config store; regardless `dyn_env.sh` and `dyn_env.cmd` are generated for everything dynamically set by the system.

Specifically these from POSIX are used:

  - `.` (for `source`ing)
  - `/bin/sh`
  - `awk` (no GNU extensions)
  - `cat`
  - `command`
  - `cp` and `cp -r`
  - `cut`
  - `dc`
  - `dd`
  - `dirname`
  - `echo`
  - `env`
  - `expr`
  - `grep` [no GNU extensions used]
  - `head`
  - `mkdir` & `mkdir -p`
  - `mktemp`
  - `printf`
  - `pwd`
  - `read`
  - `rm`
  - `sed` [no GNU extensions used]
  - `set`
  - `tee`
  - `test` and shorthand: `[` `]`
  - `touch`
  - `tr`
  - `true`
  - `uname`
  - `yes`

  - POSIX standard char ranges (`[:upper:]`; `[:lower:]`; `[:space:]`; `[:alpha:]`; `[:alnum:]`)
  - Keywords: `if`, `then`, `else`, `fi`, `for`, `while`, `do`, `done`, `case`, `in`, `esac`, `wait`, `export`, `exit`, `return`
  - Operators: `!`, `&&`, `&`, `||`, `>`, `<`, `>>`, `=`, `;`, `(`, `)`, `{`, `}`, `${`, `}`
  - Expansions: `${VAR:-default}` for default; `%` for substr
  - Heredoc: `<<EOF`, `EOF`
  - Quotes: `'`, `"`

With `jq` and the aforementioned `curl` & `envsubst` acquired if not found in system `PATH`. And:

  - `/bin/bash` on macOS [to acquire `brew`]
  - `docker`, only if using Docker, for `docker_builder.sh` and `docker_builder_parallel.sh` (or manually for any `*Dockerfile`)
  - `lsb_release` on Linux
  - `readlink`
  - `sw_vers` on macOS
