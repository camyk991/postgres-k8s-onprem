#!/usr/bin/env bash
NS=${NS:-database}
CLUSTER=${CLUSTER:-pg}
MODE=${1:-rw}
IP=$(kubectl get svc "${CLUSTER}-pooler-${MODE}" -n "$NS" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export PGPASSWORD=$(kubectl get secret "${CLUSTER}-app" -n "$NS" -o jsonpath='{.data.password}' | base64 -d)
echo ">> Connecting to $IP ($MODE)"
psql -h "$IP" -U app -d app
