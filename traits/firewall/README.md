# Plane A Host Firewall & Anti-Lockout Trait (`traits/firewall/`)

## Overview

`traits/firewall/` compiles declarative ingress/egress port and CIDR policies into native host
packet filters while enforcing automatic SSH/WinRM anti-lockout preservation so remote operators
cannot sever their active management session.

## Scripts

- **`compile.{sh,cmd}`**: Emits and applies firewall rulesets across Linux `nftables`, `iptables`,
  and `ufw`, FreeBSD/macOS/illumos `pf`/`ipfilter`, and Windows `netsh advfirewall firewall`. In
  `T3` `--sysroot` mode, writes `/etc/nftables.conf` or `/etc/pf.conf` offline without touching the
  build host's live kernel tables.
- **`teardown.{sh,cmd}`**: Cleanly removes LibScript-managed firewall chains/rules while preserving
  baseline host rules.

## Usage

```sh
./libscript.sh trait apply firewall
./libscript.sh trait verify firewall
./libscript.sh trait teardown firewall
```
