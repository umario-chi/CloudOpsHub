#!/bin/bash
set -euo pipefail

echo "=== CloudOpsHub VM Startup - ${environment} ==="

# ── Install Docker Compose ──
if ! command -v docker-compose &> /dev/null; then
  echo "Installing Docker Compose..."
  DOCKER_COMPOSE_VERSION="v2.24.0"
  mkdir -p /usr/local/bin
  curl -SL "https://github.com/docker/compose/releases/download/$${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" \
    -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

# ── Fetch secrets from Secret Manager ──
echo "Fetching secrets from GCP Secret Manager..."
DATABASE_URL=$(gcloud secrets versions access latest --secret="${db_secret_name}" --project="${project_id}")
export DATABASE_URL
GRAFANA_PASSWORD=$(gcloud secrets versions access latest --secret="${grafana_secret_name}" --project="${project_id}")
export GRAFANA_PASSWORD

# ── Login to Artifact Registry ──
echo "Logging into Artifact Registry..."
gcloud auth configure-docker ${registry_host} --quiet

# ── Set up application directory ──
APP_DIR="/opt/theepicbook"
mkdir -p "$APP_DIR"
cd "$APP_DIR"

# ── Write environment file ──
cat > .env <<ENVEOF
DATABASE_URL=$DATABASE_URL
REGISTRY=${registry_url}
NODE_ENV=${environment}
PORT=8080
GRAFANA_PASSWORD=$GRAFANA_PASSWORD
ENVEOF
chmod 600 .env

# ── Write docker-compose for microservices ──
cat > docker-compose.yml <<COMPOSEEOF
version: "3.8"

# Microservices:
# 1. Frontend (nginx)  - static assets + reverse proxy
# 2. Backend  (node)   - Express API + SSR
# 3. Database (mysql)  - Dockerized MySQL

services:
  frontend:
    image: ${registry_url}/theepicbook-frontend:latest
    restart: unless-stopped
    ports:
      - "80:80"
    depends_on:
      - backend
    networks:
      - app-network

  backend:
    image: ${registry_url}/theepicbook-backend:latest
    restart: unless-stopped
    environment:
      - PORT=8080
      - DATABASE_URL=$${DATABASE_URL}
    depends_on:
      database:
        condition: service_healthy
    networks:
      - app-network

  database:
    image: ${registry_url}/theepicbook-database:latest
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: $${DATABASE_URL##*:\/\/*:}
      MYSQL_DATABASE: bookstore
      MYSQL_USER: appuser
      MYSQL_PASSWORD: $${DATABASE_URL##*:\/\/*:}
    volumes:
      - db-data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - app-network

volumes:
  db-data:

networks:
  app-network:
    driver: bridge
COMPOSEEOF

# ── Pull and start application ──
echo "Pulling latest images..."
docker-compose pull

echo "Starting microservices..."
docker-compose up -d --remove-orphans

# ── Set up monitoring stack ──
MONITOR_DIR="/opt/monitoring"
mkdir -p "$MONITOR_DIR/prometheus" "$MONITOR_DIR/grafana/provisioning/datasources" "$MONITOR_DIR/grafana/provisioning/dashboards" "$MONITOR_DIR/grafana/dashboards" "$MONITOR_DIR/alertmanager"

# ── Prometheus config ──
cat > "$MONITOR_DIR/prometheus/prometheus.yml" <<'PROMEOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - alerts.yml

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: node-exporter
    static_configs:
      - targets: ["node-exporter:9100"]

  - job_name: theepicbook-backend
    metrics_path: /metrics
    static_configs:
      - targets: ["backend:8080"]
PROMEOF

# ── Prometheus alert rules ──
cat > "$MONITOR_DIR/prometheus/alerts.yml" <<'ALERTEOF'
groups:
  - name: container_alerts
    rules:
      - alert: ContainerDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Container {{ $labels.instance }} is down"
          description: "{{ $labels.job }} has been down for more than 1 minute."

      - alert: HighCpuUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is above 80% for more than 5 minutes."

      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 85% for more than 5 minutes."

      - alert: DiskSpaceLow
        expr: (1 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})) * 100 > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Disk space low on {{ $labels.instance }}"
          description: "Disk usage is above 90%."
ALERTEOF

# ── Alertmanager config ──
cat > "$MONITOR_DIR/alertmanager/alertmanager.yml" <<'AMEOF'
global:
  resolve_timeout: 5m

route:
  group_by: ["alertname", "severity"]
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: default

receivers:
  - name: default
    webhook_configs:
      - url: "http://backend:8080/alerts"
        send_resolved: true
AMEOF

# ── Grafana provisioning ──
cat > "$MONITOR_DIR/grafana/provisioning/datasources/datasources.yml" <<'DSEOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
DSEOF

cat > "$MONITOR_DIR/grafana/provisioning/dashboards/dashboards.yml" <<'DBEOF'
apiVersion: 1

providers:
  - name: Default
    orgId: 1
    folder: ""
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /var/lib/grafana/dashboards
      foldersFromFilesStructure: false
DBEOF

# ── Grafana dashboard (inline JSON) ──
cat > "$MONITOR_DIR/grafana/dashboards/app-dashboard.json" <<'DASHEOF'
{"annotations":{"list":[]},"editable":true,"fiscalYearStartMonth":0,"graphTooltip":0,"id":null,"links":[],"panels":[{"title":"Container Up/Down","type":"stat","gridPos":{"h":4,"w":6,"x":0,"y":0},"targets":[{"expr":"up{job=\"theepicbook\"}","legendFormat":"App"}],"fieldConfig":{"defaults":{"mappings":[{"options":{"0":{"text":"DOWN","color":"red"},"1":{"text":"UP","color":"green"}},"type":"value"}]}}},{"title":"CPU Usage %","type":"timeseries","gridPos":{"h":8,"w":12,"x":0,"y":4},"targets":[{"expr":"100 - (avg by(instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)","legendFormat":"{{ instance }}"}]},{"title":"Memory Usage %","type":"timeseries","gridPos":{"h":8,"w":12,"x":12,"y":4},"targets":[{"expr":"(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100","legendFormat":"{{ instance }}"}]},{"title":"Disk Usage %","type":"gauge","gridPos":{"h":4,"w":6,"x":6,"y":0},"targets":[{"expr":"(1 - (node_filesystem_avail_bytes{mountpoint=\"/\"} / node_filesystem_size_bytes{mountpoint=\"/\"})) * 100","legendFormat":"{{ instance }}"}],"fieldConfig":{"defaults":{"max":100,"thresholds":{"steps":[{"color":"green","value":null},{"color":"yellow","value":70},{"color":"red","value":90}]}}}}],"schemaVersion":38,"tags":["cloudopshub","theepicbook"],"templating":{"list":[]},"time":{"from":"now-1h","to":"now"},"title":"TheEpicBook Application Dashboard","uid":"theepicbook-app"}
DASHEOF

# ── Monitoring docker-compose ──
cat > "$MONITOR_DIR/docker-compose.yml" <<'MONEOF'
version: "3.8"

services:
  prometheus:
    image: prom/prometheus:v2.48.0
    restart: unless-stopped
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus/alerts.yml:/etc/prometheus/alerts.yml
      - prometheus-data:/prometheus
    ports:
      - "9090:9090"
    networks:
      - monitoring
      - theepicbook_app-network

  grafana:
    image: grafana/grafana:10.2.0
    restart: unless-stopped
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=$${GRAFANA_PASSWORD}
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
      - grafana-data:/var/lib/grafana
    ports:
      - "3000:3000"
    depends_on:
      - prometheus
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:v1.7.0
    restart: unless-stopped
    ports:
      - "9100:9100"
    networks:
      - monitoring

  alertmanager:
    image: prom/alertmanager:v0.26.0
    restart: unless-stopped
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
    ports:
      - "9093:9093"
    networks:
      - monitoring

volumes:
  prometheus-data:
  grafana-data:

networks:
  monitoring:
    driver: bridge
  theepicbook_app-network:
    external: true
MONEOF

# ── Start monitoring stack ──
echo "Starting monitoring stack..."
cd "$MONITOR_DIR"
docker-compose --env-file /opt/theepicbook/.env up -d --remove-orphans

# ── Health check ──
echo "Waiting for application to be healthy..."
cd "$APP_DIR"
for i in $(seq 1 30); do
  if curl -sf http://localhost:80/ > /dev/null 2>&1; then
    echo "All services healthy!"
    exit 0
  fi
  sleep 5
done

echo "WARNING: Application did not become healthy within timeout"
exit 1
