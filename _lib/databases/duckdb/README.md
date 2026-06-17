# DuckDB Component

## Overview

This component manages the installation and execution of `duckdb` within the libscript ecosystem. It
provides CLI wrappers to execute SQL queries or start an interactive REPL, essential for evaluating
Execution Accuracy (EX) in Text-to-SQL tasks.

## Usage

Refer to the component's setup and cli scripts for specific operations.

```bash
# Start an interactive REPL
./_lib/databases/duckdb/cli.sh repl my_dataset.duckdb

# Execute a query directly
./_lib/databases/duckdb/cli.sh execute my_dataset.duckdb "SELECT * FROM pretrain_data LIMIT 5;"
```

## Environment Variables

This component honors standard `libscript` variables. Refer to `_common/base_vars.schema.json`.
