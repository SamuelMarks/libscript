<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'rabbitmq' stack.

.DESCRIPTION
Execute this script to install and configure rabbitmq on the local system.
#>

$ErrorActionPreference = "Stop"

winget install --silent --force --id=Erlang.Erlang -e --accept-package-agreements --accept-source-agreements
winget install --silent --force --id=RabbitMQ.RabbitMQ -e --accept-package-agreements --accept-source-agreements
