# Cross-Cloud Encrypted Mesh Trait (`traits/mesh/`)

## Overview

`traits/mesh/` establishes encrypted overlay networks across multicloud and hybrid-cloud cluster
topologies using either WireGuard (`wireguard.{sh,cmd}`) or Tailscale (`tailscale.{sh,cmd}`).

## WireGuard Overlay Addressing

- Generates `/etc/wireguard/libscript-mesh.key` idempotently with `0600` permissions.
- Assigns deterministic RFC 6598 CGNAT IPv4 (`100.64.x.y/24`) and ULA IPv6 (`fd00:libscript::x/64`)
  overlay addresses.
- Renders `[Peer]` blocks for all nodes in `.topology_state.json`.
