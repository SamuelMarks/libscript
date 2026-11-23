# Plane A Zero-Leak Secret Injection Trait (`traits/secrets/`)

## Overview

`traits/secrets/` delivers credentials, TLS private keys, and API tokens to `T1`/`T5` services
**without** leaking secrets into process environment blocks (`/proc/<pid>/environ`), shell command
arguments, or unencrypted disk layers.

## Scripts

- **`openbao.{sh,cmd}`**: Fetches dynamic and KVv2 secrets from `_lib/security/openbao` or HashiCorp
  Vault using AppRole, Kubernetes, or token authentication.
- **`sops.{sh,cmd}`**: Decrypts age/KMS-encrypted SOPS manifests strictly in memory.
- **`env_file.{sh,cmd}`**: Manages `0600` owner-restricted secret files on `tmpfs` / `ramfs` or
  ACL-locked Windows directories.
- **`render.{sh,cmd}`**: Renders secret placeholders into protected configuration files without
  shell `eval`.
- **`exec_with_secrets.{sh,cmd}`**: Streams decrypted secrets over ephemeral `0600` FIFOs or file
  descriptors directly to target daemons.

## Usage

```sh
./libscript.sh trait apply secrets
./traits/secrets/exec_with_secrets.sh --source openbao -- ./my-daemon
```
