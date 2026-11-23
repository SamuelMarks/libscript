# Message Brokers, Event Streaming & MQTT (`_lib/message-brokers/`)

## Overview

**Tier Scope**: `T1 / T2`

Distributed event streaming, AMQP/NATS messaging, and embedded IoT MQTT libraries (`kafka`,
`redpanda`, `pulsar`, `rabbitmq`, `nats`, `activemq`, `mosquitto`, `zeromq`, `coremqtt`).

Each subdirectory in `_lib/message-brokers/` is an atomic, self-contained LibScript component
governed by its own `manifest.json` and `vars.schema.json`. Components in `_lib/message-brokers/`
never cross-source sibling components directly; instead, they source `T0` helpers from
`engine/common/` and are composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5`
(`workloads/`), and `Plane A` (`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh activemq --help
./libscript.sh install activemq latest
./_lib/message-brokers/activemq/cli.sh test
```

```cmd
.\libscript.cmd activemq --help
.\libscript.cmd install activemq latest
.\_lib\message-brokers\activemq\cli.cmd test
```

## Components (9)

<!-- BEGIN_COMPONENTS -->

- [`activemq`](./activemq/README.md) (`T1` — `userland-package`, `service-daemon`): Multi-protocol
  Java message broker supporting JMS, AMQP, STOMP, MQTT, and OpenWire.
- [`coremqtt`](./coremqtt/README.md) (`T1` — `userland-package`, `service-daemon`):
  Zero-dynamic-allocation C11 MQTT 3.1.1 and MQTT 5.0 client library for FreeRTOS and Zephyr IoT
  appliances.
- [`kafka`](./kafka/README.md) (`T1` — `userland-package`, `service-daemon`): A distributed event
  store and stream-processing platform.
- [`mosquitto`](./mosquitto/README.md) (`T1` — `userland-package`, `service-daemon`): An open source
  message broker that implements the MQTT protocol versions 5.0, 3.1.1 and 3.1.
- [`nats`](./nats/README.md) (`T1` — `userland-package`, `service-daemon`): A simple, secure and
  performant communications system for digital systems, services and devices.
- [`pulsar`](./pulsar/README.md) (`T1` — `userland-package`, `service-daemon`): Cloud-native
  distributed messaging and streaming platform with tiered storage and multi-tenancy.
- [`rabbitmq`](./rabbitmq/README.md) (`T1` — `userland-package`, `service-daemon`): The most widely
  deployed open source message broker.
- [`redpanda`](./redpanda/README.md) (`T1` — `userland-package`, `service-daemon`): C++
  Kafka-compatible streaming data platform and rpk CLI engineered without JVM or ZooKeeper
  dependencies.
- [`zeromq`](./zeromq/README.md) (`T1` — `userland-package`, `service-daemon`): High-performance
  asynchronous distributed messaging library (libzmq) and CurveZMQ key generation tools.

<!-- END_COMPONENTS -->
