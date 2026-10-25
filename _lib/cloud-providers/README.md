# Cloud Providers

This category contains components for interacting with major cloud providers such as AWS, GCP, and
Azure.

## Available Components

<!-- BEGIN_COMPONENTS -->

- [aws](./aws/README.md)
- [azure](./azure/README.md)
- [digitalocean](./digitalocean/README.md)
- [gcp](./gcp/README.md)
- [hetzner](./hetzner/README.md)
- [linode](./linode/README.md)
- [proxmox](./proxmox/README.md)
- [vultr](./vultr/README.md)

<!-- END_COMPONENTS -->

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
