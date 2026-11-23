# Self-Hosted Git Forges & VCS Utilities (`_lib/git-servers/`)

## Overview

**Tier Scope**: `T1`

Self-hosted Git collaboration servers (`gitea`, `forgejo`, `gitlab`, `cgit`) and shared Git
provisioning utilities (`utils`).

Each subdirectory in `_lib/git-servers/` is an atomic, self-contained LibScript component governed
by its own `manifest.json` and `vars.schema.json`. Components in `_lib/git-servers/` never
cross-source sibling components directly; instead, they source `T0` helpers from `engine/common/`
and are composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and
`Plane A` (`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh cgit --help
./libscript.sh install cgit latest
./_lib/git-servers/cgit/cli.sh test
```

```cmd
.\libscript.cmd cgit --help
.\libscript.cmd install cgit latest
.\_lib\git-servers\cgit\cli.cmd test
```

## Components (5)

<!-- BEGIN_COMPONENTS -->

- [`cgit`](./cgit/README.md) (`T1` — `userland-package`, `service-daemon`): Hyperfast C CGI web
  frontend for Git repositories with built-in caching.
- [`forgejo`](./forgejo/README.md) (`T1` — `userland-package`, `service-daemon`): Self-hosted
  lightweight community-governed software forge supporting Git, CI/CD Actions, and packages.
- [`gitea`](./gitea/README.md) (`T1` — `userland-package`, `service-daemon`): LibScript component
  for GITEA
- [`gitlab`](./gitlab/README.md) (`T1` — `userland-package`, `service-daemon`): LibScript component
  for GITLAB
- [`utils`](./utils/README.md) (`T1` — `userland-package`, `service-daemon`): Shared functions and
  utilities for Git Server components (Gitea, GitLab).

<!-- END_COMPONENTS -->
