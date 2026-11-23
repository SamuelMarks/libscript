# MSI Logical SQL Database Provisioner (`synthesis/msi/src/sql_provisioner/`)

## Overview

`synthesis/msi/src/sql_provisioner/` implements transactional logical database, role, and schema
provisioning for Windows MSI installers (`ARCHITECTURE_LOGICAL_PROVISIONING.md`). It supports both
newly installed local database daemons (`USER_DB_STRATEGY=local`, with automatic `DROP DATABASE`
cleanup on MSI rollback) and pre-existing remote database clusters (`USER_DB_STRATEGY=remote`,
performing non-destructive connectivity verification without dropping remote state on rollback).
