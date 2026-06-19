#!/usr/bin/env bash

source "$(dirname "$0")/common.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

step_start=$(date +%s)
info "STEP 8 start: $(date '+%Y-%m-%d %H:%M:%S')"

kubectl create namespace "${NAMESPACE_DEMO}" --dry-run=client -o yaml | kubectl apply -f -

OTEL_COLLECTOR_SERVICE="otel-collector-opentelemetry-collector.${NAMESPACE_MONITORING}.svc.cluster.local"

info "Installing OpenTelemetry Astronomy Shop demo..."
info "OTel Collector endpoint: ${OTEL_COLLECTOR_SERVICE}:4317"

helm upgrade --install otel-demo open-telemetry/opentelemetry-demo \
  --namespace "${NAMESPACE_DEMO}" \
  --version "0.31.0" \
  -f "${PROJECT_ROOT}/values/otel-demo.yaml" \
  --timeout 10m || warn "OpenTelemetry Astronomy Shop demo install failed; continuing..."

info "Patching demo services that require explicit OTEL_SERVICE_NAME..."

kubectl set env deploy/otel-demo-imageprovider \
  -n "${NAMESPACE_DEMO}" \
  OTEL_SERVICE_NAME=imageprovider \
  OTEL_COLLECTOR_NAME="${OTEL_COLLECTOR_SERVICE}" \
  OTEL_COLLECTOR_HOST="${OTEL_COLLECTOR_SERVICE}" \
  OTEL_COLLECTOR_PORT_GRPC=4317 || true

kubectl set env deploy/otel-demo-recommendationservice \
  -n "${NAMESPACE_DEMO}" \
  OTEL_SERVICE_NAME=recommendationservice \
  OTEL_COLLECTOR_NAME="${OTEL_COLLECTOR_SERVICE}" \
  OTEL_COLLECTOR_HOST="${OTEL_COLLECTOR_SERVICE}" \
  OTEL_COLLECTOR_PORT_GRPC=4317 || true

info "Restarting demo deployments..."
kubectl rollout restart deploy -n "${NAMESPACE_DEMO}" || true

info "Waiting for key demo deployments..."
kubectl rollout status deploy/otel-demo-imageprovider \
  -n "${NAMESPACE_DEMO}" \
  --timeout=3m || true

kubectl rollout status deploy/otel-demo-recommendationservice \
  -n "${NAMESPACE_DEMO}" \
  --timeout=3m || true

kubectl get pods -n "${NAMESPACE_DEMO}" || true

step_end=$(date +%s)
step_timer "STEP 8" "$step_start" "$step_end"
