Dependencies
============

Basic POSIX utilities, `curl`, and `jq`. They're usually included; unless you're on Windows.

Specifically these are used:

  - `.` (for `source`ing)
  - `/bin/sh`
  - `cat`
  - `command`
  - `cp` and `cp -r`
  - `dc`
  - `dirname`
  - `echo`
  - `env`
  - `envsubst`
  - `expr`
  - `grep` [no GNU extensions used]
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
  - `uname`

  - POSIX standard char ranges (`[:upper:]`; `[:lower:]`; `[:space:]`; `[:alpha:]`; `[:alnum:]`)
  - Keywords: `if`, `then`, `else`, `fi`, `for`, `while`, `do`, `done`, `case`, `in`, `esac`, `wait`, `export`, `exit`, `return`
  - Operators: `!`, `&&`, `&`, `||`, `>`, `<`, `>>`, `=`, `;`, `(`, `)`, `{`, `}`, `${`, `}`
  - Expansions: `${VAR:-default}` for default; `%` for substr
  - Heredoc: `<<EOF`, `EOF`
  - Quotes: `'`, `"`

With the aforementioned `curl` and `jq` acquired if not found in system `PATH`. And:

  - `/bin/bash` on macOS [to acquire `brew`]
  - `docker`, only if using Docker, for `docker_builder.sh` and `docker_builder_parallel.sh` (or manually for any `*Dockerfile`)
  - `lsb_release` on Linux
  - `readlink`
  - `sw_vers` on macOS
