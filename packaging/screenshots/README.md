# Packaging Visual Test Screenshots

Automated end-to-end installation and GUI verification screenshots captured during Windows Installer
test suites.

All screenshot binaries are centralized in the
[cc0-screenshots](https://github.com/SamuelMarks/cc0-assets) repository to avoid repository bloat
while providing persistent deep links.

## Screen Captures

### Simple Setup Flow

- [01_simple_welcome.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/01_simple_welcome.png):
  WiX installer welcome dialog with custom Open edX branding.
- [02_simple_license.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/02_simple_license.png):
  End User License Agreement (EULA) screen rendering RTF text.
- [03_simple_setup_type.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/03_simple_setup_type.png):
  Setup mode selection dialog (Simple vs Advanced).
- [04_simple_verify_ready.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/04_simple_verify_ready.png):
  Pre-installation summary dialog ready for execution.
- [05_simple_exit.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/05_simple_exit.png):
  Installation finished dialog with launch triggers.

### Advanced Setup Flow

- [06_advanced_setup_type_selected.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06_advanced_setup_type_selected.png):
  Advanced mode selection with full component topology configuration.
- [06b_advanced_source_repo.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06b_advanced_source_repo.png):
  Source repository URL and release branch/tag selection dialog.
- [07_advanced_db.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/07_advanced_db.png):
  External DBaaS offloading configuration (PostgreSQL, MongoDB).
- [08_advanced_cache_search.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/08_advanced_cache_search.png):
  External caching and search clustering configuration (Redis, Elasticsearch/Meilisearch).
- [09_advanced_verify_ready.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/09_advanced_verify_ready.png):
  Advanced pre-installation confirmation dialog.
- [10_advanced_exit.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/10_advanced_exit.png):
  Post-install verification and completion screen.

### Post-Install Browser Validation

- [11_browser_lms_focused.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/11_browser_lms_focused.png):
  Edge browser window verifying Open edX LMS registration/login interface.
- [12_browser_studio_focused.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/12_browser_studio_focused.png):
  Edge browser window verifying Open edX Studio course authoring interface.

## Verification Harness

These screenshots are captured by `packaging/capture_browser_tabs.ps1` and automated test suites in
`tests/test_openedx_msi.sh` / `tests/test_openedx_msi.cmd`.
