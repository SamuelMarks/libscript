# Cloud SSL Certificates

The `cert` component provides a unified multicloud interface for requesting and managing managed SSL
certificates.

## Usage

```sh
libscript cert [create|delete|list] [--cloud aws|gcp|azure] [--domain name]
```

### Commands

- `create`: Request a new managed SSL certificate for a domain.
- `delete`: Delete an existing managed SSL certificate.
- `list`: List managed SSL certificates.
