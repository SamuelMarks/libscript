# ollama Component

## Overview

Libscript manages ollama versions natively by installing them into isolated directories under
\`LIBSCRIPT_HOME/ollama/<version>\`.

## Configuration

| Variable                | Description                                                                                                                                                            | Default            | Required |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | -------- |
| `OLLAMA_INSTALL_METHOD` | How to install OLLAMA. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |          |
