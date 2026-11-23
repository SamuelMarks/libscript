# HTTP Reverse Proxies, Load Balancers & Web Servers (`_lib/web-servers/`)

## Overview

**Tier Scope**: `T1`

High-performance HTTP/1.1, HTTP/2, HTTP/3 web servers and L4/L7 reverse proxies (`nginx`, `caddy`,
`haproxy`, `envoy`, `traefik`, `httpd`, `apache`, `openresty`, `lighttpd`, `tomcat`, `iis`).

Each subdirectory in `_lib/web-servers/` is an atomic, self-contained LibScript component governed
by its own `manifest.json` and `vars.schema.json`. Components in `_lib/web-servers/` never
cross-source sibling components directly; instead, they source `T0` helpers from `engine/common/`
and are composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and
`Plane A` (`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh apache --help
./libscript.sh install apache latest
./_lib/web-servers/apache/cli.sh test
```

```cmd
.\libscript.cmd apache --help
.\libscript.cmd install apache latest
.\_lib\web-servers\apache\cli.cmd test
```

## Components (11)

<!-- BEGIN_COMPONENTS -->

- [`apache`](./apache/README.md) (`T1` — `userland-package`, `service-daemon`): Apache HTTP Server
  (apachectl / apache2) modular, cross-platform web server recipe.
- [`caddy`](./caddy/README.md) (`T1` — `userland-package`, `service-daemon`): A powerful,
  enterprise-ready, open source web server with automatic HTTPS written in Go.
- [`envoy`](./envoy/README.md) (`T1` — `userland-package`, `service-daemon`): Cloud-native
  high-performance C++ distributed L4/L7 edge and service proxy.
- [`haproxy`](./haproxy/README.md) (`T1` — `userland-package`, `service-daemon`): Reliable,
  high-performance TCP/HTTP load balancer and proxy server for high-availability systems.
- [`httpd`](./httpd/README.md) (`T1` — `userland-package`, `service-daemon`): The Apache HTTP
  Server, a secure, efficient and extensible server that provides HTTP services in sync with the
  current HTTP standards.
- [`iis`](./iis/README.md) (`T1` — `userland-package`, `service-daemon`): Flexible, secure and
  manageable Web server for hosting anything on the Web.
- [`lighttpd`](./lighttpd/README.md) (`T1` — `userland-package`, `service-daemon`): A secure, fast,
  compliant, and very flexible web-server that has been optimized for high-performance environments.
- [`nginx`](./nginx/README.md) (`T1` — `userland-package`, `service-daemon`): A high-performance
  HTTP and reverse proxy server, as well as a mail proxy server.
- [`openresty`](./openresty/README.md) (`T1` — `userland-package`, `service-daemon`): Dynamic web
  platform based on Nginx and LuaJIT for high-concurrency API gateways and web apps.
- [`tomcat`](./tomcat/README.md) (`T1` — `userland-package`, `service-daemon`): Open-source
  implementation of Jakarta Servlet, Jakarta Server Pages, and WebSocket specifications.
- [`traefik`](./traefik/README.md) (`T1` — `userland-package`, `service-daemon`): Modern HTTP
  reverse proxy and cloud-native edge router with automatic service discovery and TLS.

<!-- END_COMPONENTS -->
