# Packaging Visual Test Screenshots

Automated end-to-end installation and GUI verification screenshots captured during Windows Installer
test suites on Vagrant Windows 11 (`bento/windows-11`).

All screenshot binaries are centralized in the
[cc0-screenshots](https://github.com/SamuelMarks/cc0-assets) repository to avoid repository bloat
while providing persistent deep links.

## Screen Captures

### Simple Setup Flow (Express Installation)

- [01_simple_welcome.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/01_simple_welcome.png):
  WiX installer welcome dialog with custom Open edX branding side banner and prerequisite summary.
- [02_simple_license.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/02_simple_license.png):
  End User License Agreement (EULA) screen rendering GNU AGPLv3 terms and license acceptance
  control.
- [03_simple_setup_type.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/03_simple_setup_type.png):
  Setup mode selection dialog with default "Simple Mode (Express Install)" radio button selected.
- [04_simple_verify_ready.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/04_simple_verify_ready.png):
  Pre-installation component summary dialog listing all core non-optional services ready for
  deployment.
- [05_simple_exit.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/05_simple_exit.png):
  Installation finished dialog with automated web browser launch checkboxes for LMS and Studio.

### Advanced Setup Flow (Custom Component & Topology Configuration)

- [06_advanced_setup_type_selected.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06_advanced_setup_type_selected.png):
  Setup mode selection dialog with "Advanced Mode (Custom Configuration)" radio button selected.
- [06a_advanced_features.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06a_advanced_features.png):
  Custom Component Selection dialog configuring LMS, Studio, MySQL, Redis, Celery workers, demo
  courseware, and MFEs.
- [06b_advanced_install_location.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06b_advanced_install_location.png):
  Destination Folders dialog configuring custom paths for application binaries, datastores, logs,
  and backups.
- [06c_advanced_runtime_selection.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06c_advanced_runtime_selection.png):
  Runtime Environment Selection dialog detecting host Python / Node.js runtimes or isolating private
  LibScript environments.
- [06d_advanced_source_repo.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06d_advanced_source_repo.png):
  Source Repository & Release Selection dialog displaying configured Git repository URL, release
  branch/tag, and token input.
- [06e_advanced_config.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06e_advanced_config.png):
  Network and Credentials Configuration dialog setting LMS/Studio web ports, superuser credentials,
  and theme options.
- [07_advanced_db.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/07_advanced_db.png):
  Relational Database / DBaaS Configuration dialog for MySQL port, remote DBaaS connection URL, and
  root credentials.
- [08_advanced_cache_search.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/08_advanced_cache_search.png):
  Cache, Document Store & Search Configuration dialog for Redis port/URL, MongoDB Atlas URI, and
  Meilisearch endpoint.
- [09_advanced_verify_ready.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/09_advanced_verify_ready.png):
  Advanced pre-installation confirmation dialog reviewing customized component topology before
  deployment.
- [10_advanced_exit.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/10_advanced_exit.png):
  Post-install completion screen with branded side splash and browser launch actions.

### Post-Install Desktop & Browser Verification

- [10b_desktop_icons.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/10b_desktop_icons.png):
  Windows 11 desktop showing newly installed Open edX application shortcuts (LMS, Studio CMS, and
  Management Console).
- [11_browser_lms_focused.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/11_browser_lms_focused.png):
  Web browser window verifying Open edX LMS learning portal interface
  (`http://localhost:8000/login`).
- [12_browser_studio_focused.png](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/12_browser_studio_focused.png):
  Web browser window verifying Open edX Studio course authoring CMS interface
  (`http://localhost:8001/signin`).

## Verification Harness

These screenshots are automated by `devtools/capture_openedx_screenshots.sh` and validated by
`tests/test_openedx_msi.sh` / `tests/test_openedx_msi.cmd`.
