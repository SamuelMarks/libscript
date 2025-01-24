nginx server roadmap
====================

  - [ ] simple secure (for template interpolation)
  - [ ] simple insecure (for template interpolation)
  - [ ] letsencrypt auto-setup and auto-renew
  - [ ] alternative to letsencrypt (e.g., ZeroSSL, cloud-vendor, user-provided)
  - [ ] setup nginx.conf with sites-available or `/etc/nginx/conf.d/*.conf` as include dir (if not set that way already)
  - [ ] backups and rollbacks, so; e.g.; if `nginx -t` fails rollback to previous working version and show error
  - [ ] checksums (so if nothing changed don't `restart`|`stop`+`start`|`reload` nginx daemon)
  - [ ] translate [compile!] `location` block to IIS and Apache Web Server equivalents
  - [ ] `setup.cmd` for Windows
  - [ ] `setup_generic.sh`
  - [ ] `setup_alpine.sh`
  - [ ] `setup_debian.sh`
  - [ ] `setup_macOS.sh`
