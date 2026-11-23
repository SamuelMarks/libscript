# Nginx Component Roadmap (`_lib/web-servers/nginx/`)

## Completed Capabilities

- [x] Isolated `T1` `libscript_native`, `from-source` (multi-compiler `gcc`/`clang`/`tcc`/`edgcpp`),
      and `system` installation modes across Linux, macOS, FreeBSD, illumos, and Windows.
- [x] Idempotent server-block and location-block composition (`create_server_block.{sh,cmd}`,
      `create_location_block.{sh,cmd}`, `merge_location_into_server.{sh,cmd}`) integrated with
      `_lib/networking/netctl/` and `T0` `engine/hooks/web-servers/`.
- [x] Native `service-daemon` supervision across `systemd`, `openrc`, `launchd`, `smf`, and Windows
      Services, plus zero-downtime configuration validation (`nginx -t`) before reload.

## Planned Enhancements

- [ ] First-class HTTP/3 (`listen ... quic reuseport`) and `ssl_early_data` fragment emission in
      `conf/` templates when built against OpenSSL 3.2+ or BoringSSL/QuicTLS.
- [ ] Optional dynamic module build variants (`brotli`, `njs`, `geoip2`, `headers-more`) exposed in
      `manifest.json` `variants`.
- [ ] Automated OCSP stapling verification and Prometheus `stub_status` exporter wiring via
      `hooks/metrics.{sh,cmd}`.
