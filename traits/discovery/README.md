# Service Discovery & Cloud DNS Trait (`traits/discovery/`)

## Overview

`traits/discovery/` queries component `hooks/announce` metadata and maintains internal `/etc/hosts`
blocks (`# BEGIN libscript-discovery` ... `# END libscript-discovery`), mDNS broadcasts, etcd/Consul
service registrations, and public Cloud DNS records (`dns map-node` / `dns unmap-node`) across
Route53, Google Cloud DNS, and Azure DNS.
