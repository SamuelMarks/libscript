# Plane A Encrypted Overlay Mesh Trait (`traits/mesh/`)

## Overview

`traits/mesh/` establishes authenticated, encrypted east-west peer-to-peer overlay networks across
single-cloud, multicloud, and hybrid bare-metal nodes so `T4` clusters and `T5` stateful
constellations communicate over private mesh IPs without exposing replication or consensus ports on
public interfaces.

## Scripts

- **`wireguard.{sh,cmd}`**: Generates Curve25519 keypairs, renders `/etc/wireguard/wg0.conf` peer
  topologies (offline in `--sysroot` mode or live via `wg-quick` / `wireguard.exe`), and verifies
  peer handshakes.
- **`tailscale.{sh,cmd}`**: Automates Tailscale / Headscale pre-auth key enrollment, subnet routing,
  and ACL tag advertisement.

## Usage

```sh
./libscript.sh trait apply mesh
./libscript.sh trait verify mesh
./libscript.sh trait teardown mesh
```
