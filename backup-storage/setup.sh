#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

BUCKET="${BUCKET:-pg-backups}"

if [[ ! -f .env ]]; then
  echo ">> Generating .env (S3 credentials)"
  cat > .env <<EOF
GARAGE_DEFAULT_ACCESS_KEY=GK$(openssl rand -hex 16)
GARAGE_DEFAULT_SECRET_KEY=$(openssl rand -hex 32)
GARAGE_DEFAULT_BUCKET=${BUCKET}
EOF
  chmod 600 .env
fi

if [[ ! -f garage.toml ]]; then
  echo ">> Generating garage.toml"
  cat > garage.toml <<EOF
metadata_dir = "/var/lib/garage/meta"
data_dir     = "/var/lib/garage/data"
db_engine    = "sqlite"

replication_factor = 1

rpc_bind_addr   = "[::]:3901"
rpc_public_addr = "127.0.0.1:3901"
rpc_secret      = "$(openssl rand -hex 32)"

[s3_api]
s3_region     = "garage"
api_bind_addr = "[::]:3900"
root_domain   = ".s3.garage.localhost"

[admin]
api_bind_addr = "[::]:3903"
admin_token   = "$(openssl rand -base64 32)"
metrics_token = "$(openssl rand -base64 32)"
EOF
  chmod 600 garage.toml
fi

if docker compose version >/dev/null 2>&1; then COMPOSE="docker compose"; else COMPOSE="docker-compose"; fi
$COMPOSE up -d
sleep 3
docker exec garage /garage status
echo
docker exec garage /garage bucket list
echo
echo ">> Garage is running. S3 endpoint for the cluster: http://172.16.144.1:3900 (region: garage, bucket: ${BUCKET})"
