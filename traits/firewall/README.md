# Host Firewall & Security Group Trait (`traits/firewall/`)

## Overview

`traits/firewall/` queries active components via `hooks/announce.{sh,cmd}`, distinguishes public
ingress ports (`0.0.0.0/0`) from internal mesh/VPC ports, and compiles rules for `nftables`,
`iptables`, `pf` (FreeBSD/macOS/illumos), and Windows `netsh advfirewall`.

## Anti-Lockout Safeguard

Before applying default-deny policies, `compile.{sh,cmd}` automatically detects active management
ports (`SSH_CONNECTION` port, default `22`, WinRM `5985`/`5986`, RDP `3389`, and
`libscript-rest-api` port `8080`) and prepends explicit allow rules.
