# Configuration & Zero-Env-Leak Secrets Trait (`traits/secrets/`)

## Overview

`traits/secrets/` renders configuration templates by delegating directly to
`_lib/_common/envsubst_safe.{sh,cmd}` and `_lib/_common/find_replace.{sh,cmd}` while enforcing a
strict **Zero-Environment-Variable-Leakage Guarantee**.

## Why Exporting Secrets to Environment Variables is Forbidden

Exporting plaintext credentials into child process environments (`export DB_PASSWORD=...`) exposes
those secrets inside `/proc/<pid>/environ`, `ps eww`, and crash dumps to co-tenant processes or
monitoring agents. Instead, `traits/secrets/exec_with_secrets.{sh,cmd}` creates a `0700` RAM-backed
directory (`/dev/shm` or `tmpfs`) or `0600` FIFO (`mkfifo`) on POSIX—or an ACL-restricted temporary
file (`icacls /inheritance:r`) on Windows—streams decrypted key-value pairs into the target hook or
`envsubst_safe` via file descriptor, and unlinks the secret file in an `EXIT INT TERM` trap.
