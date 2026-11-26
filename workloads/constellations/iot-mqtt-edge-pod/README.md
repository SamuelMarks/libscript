# IoT MQTT Edge-to-Cloud Pod (`workloads/constellations/iot-mqtt-edge-pod`)

## Overview

Declarative hybrid topology wiring **Zephyr RTOS** (`qemu_riscv64`) and **FreeRTOS** (`mps2_an385`)
sensor/actuator firmware appliances over TLS-authenticated MQTT (`coremqtt`) to a companion
`_lib/message-brokers/mosquitto` broker and `_lib/databases/postgres` + `timescaledb` time-series
backend.

## Usage

```sh
./workloads/constellations/iot-mqtt-edge-pod/cli.sh validate
./workloads/constellations/iot-mqtt-edge-pod/cli.sh plan
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->

## Orchestrated Components

This stack orchestrates the following LibScript components:

- `_lib/message-brokers/mosquitto`
- `_lib/databases/postgres`
- `_lib/databases/timescaledb`
- `_lib/kernel/zephyr`
- `_lib/kernel/freertos`
