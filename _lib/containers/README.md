# Container Runtimes & Image Builders (`_lib/containers/`)

## Overview

**Tier Scope**: `T1`

OCI container engines, daemonless image builders, and system container managers (`docker`, `podman`,
`containerd`, `cri-o`, `buildah`, `skopeo`, `lxc`, `lxd`).

Each subdirectory in `_lib/containers/` is an atomic, self-contained LibScript component governed by
its own `manifest.json` and `vars.schema.json`. Components in `_lib/containers/` never cross-source
sibling components directly; instead, they source `T0` helpers from `engine/common/` and are
composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and `Plane A`
(`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh buildah --help
./libscript.sh install buildah latest
./_lib/containers/buildah/cli.sh test
```

```cmd
.\libscript.cmd buildah --help
.\libscript.cmd install buildah latest
.\_lib\containers\buildah\cli.cmd test
```

## Components (8)

<!-- BEGIN_COMPONENTS -->

- [`buildah`](./buildah/README.md) (`T1` — `userland-package`): Daemonless tool for building Open
  Container Initiative (OCI) and Docker container images.
- [`containerd`](./containerd/README.md) (`T1` — `userland-package`): Industry-standard CNCF
  graduated core container runtime daemon (containerd, ctr, containerd-shim-runc-v2).
- [`cri-o`](./cri-o/README.md) (`T1` — `userland-package`): Lightweight OCI-based implementation of
  the Kubernetes Container Runtime Interface (crio).
- [`docker`](./docker/README.md) (`T1` — `userland-package`): A platform for developing, shipping,
  and running containerized applications.
- [`lxc`](./lxc/README.md) (`T1` — `userland-package`): Low-level Linux Containers userspace tools
  and library (lxc-create, lxc-start, lxc-ls, lxc-attach) over kernel namespaces and cgroups.
- [`lxd`](./lxd/README.md) (`T1` — `userland-package`, `service-daemon`): Canonical LXD
  next-generation system container and virtual machine manager daemon (lxd) and REST CLI client
  (lxc).
- [`podman`](./podman/README.md) (`T1` — `userland-package`): Daemonless, rootless OCI container and
  pod management engine (podman) compatible with Docker CLI workflows.
- [`skopeo`](./skopeo/README.md) (`T1` — `userland-package`): Daemonless utility (skopeo) for
  inspecting, copying, signing, and synchronizing container images and registries.

<!-- END_COMPONENTS -->
