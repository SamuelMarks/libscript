# Usage

_Note: The API is currently under development. These instructions represent the target workflow._

## Prerequisites

- A C compiler (`gcc` or `clang`)
- `cmake` and `make`/`ninja`
- `git`
- `libscript` installed and available on the host machine.

## Building from Source

1. Navigate to the API directory:
   ```bash
   cd libscript-rest-api
   ```
2. Fetch dependencies (e.g., `c-rest-framework`):
   ```bash
   ./scripts/fetch_deps.sh  # (Planned script)
   ```
3. Build the project using CMake:
   ```bash
   mkdir build && cd build
   cmake ..
   make
   ```

## Configuration

Configuration is managed via environment variables. You can optionally create a `.env` file in the
directory where you run the server.

| Variable       | Default     | Description                                           |
| -------------- | ----------- | ----------------------------------------------------- |
| `PORT`         | `8080`      | Port the HTTP server listens on.                      |
| `HOST`         | `127.0.0.1` | Bind address. Use `0.0.0.0` for external access.      |
| `AUTH_ENABLED` | `false`     | Set to `true` to require a Bearer token.              |
| `API_KEY`      | (empty)     | The expected Bearer token if `AUTH_ENABLED=true`.     |
| `LOG_LEVEL`    | `info`      | Logging verbosity (`debug`, `info`, `warn`, `error`). |

## Running the Server

Execute the compiled binary:

```bash
./build/libscript-api
```

## API Interactions

Once running, you can interact with the API using tools like `curl`:

**Check Server Status:**

```bash
curl http://127.0.0.1:8080/api/v1/status
```

**List Available Components:**

```bash
curl http://127.0.0.1:8080/api/v1/components
```

**Trigger an Installation (Async):**

```bash
curl -X POST http://127.0.0.1:8080/api/v1/installations \
     -H "Content-Type: application/json" \
     -d '{"component": "nodejs-server"}'
# Returns 202 Accepted with a {"job_id": "..."}
```
