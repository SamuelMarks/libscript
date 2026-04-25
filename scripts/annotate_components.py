
import sys
if len(sys.argv) > 1 and sys.argv[1] in ["-h", "--help"]:
    print(f"Usage: python {sys.argv[0]} [OPTIONS]")
    print("See script source or documentation for more details.")
    sys.exit(0)
import json
import os
import glob

# Mapping of component paths to their capabilities and conflicts
components = {
    # Databases
    "_lib/databases/mariadb": {"name": "MARIADB", "provides": ["database", "mysql-compatible", "mariadb"], "conflicts": ["mysql"]},
    "_lib/databases/postgres": {"name": "POSTGRES", "provides": ["database", "postgres", "postgresql"], "conflicts": []},
    "_lib/databases/sqlite": {"name": "SQLITE", "provides": ["database", "sqlite"], "conflicts": []},
    "_lib/databases/mongodb": {"name": "MONGODB", "provides": ["database", "document-db", "mongodb"], "conflicts": []},
    "_lib/databases/etcd": {"name": "ETCD", "provides": ["kv-store", "etcd"], "conflicts": []},
    "_lib/message-brokers/rabbitmq": {"name": "RABBITMQ", "provides": ["message-broker", "rabbitmq"], "conflicts": []},
    "_lib/caches/valkey": {"name": "VALKEY", "provides": ["kv-store", "redis-compatible", "valkey"], "conflicts": ["redis"]},

    # Servers
    "_lib/web-servers/nginx": {"name": "NGINX", "provides": ["web-server", "reverse-proxy", "nginx"], "conflicts": []},
    "_lib/web-servers/caddy": {"name": "CADDY", "provides": ["web-server", "reverse-proxy", "caddy"], "conflicts": []},
    "_lib/web-servers/httpd": {"name": "HTTPD", "provides": ["web-server", "apache", "httpd"], "conflicts": []},
    "_lib/web-servers/iis": {"name": "IIS", "provides": ["web-server", "iis"], "conflicts": []},
    "_lib/languages/nodejs_server": {"name": "NODEJS_SERVER", "provides": ["app-server", "nodejs"], "conflicts": []},
    "_lib/languages/python_server": {"name": "PYTHON_SERVER", "provides": ["app-server", "python", "wsgi", "asgi"], "conflicts": []},
    "_lib/languages/rust_server": {"name": "RUST_SERVER", "provides": ["app-server", "rust"], "conflicts": []},

    # Toolchains
    "_lib/languages/nodejs": {"name": "NODEJS", "provides": ["runtime", "javascript", "nodejs", "npm"], "conflicts": []},
    "_lib/languages/python": {"name": "PYTHON", "provides": ["runtime", "python", "pip"], "conflicts": []},
    "_lib/languages/rust": {"name": "RUST", "provides": ["compiler", "rust", "cargo"], "conflicts": []},
    "_lib/languages/go": {"name": "GO", "provides": ["compiler", "go"], "conflicts": []},
    "_lib/languages/java": {"name": "JAVA", "provides": ["runtime", "java", "jre", "jdk"], "conflicts": []},
    "_lib/languages/php": {"name": "PHP", "provides": ["runtime", "php"], "conflicts": []},
    "_lib/languages/ruby": {"name": "RUBY", "provides": ["runtime", "ruby", "gem"], "conflicts": []},
    "_lib/languages/deno": {"name": "DENO", "provides": ["runtime", "javascript", "typescript", "deno"], "conflicts": []},
    "_lib/languages/bun": {"name": "BUN", "provides": ["runtime", "javascript", "typescript", "bun"], "conflicts": []},
    "_lib/languages/c": {"name": "C", "provides": ["compiler", "c", "gcc", "clang"], "conflicts": []},
    "_lib/languages/cpp": {"name": "CPP", "provides": ["compiler", "c++", "cpp", "g++", "clang++"], "conflicts": []},
    "_lib/languages/csharp": {"name": "CSHARP", "provides": ["compiler", "c#", "csharp", "dotnet"], "conflicts": []},
    "_lib/languages/kotlin": {"name": "KOTLIN", "provides": ["compiler", "kotlin", "jvm"], "conflicts": []},
    "_lib/languages/elixir": {"name": "ELIXIR", "provides": ["compiler", "elixir", "erlang", "beam"], "conflicts": []},
}

for path, data in components.items():
    if os.path.exists(path):
        manifest_path = os.path.join(path, "manifest.json")
        with open(manifest_path, 'w') as f:
            json.dump(data, f, indent=2)
            f.write("\n")
        print(f"Created {manifest_path}")
    else:
        print(f"Warning: Directory {path} does not exist, skipping.")

# Create manifests for unmapped directories as a fallback
for category in ["_storage", "_server", "_toolchain"]:
    base_dir = f"_lib/{category}"
    if os.path.exists(base_dir):
        for item in os.listdir(base_dir):
            item_path = os.path.join(base_dir, item)
            if os.path.isdir(item_path) and not os.path.exists(os.path.join(item_path, "manifest.json")):
                manifest_path = os.path.join(item_path, "manifest.json")
                name = item.upper()
                provides = [item]
                if category == "_storage": provides.append("database")
                elif category == "_server": provides.append("server")
                elif category == "_toolchain": provides.append("toolchain")
                
                data = {"name": name, "provides": provides, "conflicts": []}
                with open(manifest_path, 'w') as f:
                    json.dump(data, f, indent=2)
                    f.write("\n")
                print(f"Created fallback {manifest_path}")

print("Phase 2 component annotation completed.")
