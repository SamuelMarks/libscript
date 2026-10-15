# Dynamic Ingress Trait (`traits/ingress/`)

## Overview

`traits/ingress/` acts as the reactive service discovery bridge to `_lib/networking/netctl/`. It
queries installed components and logical tenants via `hooks/announce.{sh,cmd}`, updates
`.netctl.json` via `netctl` (`init`, `listen`, `proxy`, `static`, `rewrite`), and emits native
configurations for `nginx`, `caddy`, `apache` (`httpd`), `iis`, and `traefik` with syntax validation
and automatic rollback.
