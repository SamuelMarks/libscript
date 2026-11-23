# Hermetic Container Builders & Base Dockerfiles (`docker/`)

## Overview

`docker/` contains base Alpine and Debian container definitions, non-interactive environment presets
(`conf_no_all.env.{sh,cmd,ps1}`), and Dockerfile templates (`Dockerfile.tpl`,
`Dockerfile.no_body.tpl`) used by `T3` `synthesis/formats/docker.{sh,cmd}`
(`./libscript.sh package-as docker`) and isolated CI component test runners.

## Files

- **`base.alpine.Dockerfile` & `base.debian.Dockerfile`**: Minimal POSIX `/bin/sh` container test
  environments for Alpine musl and Debian glibc verification.
- **`postgres.debian.Dockerfile`**: Reference stateful service container image definition.
- **`Dockerfile.tpl` & `Dockerfile.no_body.tpl`**: Templates rendered during `package-as docker`.
- **`create_docker_builder.{sh,cmd}`**: Configures multi-arch `docker buildx` builder instances.
- **`conf_no_all.env.{sh,cmd,ps1}`**: Disables optional auxiliary daemons during minimal container
  builds.
