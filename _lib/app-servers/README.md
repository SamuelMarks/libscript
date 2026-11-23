# Application & Inference Servers (`_lib/app-servers/`)

## Overview

**Tier Scope**: `T1`

Language application workers (WSGI/ASGI, PHP-FPM, Puma, Passenger, PM2, JEE servlet containers) and
high-throughput LLM/ML inference servers (`vLLM`, `JetStream`, `Triton`, `Ollama`).

Each subdirectory in `_lib/app-servers/` is an atomic, self-contained LibScript component governed
by its own `manifest.json` and `vars.schema.json`. Components in `_lib/app-servers/` never
cross-source sibling components directly; instead, they source `T0` helpers from `engine/common/`
and are composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and
`Plane A` (`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh glassfish --help
./libscript.sh install glassfish latest
./_lib/app-servers/glassfish/cli.sh test
```

```cmd
.\libscript.cmd glassfish --help
.\libscript.cmd install glassfish latest
.\_lib\app-servers\glassfish\cli.cmd test
```

## Components (21)

<!-- BEGIN_COMPONENTS -->

- [`glassfish`](./glassfish/README.md) (`T1` — `userland-package`, `service-daemon`): Eclipse
  Foundation open-source Jakarta EE compatible enterprise application server.
- [`gunicorn`](./gunicorn/README.md) (`T1` — `userland-package`, `service-daemon`): Python WSGI HTTP
  Server for UNIX / POSIX.
- [`jboss`](./jboss/README.md) (`T1` — `userland-package`, `service-daemon`): JBoss EAP / WildFly
  upstream Jakarta EE application server runtime and jboss-cli management tool.
- [`jetstream`](./jetstream/README.md) (`T1` — `userland-package`, `service-daemon`):
  High-performance generative AI inference server
- [`jetty`](./jetty/README.md) (`T1` — `userland-package`, `service-daemon`): Lightweight, highly
  scalable Java HTTP web server and Jakarta Servlet container.
- [`nodejs-server`](./nodejs-server/README.md) (`T1` — `userland-package`, `service-daemon`):
  Generic Node.js application server component.
- [`ollama`](./ollama/README.md) (`T1` — `userland-package`, `service-daemon`): Get up and running
  with large language models.
- [`passenger`](./passenger/README.md) (`T1` — `userland-package`, `service-daemon`): Polyglot web
  and application server supporting Ruby, Node.js, Python, and Meteor workloads.
- [`payara`](./payara/README.md) (`T1` — `userland-package`, `service-daemon`): Cloud-native
  open-source Jakarta EE and MicroProfile enterprise application server runtime.
- [`php-fpm`](./php-fpm/README.md) (`T1` — `userland-package`, `service-daemon`): PHP FastCGI
  Process Manager daemon with adaptive process spawning for high-traffic PHP sites.
- [`pm2`](./pm2/README.md) (`T1` — `userland-package`, `service-daemon`): Production process manager
  and cluster load balancer for Node.js and polyglot applications.
- [`puma`](./puma/README.md) (`T1` — `userland-package`, `service-daemon`): Fast, multithreaded, and
  highly concurrent HTTP 1.1 server for Ruby and Rack applications.
- [`python-server`](./python-server/README.md) (`T1` — `userland-package`, `service-daemon`):
  Generic Python application server component (WSGI/ASGI).
- [`rust-server`](./rust-server/README.md) (`T1` — `userland-package`, `service-daemon`): Generic
  Rust application server component.
- [`triton`](./triton/README.md) (`T1` — `userland-package`, `service-daemon`): Open-source
  inference serving software streamlining AI model deployment across GPUs and CPUs.
- [`unicorn`](./unicorn/README.md) (`T1` — `userland-package`, `service-daemon`): Rack HTTP server
  for fast clients and Unix-like operating systems utilizing pre-forking worker processes.
- [`uvicorn`](./uvicorn/README.md) (`T1` — `userland-package`, `service-daemon`): An ASGI web server
  implementation for Python with native Windows support.
- [`uwsgi`](./uwsgi/README.md) (`T1` — `userland-package`, `service-daemon`): Fast, self-healing,
  developer-friendly WSGI server and application container.
- [`vllm`](./vllm/README.md) (`T1` — `userland-package`, `service-daemon`): High-throughput and
  memory-efficient LLM inference server
- [`waitress`](./waitress/README.md) (`T1` — `userland-package`, `service-daemon`):
  Production-quality pure-Python WSGI server with native Windows support.
- [`wildfly`](./wildfly/README.md) (`T1` — `userland-package`, `service-daemon`): Flexible,
  lightweight, managed Jakarta EE and MicroProfile application runtime.

<!-- END_COMPONENTS -->
