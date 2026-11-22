# Apache Mesos + Marathon HA Topology (`infrastructure/clusters/mesos-marathon-ha`)

## Overview

Declarative T5 High-Availability cluster topology orchestrating **Apache ZooKeeper**
(`_lib/databases/zookeeper`), **Apache Mesos** (`_lib/schedulers/mesos` master quorum + agent
fleet), **Marathon** (`_lib/schedulers/marathon` HA framework), and **netctl**
(`_lib/networking/netctl`) service discovery / ingress routing with distributed locking
(`topologies/lock.{sh,cmd}`) and STONITH fencing (`topologies/fence.{sh,cmd}`).

## Usage

```sh
./infrastructure/clusters/mesos-marathon-ha/cli.sh up
./infrastructure/clusters/mesos-marathon-ha/cli.sh status
./infrastructure/clusters/mesos-marathon-ha/cli.sh scale mesos-agents 5
./infrastructure/clusters/mesos-marathon-ha/cli.sh failover mesos-masters-0
./infrastructure/clusters/mesos-marathon-ha/cli.sh down
```

```cmd
infrastructure\clusters\mesos-marathon-ha\cli.cmd up
infrastructure\clusters\mesos-marathon-ha\cli.cmd status
infrastructure\clusters\mesos-marathon-ha\cli.cmd scale mesos-agents 5
infrastructure\clusters\mesos-marathon-ha\cli.cmd down
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
