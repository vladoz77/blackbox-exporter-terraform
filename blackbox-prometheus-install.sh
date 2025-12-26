#! /bin/bash

# Config blackbox-exporter and Prometheus installation script
set -e
# Config prometheus
PROMETHEUS_BASE_DIR="/home/vlad/prometheus"
PROMETHEUS_IMAGE="prom/prometheus"
PROMETHEUS_CONTAINER_NAME="prometheus"
PROMETHEUS_VERSION="latest"
PROMETHEUS_PORT="9090"

# Config blackbox-exporter
BLACKBOX_BASE_DIR="/home/vlad/blackbox-exporter"
CERTS_DIR="$BLACKBOX_BASE_DIR/certs"
BLACKBOX_IMAGE="prom/blackbox-exporter"
BLACKBOX_VERSION="latest"
BLACKBOX_CONTAINER_NAME="blackbox-exporter"
BLACKBOX_PORT="9115"

# Check for root privileges
if [ "$UID" -ne 0 ]; then
  echo "Please run as root or use sudo"
  exit 1
fi

# Install docker if not install
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
else
    echo "Docker is already installed."
fi
systemctl enable --now docker

# Create docker network for blackbox and prometheus
if ! docker network ls | grep -q "monitoring_net"; then
    echo "Creating docker network 'monitoring_net'..."
    docker network create monitoring_net
else
    echo "Docker network 'monitoring_net' already exists."
fi

#######blackbox-exporter installation########

# Creation of directories for blackbox-exporter configuration
echo "Creating directory ${BLACKBOX_BASE_DIR} and ${CERTS_DIR} for blackbox-exporter configuration..."
mkdir -p $BLACKBOX_BASE_DIR $CERTS_DIR

# Generation of self-signed SSL certificates
echo "Generating self-signed SSL certificates..."
if [ -f "$CERTS_DIR/blackbox.crt" ] || [ -f "$CERTS_DIR/blackbox.key" ]; then
    echo "SSL certificates already exist. Skipping generation."
else
    echo "SSL certificates do not exist. Generating new ones."
    openssl req -newkey rsa:4096 \
      -x509 \
      -sha256 \
      -days 3650 \
      -nodes \
      -out blackbox.crt \
      -keyout blackbox.key \
      -subj "/C=RU/L=Ryazan/O=Fabrika/OU=IT/CN=blackbox.home.local"
    # Move generated certificates to the certs directory
    mv blackbox.crt blackbox.key $CERTS_DIR/
    # chmod 755 $CERTS_DIR
    chmod 644 $CERTS_DIR/*
fi

  # Creation of blackbox-exporter configuration file
echo "Creating blackbox-exporter configuration file..."
cat > $BLACKBOX_BASE_DIR/blackbox.yml << 'EOF'
modules:
  https_endpoint:
    prober: http
    timeout: 15s
    http:
      method: GET
      valid_http_versions:
      - HTTP/1.1
      - HTTP/2.0
      fail_if_not_ssl: true
      no_follow_redirects: false
      ip_protocol_fallback: false
      preferred_ip_protocol: ip4
EOF

# Create blackbox web configuration with TLS
cat > $BLACKBOX_BASE_DIR/web-config.yml << 'EOF'
tls_server_config:
  cert_file: /certs/blackbox.crt
  key_file: /certs/blackbox.key

basic_auth_users:
  blackbox: $2y$10$1KWGGVB0jhe878t6tUvtYeB8/iudISI9tKHdsfSRMMxFKOIwg9XvC
EOF


# Check if blackbox-exporter container is already running delete if exists
echo "Checking if $BLACKBOX_CONTAINER_NAME container is running..."
EXISTING=$(docker ps -a -q -f name="^${BLACKBOX_CONTAINER_NAME}$")
if [ "$EXISTING" ]; then
    echo "$BLACKBOX_CONTAINER_NAME container is already running, removing it..."
    docker rm -f "$BLACKBOX_CONTAINER_NAME"
fi

# Run blackbox-exporter container
echo "Running $BLACKBOX_CONTAINER_NAME container..."
docker run -d --name $BLACKBOX_CONTAINER_NAME \
  --network monitoring_net \
  -p $BLACKBOX_PORT:$BLACKBOX_PORT \
  -v $BLACKBOX_BASE_DIR/blackbox.yml:/etc/blackbox_exporter/blackbox.yml \
  -v $BLACKBOX_BASE_DIR/web-config.yml:/etc/blackbox_exporter/web-config.yml \
  -v $CERTS_DIR:/certs \
  $BLACKBOX_IMAGE:$BLACKBOX_VERSION \
  --config.file=/etc/blackbox_exporter/blackbox.yml \
  --web.config.file=/etc/blackbox_exporter/web-config.yml
echo "blackbox-exporter is running."

#######Prometheus installation########

# Creation of directories for Prometheus configuration
echo "Creating directory ${PROMETHEUS_BASE_DIR} for Prometheus configuration..."
mkdir -p $PROMETHEUS_BASE_DIR

# Creation of Prometheus configuration file
echo "Creating Prometheus configuration file..."
cat > $PROMETHEUS_BASE_DIR/prometheus.yml << EOF
global:
  scrape_interval: 30s
  evaluation_interval: 30s

scrape_configs:
- job_name: $BLACKBOX_CONTAINER_NAME
  scheme: https 
  tls_config:
    insecure_skip_verify: true
    key_file: /certs/blackbox.key
    cert_file: /certs/blackbox.crt
  basic_auth:
    username: blackbox
    password: Password
  metrics_path: /probe
  params:
    module: [ https_endpoint ]
  static_configs:
  - targets:
    - lampa.msk.home-local.site
  relabel_configs:
  - source_labels: [ __address__ ]
    target_label: __param_target
  - source_labels: [ __param_target ]
    target_label: instance
  - target_label: __address__
    replacement: $BLACKBOX_CONTAINER_NAME:$BLACKBOX_PORT
EOF

# Check if prometheus container is already running delete if exists
echo "Checking if $PROMETHEUS_CONTAINER_NAME container is running..."
EXISTING=$(docker ps -a -q -f name="^${PROMETHEUS_CONTAINER_NAME}$")
if [ "$EXISTING" ]; then
    echo "$PROMETHEUS_CONTAINER_NAME container is already running, removing it..."
    docker rm -f "$PROMETHEUS_CONTAINER_NAME"
fi

# Run Prometheus container
echo "Running $PROMETHEUS_CONTAINER_NAME container..."
docker run -d --name $PROMETHEUS_CONTAINER_NAME \
  --network monitoring_net \
  -p $PROMETHEUS_PORT:$PROMETHEUS_PORT \
  -v $PROMETHEUS_BASE_DIR/prometheus.yml:/etc/prometheus/prometheus.yml \
  -v $CERTS_DIR:/certs \
  $PROMETHEUS_IMAGE:$PROMETHEUS_VERSION \
  --config.file=/etc/prometheus/prometheus.yml
echo "Prometheus is running."