# Tiers 1 & 2 (`T1` / `T2`): Atomic Component Catalog (`_lib/`)

## Overview

`_lib/` is LibScript's catalog of **498+ self-contained, atomic software recipes** organized across
31 functional categories, accompanied by `_lib/checksums.txt` for offline cryptographic artifact
verification.

Every directory `_lib/<category>/<component>/` is an autonomous component-package-manager governed
by [`../engine/schemas/manifest.schema.json`](../engine/schemas/manifest.schema.json) and its own
`vars.schema.json`:

- **Tier 1 (`T1`) — Userland Packages, Toolchains & Service Daemons**:
  - Developer languages, compilers, build systems, CLI utilities, databases, caches, search engines,
    message brokers, and web/application servers.
  - Installs side-by-side into `${LIBSCRIPT_HOME}/<component>/<version>` with `O(1)` active binary
    symlinks/shims in `${LIBSCRIPT_HOME}/bin`.
  - Components declaring `"service-daemon"` in `manifest.json` ship `service.{sh,cmd}` for native
    supervision across `systemd`, `openrc`, `runit`, `s6`, `dinit`, `launchd`, `smf`, and Windows
    Services.
- **Tier 2 (`T2`) — OS Kernels, Bootloaders, Init Systems & Sysroot Plumbing**:
  - Kernels (`linux`, `initramfs`, `freedos`, `msdos`, `zephyr`, `freertos`), bootloaders (`grub`,
    `systemd-boot`, `limine`, `refind`, `mcuboot`), C standard libraries (`glibc`, `musl`),
    Wayland/DRM/Mesa graphics plumbing, and PID 1 init systems.
  - Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`, and `LIBSCRIPT_TARGET_TRIPLET` when
    invoked by `T3` OS synthesizers (`synthesis/`).

## Architectural Purity Invariants

Enforced statically on every commit by `devtools/audit/audit_tiers.{sh,cmd}` and
`devtools/audit/audit_standards.{sh,cmd}`:

1. **Zero Lateral Cross-Sourcing**: No script inside `_lib/<catA>/<compA>/` may directly source
   `_lib/<catB>/<compB>/`. Multi-service composition happens strictly above `_lib/` via `T0`
   `engine/hooks/`, `T3` `synthesis/`, `T5` `workloads/`, or `Plane A` `traits/`.
2. **Downward-Only `T0` Imports**: `_lib/` recipes source shared helpers exclusively from
   `engine/common/` and `engine/target/`.
3. **Capability-Typed Entry Points**: Only components declaring `"service-daemon"` in
   `manifest.json` include `service.{sh,cmd}`; pure libraries and CLI tools never ship dead daemon
   stubs.

## Installation Strategies (`<COMPONENT>_INSTALL_METHOD`)

Components evaluate `<COMPONENT>_INSTALL_METHOD` -> `LIBSCRIPT_DEFAULT_INSTALL_METHOD` ->
`libscript_native`:

- **`libscript_native`** _(default)_: Downloads checksum-verified upstream archives into isolated
  `${LIBSCRIPT_HOME}/<component>/<version>` directories without requiring root privileges or
  polluting `/usr`.
- **`from-source` / `source`**: Compiles from verified upstream tarballs via
  `engine/common/source_builder.{sh,cmd}`
  (`--from-source --toolchain=default|gcc|clang|tcc|edgcpp|custom-cc`).
- **`system`**: Delegates to the host or explicitly requested OS/ecosystem package manager
  (`--pkg-mgr=apt-get|apk|dnf|brew|winget|choco|scoop|nix|spack|vcpkg|rapps`).

## Usage

```sh
# Discover and inspect atomic components
./libscript.sh list
./libscript.sh search postgres

# Native version management (T1)
./libscript.sh ls-remote nodejs
./libscript.sh install nodejs 22.14.0
./libscript.sh use nodejs 22.14.0
./libscript.sh which nodejs

# Service daemon lifecycle (components with "service-daemon" capability)
./libscript.sh install postgres 17
./libscript.sh start postgres
./libscript.sh status postgres
./libscript.sh stop postgres
```

```cmd
.\libscript.cmd ls-remote nodejs
.\libscript.cmd install nodejs 22.14.0
.\libscript.cmd use nodejs 22.14.0
.\libscript.cmd install postgres 17
.\libscript.cmd start postgres
```

## Category Index

| Category                                            | Tier      | Components | Scope                                                                                                                                                                                                                                                                                                                                                                      |
| :-------------------------------------------------- | :-------- | :--------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`app-servers/`](./app-servers/README.md)           | `T1`      |     21     | Application & Inference Servers — Language application workers (WSGI/ASGI, PHP-FPM, Puma, Passenger, PM2, JEE servlet containers) and high-throughput LLM/ML inference servers (`vLLM`, `JetStream`, `Triton`, `Ollama`).                                                                                                                                                  |
| [`audio/`](./audio/README.md)                       | `T1 / T2` |     8      | Audio & Multimedia Stack — Kernel/userspace sound libraries, low-latency multimedia graph routers (`pipewire`, `wireplumber`, `jack`, `pulseaudio`, `sndio`), and ALSA sysroot components.                                                                                                                                                                                 |
| [`base-system/`](./base-system/README.md)           | `T2`      |     21     | Base System, LibC & Filesystem Utilities — Foundational OS userland and sysroot libraries (`glibc`, `musl`, `coreutils`, `util-linux`, `pam`, `shadow`, `sudo`, `doas`, `dbus`, `eudev`, `kmod`, `e2fsprogs`, `btrfs-progs`, `xfsprogs`, `dosfstools`, `lfs-*`).                                                                                                           |
| [`bootloaders/`](./bootloaders/README.md)           | `T2`      |     5      | UEFI, BIOS, U-Boot & MCU Bootloaders — System bootloaders and boot managers spanning x86_64/ARM64/RISC-V servers and desktops (`grub`, `systemd-boot`, `limine`, `refind`, `u-boot`) and signed microcontroller firmware (`mcuboot`).                                                                                                                                      |
| [`caches/`](./caches/README.md)                     | `T1`      |     7      | In-Memory Caches & HTTP Accelerators — Low-latency key-value stores, distributed caches, and reverse-proxy HTTP accelerators (`redis`, `valkey`, `dragonfly`, `keydb`, `memcached`, `hazelcast`, `varnish`).                                                                                                                                                               |
| [`containers/`](./containers/README.md)             | `T1`      |     8      | Container Runtimes & Image Builders — OCI container engines, daemonless image builders, and system container managers (`docker`, `podman`, `containerd`, `cri-o`, `buildah`, `skopeo`, `lxc`, `lxd`).                                                                                                                                                                      |
| [`databases/`](./databases/README.md)               | `T1`      |     25     | Relational, Document, Columnar & Consensus Databases — Transactional SQL, NoSQL document, time-series, analytical OLAP, graph, embedded, and Raft/quorum datastore engines (`postgres`, `mariadb`, `mysql`, `sqlite`, `duckdb`, `mongodb`, `clickhouse`, `etcd`, `zookeeper`, `cockroachdb`, `tidb`, `scylladb`, etc.).                                                    |
| [`desktops/`](./desktops/README.md)                 | `T1 / T2` |     11     | Wayland Compositors & X11 Desktop Environments — Graphical desktop environments and tiling/stacking compositors (`kde-plasma-6`, `gnome`, `xfce4`, `lxqt`, `mate`, `sway`, `hyprland`, `labwc`, `weston`, `i3`, `openbox`).                                                                                                                                                |
| [`display-managers/`](./display-managers/README.md) | `T2`      |     5      | Graphical Display Managers & Login Greeters — Wayland and X11 session login managers (`greetd`, `sddm`, `gdm`, `lightdm`, `ly`).                                                                                                                                                                                                                                           |
| [`display-servers/`](./display-servers/README.md)   | `T2`      |     8      | Wayland, Seat Management & X11 Display Servers — Core display protocol libraries, seat multiplexers, and X11/Wayland servers (`wayland`, `wayland-protocols`, `wlroots`, `seatd`, `libseat`, `libxkbcommon`, `xorg-server`, `xwayland`).                                                                                                                                   |
| [`git-servers/`](./git-servers/README.md)           | `T1`      |     5      | Self-Hosted Git Forges & VCS Utilities — Self-hosted Git collaboration servers (`gitea`, `forgejo`, `gitlab`, `cgit`) and shared Git provisioning utilities (`utils`).                                                                                                                                                                                                     |
| [`graphics/`](./graphics/README.md)                 | `T2`      |     7      | DRM, Mesa OpenGL/Vulkan & Hardware Media Drivers — Direct Rendering Manager (`libdrm`), Mesa 3D Gallium/Vulkan (`mesa`, `vulkan-loader`), NVIDIA drivers, and VA-API/VDPAU video acceleration libraries.                                                                                                                                                                   |
| [`iac/`](./iac/README.md)                           | `T1`      |     6      | Infrastructure-as-Code & Provisioning CLI Tools — Declarative infrastructure, configuration, and VM image automation tools (`terraform`, `tofu`, `pulumi`, `ansible`, `packer`, `vagrant`).                                                                                                                                                                                |
| [`init-systems/`](./init-systems/README.md)         | `T2`      |     11     | PID 1 Init Systems & Service Supervisors — Operating system init systems and cross-platform daemon supervisors (`systemd`, `openrc`, `runit`, `s6`, `dinit`, `sysvinit`, `launchd`, `smf`, `windows-scm`, `nssm`, `supervisord`).                                                                                                                                          |
| [`kernel/`](./kernel/README.md)                     | `T2`      |     4      | OS Kernels, Initramfs & Real-Time Operating Systems — Linux kernel source/fragment builder (`linux`), CPIO/UKI `initramfs` generator (`initramfs`), and embedded RTOS kernels (`zephyr`, `freertos`).                                                                                                                                                                      |
| [`languages/`](./languages/README.md)               | `T1`      |     44     | Programming Languages & C/C++ Compilers — Isolated native version managers (`O(1)` `${LIBSCRIPT_HOME}/bin` shims) for 35+ programming languages and C/C++ compiler toolchains (`nodejs`, `python`, `rust`, `go`, `java`, `ruby`, `php`, `zig`, `gcc`, `clang`, `tcc`, `edgcpp`, `custom-cc`, etc.).                                                                        |
| [`logging/`](./logging/README.md)                   | `T1`      |     7      | Observability, Metrics & Log Shippers — Log routers, metrics time-series engines, dashboards, and ML training telemetry servers (`fluentbit`, `vector`, `loki`, `prometheus`, `otel-collector`, `grafana`, `tensorboard`).                                                                                                                                                 |
| [`message-brokers/`](./message-brokers/README.md)   | `T1 / T2` |     9      | Message Brokers, Event Streaming & MQTT — Distributed event streaming, AMQP/NATS messaging, and embedded IoT MQTT libraries (`kafka`, `redpanda`, `pulsar`, `rabbitmq`, `nats`, `activemq`, `mosquitto`, `zeromq`, `coremqtt`).                                                                                                                                            |
| [`networking/`](./networking/README.md)             | `T1 / T2` |     21     | Networking Daemons, Firewalls, VPNs & Universal Routing (`netctl`) — Host networking managers, DHCP/DNS/NTP daemons, packet filters (`nftables`, `iptables`, `pf`, `ufw`, `firewalld`), VPN overlays, embedded `freertos-plus-tcp`, and the universal reverse-proxy compiler `netctl`.                                                                                     |
| [`package-managers/`](./package-managers/README.md) | `T1`      |     87     | OS, Ecosystem & Native Installer Package Managers — System, language-ecosystem, functional (`nix`, `guix`, `spack`), ReactOS (`rapps`), and Windows (`winget`, `choco`, `scoop`, `msi-rs`) package manager bootstrappers and adapters.                                                                                                                                     |
| [`runtimes/`](./runtimes/README.md)                 | `T1 / T2` |     2      | Accelerator & WebAssembly Execution Runtimes — Hardware ML accelerator runtimes (`libtpu`) and lightweight WebAssembly Micro Runtimes (`wamr`) for cloud, edge, and RTOS targets.                                                                                                                                                                                          |
| [`schedulers/`](./schedulers/README.md)             | `T1`      |     12     | Cluster Orchestrators, Service Mesh & HPC Schedulers — Atomic cluster scheduler binaries and control-plane daemons (`kubernetes-k0s`, `k3s`, `kubeadm`, `kubectl`, `nomad`, `mesos`, `marathon`, `slurm`, `consul`, `cilium`, `rancher`, `helm-controller`).                                                                                                               |
| [`search/`](./search/README.md)                     | `T1`      |     7      | Full-Text, Vector & Analytics Search Engines — Distributed search, vector retrieval, and log analytics engines (`elasticsearch`, `opensearch`, `opensearch-dashboards`, `meilisearch`, `typesense`, `solr`, `sonic`).                                                                                                                                                      |
| [`security/`](./security/README.md)                 | `T1`      |     8      | Secrets Management, PKI, IAM & Intrusion Prevention — Secrets vaults (`openbao`, `vault`), internal PKI/ACME (`step-ca`, `certbot`), identity providers (`keycloak`), WireGuard VPN tooling, and active defense daemons (`crowdsec`, `fail2ban`).                                                                                                                          |
| [`storage-layers/`](./storage-layers/README.md)     | `T1 / T2` |     9      | Distributed Object, POSIX & Embedded Flash Filesystems — S3-compatible object stores, distributed filesystems, FUSE cloud mounts, ZFS userland, and microcontroller flash filesystems (`minio`, `garage`, `seaweedfs`, `ceph`, `glusterfs`, `juicefs`, `gcsfuse`, `zfs`, `littlefs`).                                                                                      |
| [`toolchains/`](./toolchains/README.md)             | `T1 / T2` |     60     | Build Systems, Cross-Compilers, SDKs & Compiler Fuzzers — Build systems (`cmake`, `ninja`, `meson`, `bazel`, `buck2`, `make`), LFS/musl/bare-metal/ReactOS/DOS cross-toolchains (`bootstrap`, `lfs-toolchain`, `arm-none-eabi-gcc`, `riscv-none-elf-gcc`, `zephyr-sdk`, `rosbe`, `openwatcom`, `msvc`), and verification tools (`shellcheck`, `csmith`, `yarpgen`, `wix`). |
| [`unikernels/`](./unikernels/README.md)             | `T2`      |     6      | Single-Address-Space Unikernel Toolchains — Unikernel build systems and hypervisor tenders (`osv`, `nanos`, `unikraft`, `mirage`, `rumprun`, `solo5`) consumed by `T3` `synthesis/formats/unikernel_img.*`.                                                                                                                                                                |
| [`utilities/`](./utilities/README.md)               | `T1`      |     46     | Cross-Platform CLI, Compression, Archive & Win32/DOS Utilities — Core CLI tools, shells (`dash`, `powershell`, `busybox`, `toybox`), compression libraries, benchmarking tools, and zero-emulation Windows PE / 32-bit MS-DOS (`dos32`) binary package managers (`jq`, `gawk`, `7zip`, `curl`, `ripgrep`, `fzf`, `tmux`, `psmux`, etc.).                                   |
| [`virtualization/`](./virtualization/README.md)     | `T1`      |     11     | Hypervisors, MicroVMMonitors & Compatibility Layers — Hardware virtual machine monitors, lightweight microVMs, embedded SoC simulators, and binary translation layers (`qemu`, `libvirt`, `firecracker`, `cloud-hypervisor`, `virtualbox`, `utm`, `lima`, `multipass`, `renode`, `wine`, `wsl`).                                                                           |
| [`web-servers/`](./web-servers/README.md)           | `T1`      |     11     | HTTP Reverse Proxies, Load Balancers & Web Servers — High-performance HTTP/1.1, HTTP/2, HTTP/3 web servers and L4/L7 reverse proxies (`nginx`, `caddy`, `haproxy`, `envoy`, `traefik`, `httpd`, `apache`, `openresty`, `lighttpd`, `tomcat`, `iis`).                                                                                                                       |
