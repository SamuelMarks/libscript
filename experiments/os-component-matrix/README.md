# 7-OS Component Compatibility & 2x-Idempotency Matrix (`experiments/os-component-matrix`)

Coordinates Bento Vagrant VMs and host OS runners across Alpine (`apk`), Debian/Ubuntu (`deb`),
Rocky/RHEL (`rpm`), FreeBSD, OmniOS/illumos (`SunOS`), macOS (`darwin`), and Windows, emitting
provenance-stamped `matrix_results.json` (`schemas/os-matrix-results.schema.json`) and
deterministically regenerating root `README.md`.
