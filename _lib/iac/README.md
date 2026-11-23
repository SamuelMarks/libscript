# Infrastructure-as-Code & Provisioning CLI Tools (`_lib/iac/`)

## Overview

**Tier Scope**: `T1`

Declarative infrastructure, configuration, and VM image automation tools (`terraform`, `tofu`,
`pulumi`, `ansible`, `packer`, `vagrant`).

Each subdirectory in `_lib/iac/` is an atomic, self-contained LibScript component governed by its
own `manifest.json` and `vars.schema.json`. Components in `_lib/iac/` never cross-source sibling
components directly; instead, they source `T0` helpers from `engine/common/` and are composed upward
by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and `Plane A` (`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh ansible --help
./libscript.sh install ansible latest
./_lib/iac/ansible/cli.sh test
```

```cmd
.\libscript.cmd ansible --help
.\libscript.cmd install ansible latest
.\_lib\iac\ansible\cli.cmd test
```

## Components (6)

<!-- BEGIN_COMPONENTS -->

- [`ansible`](./ansible/README.md) (`T1` — `userland-package`): Agentless IT automation,
  configuration management, and application deployment engine (ansible, ansible-playbook,
  ansible-vault).
- [`packer`](./packer/README.md) (`T1` — `userland-package`): HashiCorp Packer multi-platform
  automated machine image builder.
- [`pulumi`](./pulumi/README.md) (`T1` — `userland-package`): Pulumi open-source
  Infrastructure-as-Code SDK and CLI supporting TypeScript, Python, Go, C#, Java, and YAML.
- [`terraform`](./terraform/README.md) (`T1` — `userland-package`): HashiCorp Terraform declarative
  Infrastructure-as-Code CLI for provisioning and managing cloud and on-prem resources.
- [`tofu`](./tofu/README.md) (`T1` — `userland-package`): OpenTofu (tofu) Linux Foundation
  open-source Infrastructure-as-Code CLI drop-in replacement for Terraform.
- [`vagrant`](./vagrant/README.md) (`T1` — `userland-package`): HashiCorp Vagrant development
  environment and virtual machine manager.

<!-- END_COMPONENTS -->
