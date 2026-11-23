# SSH Test Target Container Images (`dockerfiles-ssh/`)

## Overview

`dockerfiles-ssh/` provides lightweight OpenSSH-enabled Alpine (`ssh.alpine.Dockerfile`) and Debian
(`ssh.debian.Dockerfile`) container targets used to test agentless remote deployments
(`workloads/services/deploy-remote.{sh,cmd}`), `Plane A` remote trait execution, and `T4`/`T5`
multi-node SSH choreography locally without cloud VMs.

## Usage

```sh
docker build -f dockerfiles-ssh/ssh.debian.Dockerfile -t libscript-ssh-debian dockerfiles-ssh/
docker build -f dockerfiles-ssh/ssh.alpine.Dockerfile -t libscript-ssh-alpine dockerfiles-ssh/
```
