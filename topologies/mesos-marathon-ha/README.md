# Apache Mesos + Marathon HA Topology (`topologies/mesos-marathon-ha`)

## Overview
Declarative Tier 3.5 High-Availability cluster topology orchestrating **Apache ZooKeeper**
(`_lib/databases/zookeeper`), **Apache Mesos** (`_lib/orchestration/mesos` master quorum + agent
fleet), **Marathon** (`_lib/orchestration/marathon` HA framework), and **netctl**
(`_lib/networking/netctl`) service discovery / ingress routing with distributed locking
(`topologies/lock.{sh,cmd}`) and STONITH fencing (`topologies/fence.{sh,cmd}`).

## Usage
```sh
./topologies/mesos-marathon-ha/cli.sh up
./topologies/mesos-marathon-ha/cli.sh status
./topologies/mesos-marathon-ha/cli.sh scale mesos-agents 5
./topologies/mesos-marathon-ha/cli.sh failover mesos-masters-0
./topologies/mesos-marathon-ha/cli.sh down
```

```cmd
topologies\mesos-marathon-ha\cli.cmd up
topologies\mesos-marathon-ha\cli.cmd status
topologies\mesos-marathon-ha\cli.cmd scale mesos-agents 5
topologies\mesos-marathon-ha\cli.cmd down
```
