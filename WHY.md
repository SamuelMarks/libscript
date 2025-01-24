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

  - Podman
  - nerdctl

### Linux specific

  - cgroups
  - namespaces
  - OCI (at least until FreeBSD support is merged! - Windows Containers not sure how this fits into OCI…)

### Other

  - Zones (SunOS)
  - Jails (*BSD)
  - Windows Containers
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
