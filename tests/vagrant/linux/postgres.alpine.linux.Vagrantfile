Vagrant.configure("2") do |config|
  config.vm.box = "alpine-test"
  config.vm.box_architecture = "arm64"
  config.vm.box_version = "0"

  config.vm.synced_folder ".", "/opt/repos/libscript", type: "rsync"

  config.vm.network "forwarded_port", guest: 22, host: 2223, id: "ssh", auto_correct: true

  config.vm.provision "shell", inline: <<-SHELL
    set -e

    echo "Updating apk repositories..."
    apk update

    echo "Configuring libscript..."
    export LIBSCRIPT_ROOT_DIR=/opt/repos/libscript
    cd /opt/repos/libscript

    echo "Installing PostgreSQL and Python using libscript (system method)..."
    ./libscript.sh install postgres 17 --POSTGRES_INSTALL_METHOD=system
    ./libscript.sh install python 3 --PYTHON_INSTALL_METHOD=system

    echo "Installing psycopg2 for Python..."
    apk add --no-cache py3-psycopg2

    echo "Initializing PostgreSQL database..."
    # Alpine auto-initializes or we can just restart it if needed, but libscript install handles the initial start.
    # We will explicitly restart to ensure any changes are caught.
    ./libscript.sh restart postgres

    echo "Waiting for PostgreSQL to be ready..."
    sleep 3

    echo "Checking PostgreSQL health using libscript..."
    ./libscript.sh health postgres

    echo "Creating test user and database..."
    su - postgres -c "psql -c \\"CREATE USER testuser WITH PASSWORD 'testpass';\\""
    su - postgres -c "psql -c \\"CREATE DATABASE testdb OWNER testuser;\\""

    echo "Creating Python healthcheck script..."
    cat << 'EOF' > /tmp/healthcheck.py
import psycopg2
import sys

try:
    conn = psycopg2.connect(
        dbname="testdb",
        user="testuser",
        password="testpass",
        host="127.0.0.1",
        port="5432"
    )
    cur = conn.cursor()
    cur.execute("SELECT 1;")
    result = cur.fetchone()
    if result and result[0] == 1:
        print("PostgreSQL healthcheck passed via libscript environment!")
        sys.exit(0)
    else:
        print("Unexpected result from PostgreSQL!")
        sys.exit(1)
except Exception as e:
    print("Healthcheck failed: " + str(e))
    sys.exit(1)
EOF

    echo "Running Python healthcheck..."
    python3 /tmp/healthcheck.py
  SHELL
end
