# Networking Daemons, Firewalls, VPNs & Universal Routing (`netctl`) (`_lib/networking/`)

## Overview

**Tier Scope**: `T1 / T2`

Host networking managers, DHCP/DNS/NTP daemons, packet filters (`nftables`, `iptables`, `pf`, `ufw`,
`firewalld`), VPN overlays, embedded `freertos-plus-tcp`, and the universal reverse-proxy compiler
`netctl`.

Each subdirectory in `_lib/networking/` is an atomic, self-contained LibScript component governed by
its own `manifest.json` and `vars.schema.json`. Components in `_lib/networking/` never cross-source
sibling components directly; instead, they source `T0` helpers from `engine/common/` and are
composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and `Plane A`
(`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh bind9 --help
./libscript.sh install bind9 latest
./_lib/networking/bind9/cli.sh test
```

```cmd
.\libscript.cmd bind9 --help
.\libscript.cmd install bind9 latest
.\_lib\networking\bind9\cli.cmd test
```

## Components (22)

<!-- BEGIN_COMPONENTS -->

- [`bind9`](./bind9/README.md) (`T1` — `userland-package`, `service-daemon`): ISC BIND 9 (named)
  authoritative, recursive, and DNSSEC-validating Domain Name System server and utilities.
- [`chrony`](./chrony/README.md) (`T1` — `userland-package`): Versatile Network Time Protocol daemon
- [`coredns`](./coredns/README.md) (`T1` — `userland-package`, `service-daemon`): CoreDNS
  cloud-native, plugin-driven DNS server and service discovery engine.
- [`dhcpcd`](./dhcpcd/README.md) (`T1` — `userland-package`): RFC-compliant DHCP client daemon
- [`dnsmasq`](./dnsmasq/README.md) (`T1` — `userland-package`, `service-daemon`): Lightweight DNS
  forwarder, DHCPv4/v6 server, router advertisement, and PXE/TFTP network boot server.
- [`dos-pktdrv`](./dos-pktdrv/README.md) (`T2` — `sysroot-package`): Crynwr DOS packet drivers
  (`PCNTPKT.COM`, `NE2000.COM`), `SHSUCDX.COM`, `UDVD2.SYS`, `HIMEMX.EXE`, `FDAPM.COM`, and
  `DOSLFN.COM`.
- [`firewalld`](./firewalld/README.md) (`T1` — `userland-package`): Dynamically managed Linux
  firewall daemon (firewalld and firewall-cmd) supporting network/firewall zones over nftables and
  iptables.
- [`freertos-plus-tcp`](./freertos-plus-tcp/README.md) (`T1` — `userland-package`): Thread-safe
  embedded IPv4/IPv6 TCP/UDP/DNS/DHCP networking stack for FreeRTOS bare-metal appliances.
- [`frr`](./frr/README.md) (`T1` — `userland-package`, `service-daemon`): FRRouting IP routing
  protocol suite implementing BGP, OSPF, RIP, IS-IS, PIM, LDP, BFD, Babel, and EVPN (vtysh, zebra,
  bgpd, ospfd).
- [`iptables`](./iptables/README.md) (`T2` — `sysroot-package`): Traditional Linux packet filter
  userland utility
- [`iwd`](./iwd/README.md) (`T2` — `sysroot-package`): Intel Wireless Daemon for Linux
- [`keepalived`](./keepalived/README.md) (`T1` — `userland-package`): Keepalived VRRPv2/v3 virtual
  router redundancy and Linux Virtual Server (IPVS) load-balancing healthcheck daemon.
- [`netctl`](./netctl/README.md) (`T2` — `sysroot-package`): Unified network port, reverse proxy,
  and firewall orchestration engine for LibScript.
- [`networkmanager`](./networkmanager/README.md) (`T2` — `sysroot-package`): Universal network
  configuration and management daemon
- [`nftables`](./nftables/README.md) (`T2` — `sysroot-package`): Netfilter project packet
  classification framework
- [`openssh`](./openssh/README.md) (`T1` — `userland-package`): Hardened secure remote login and
  shell daemon
- [`openvpn`](./openvpn/README.md) (`T1` — `userland-package`): openvpn stack
- [`pf`](./pf/README.md) (`T2` — `sysroot-package`): FreeBSD stateful packet inspection firewall
- [`systemd-networkd`](./systemd-networkd/README.md) (`T1` — `userland-package`): Network device
  manager integrated into systemd
- [`tailscale`](./tailscale/README.md) (`T2` — `sysroot-package`, `service-daemon`): Tailscale
  zero-config WireGuard mesh VPN client and daemon (tailscale and tailscaled).
- [`ufw`](./ufw/README.md) (`T1` — `userland-package`): Uncomplicated Firewall (ufw) command-line
  host firewall configuration frontend for netfilter/iptables and nftables.
- [`wpa_supplicant`](./wpa_supplicant/README.md) (`T2` — `sysroot-package`): WPA/WPA2/WPA3 wireless
  security daemon

<!-- END_COMPONENTS -->
