Why
===

## Overhead

Overhead of Docker is extreme, in terms of:

  - Disk usage
  - Build time
  - Other resource usage overhead vs native (CPU, GPU, disk, kernel)

## Alternatives to Docker

There are many alternatives to Docker.
These are rarely benchmarked, security-audited, or otherwise compared with Docker based solutions.

Some alternatives follow.

### Docker directly comparable

These can work directly with `Dockerfile`s:

  - [Podman](https://podman.io)
  - [nerdctl](https://github.com/containerd/nerdctl)

### Linux specific

  - [cgroups](https://en.wikipedia.org/wiki/Cgroups)
  - [namespaces](https://en.wikipedia.org/wiki/Linux_namespaces)
  - [OCI](https://en.wikipedia.org/wiki/Open_Container_Initiative) (at least until [FreeBSD support is merged](https://github.com/opencontainers/wg-freebsd-runtime)! - Windows Containers not sure how this fits into OCI…)

### Other

  - [Zones (SunOS)](https://en.wikipedia.org/wiki/Solaris_Containers)
  - [Jails (*BSD)](https://en.wikipedia.org/wiki/FreeBSD_jail)
  - [Windows Containers](https://learn.microsoft.com/en-us/virtualization/windowscontainers/about/)
  - Platform virtualization software: https://en.wikipedia.org/wiki/Comparison_of_platform_virtualization_software
  - OS-level virtualization software: https://en.wikipedia.org/wiki/OS-level_virtualization#IMPLEMENTATIONS
  - μ-kernel: https://en.wikipedia.org/wiki/Microkernel
  - Unikernel: https://en.wikipedia.org/wiki/Unikernel
  - Any other kernel: https://en.wikipedia.org/wiki/Comparison_of_operating_system_kernels

## Slogans

  - Mutable dev; immutable prod.
  - Develop quickly. Production? - Produce images.
  - PaaS. Native.
  - PaaS. Native. Actually.
  - Cross-platform. Actually.
  - Docker should be optional.
  - Docker is terrible; stop using it. Also: we make your Docker images better.
  - Python scripts? - No: Python packages. - Bash scripts? - No: `*.sh` & `*.bat` packages.
  - Make shell scripting software-engineering
  - Shell scripting? - No: shell software-engineering.
