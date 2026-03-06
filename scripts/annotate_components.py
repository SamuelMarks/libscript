import json
import os
import glob

# Mapping of component paths to their capabilities and conflicts
components = {
    # Databases
    "_lib/_storage/mariadb": {"name": "MARIADB", "provides": ["database", "mysql-compatible", "mariadb"], "conflicts": ["mysql"]},
    "_lib/_storage/postgres": {"name": "POSTGRES", "provides": ["database", "postgres", "postgresql"], "conflicts": []},
    "_lib/_storage/sqlite": {"name": "SQLITE", "provides": ["database", "sqlite"], "conflicts": []},
    "_lib/_storage/mongodb": {"name": "MONGODB", "provides": ["database", "document-db", "mongodb"], "conflicts": []},
    "_lib/_storage/etcd": {"name": "ETCD", "provides": ["kv-store", "etcd"], "conflicts": []},
    "_lib/_storage/rabbitmq": {"name": "RABBITMQ", "provides": ["message-broker", "rabbitmq"], "conflicts": []},
    "_lib/_storage/valkey": {"name": "VALKEY", "provides": ["kv-store", "redis-compatible", "valkey"], "conflicts": ["redis"]},

    # Servers
    "_lib/_server/nginx": {"name": "NGINX", "provides": ["web-server", "reverse-proxy", "nginx"], "conflicts": []},
    "_lib/_server/caddy": {"name": "CADDY", "provides": ["web-server", "reverse-proxy", "caddy"], "conflicts": []},
    "_lib/_server/httpd": {"name": "HTTPD", "provides": ["web-server", "apache", "httpd"], "conflicts": []},
    "_lib/_server/iis": {"name": "IIS", "provides": ["web-server", "iis"], "conflicts": []},
    "_lib/_server/nodejs": {"name": "NODEJS_SERVER", "provides": ["app-server", "nodejs"], "conflicts": []},
    "_lib/_server/python": {"name": "PYTHON_SERVER", "provides": ["app-server", "python", "wsgi", "asgi"], "conflicts": []},
    "_lib/_server/rust": {"name": "RUST_SERVER", "provides": ["app-server", "rust"], "conflicts": []},

    # Toolchains
    "_lib/_toolchain/nodejs": {"name": "NODEJS", "provides": ["runtime", "javascript", "nodejs", "npm"], "conflicts": []},
    "_lib/_toolchain/python": {"name": "PYTHON", "provides": ["runtime", "python", "pip"], "conflicts": []},
    "_lib/_toolchain/rust": {"name": "RUST", "provides": ["compiler", "rust", "cargo"], "conflicts": []},
    "_lib/_toolchain/go": {"name": "GO", "provides": ["compiler", "go"], "conflicts": []},
    "_lib/_toolchain/java": {"name": "JAVA", "provides": ["runtime", "java", "jre", "jdk"], "conflicts": []},
    "_lib/_toolchain/php": {"name": "PHP", "provides": ["runtime", "php"], "conflicts": []},
    "_lib/_toolchain/ruby": {"name": "RUBY", "provides": ["runtime", "ruby", "gem"], "conflicts": []},
    "_lib/_toolchain/deno": {"name": "DENO", "provides": ["runtime", "javascript", "typescript", "deno"], "conflicts": []},
    "_lib/_toolchain/bun": {"name": "BUN", "provides": ["runtime", "javascript", "typescript", "bun"], "conflicts": []},
    "_lib/_toolchain/c": {"name": "C", "provides": ["compiler", "c", "gcc", "clang"], "conflicts": []},
    "_lib/_toolchain/cpp": {"name": "CPP", "provides": ["compiler", "c++", "cpp", "g++", "clang++"], "conflicts": []},
    "_lib/_toolchain/csharp": {"name": "CSHARP", "provides": ["compiler", "c#", "csharp", "dotnet"], "conflicts": []},
    "_lib/_toolchain/kotlin": {"name": "KOTLIN", "provides": ["compiler", "kotlin", "jvm"], "conflicts": []},
    "_lib/_toolchain/elixir": {"name": "ELIXIR", "provides": ["compiler", "elixir", "erlang", "beam"], "conflicts": []},
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
