# Android SDK (`android-sdk`)

T1 toolchain recipe for Google's Android SDK Command-Line Tools (`sdkmanager`), `platform-tools`,
`platforms;android-34`, and `build-tools;34.0.0`. Enables autonomous Android and Kotlin
Multiplatform (`androidTarget`) compilation without manual Android Studio setup.

## Usage

```sh
./libscript.sh install android-sdk latest
. "$(./libscript.sh env android-sdk latest)"
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                  | Default                | Aliases/Examples |
| -------------------------- | ---------------------------------------------------------------------------- | ---------------------- | ---------------- |
| `ANDROID_SDK_VERSION`      | Revision number of Google Android commandlinetools to install (or 'latest'). | `11076708`             |                  |
| `ANDROID_PLATFORM`         | Android SDK platform package identifier to install via sdkmanager.           | `platforms;android-34` |                  |
| `ANDROID_BUILD_TOOLS`      | Android SDK build-tools package identifier to install via sdkmanager.        | `build-tools;34.0.0`   |                  |
| `ANDROID_SDK_DOWNLOAD_URL` | Optional explicit download URL override for the commandlinetools archive.    | `none`                 |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
