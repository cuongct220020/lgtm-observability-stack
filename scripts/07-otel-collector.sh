#!/usr/bin/env bash

source "$(dirname "$0")/common.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

step_start=$(date +%s)
info "STEP 7 start: $(date '+%Y-%m-%d %H:%M:%S')"

info "Installing OpenTelemetry Collector Gateway..."

helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
  --namespace "${NAMESPACE_MONITORING}" \
  --version "0.150.0" \
  -f "${PROJECT_ROOT}/values/otel-collector.yaml" \
  --wait --timeout 5m || warn "OpenTelemetry Collector install failed; continuing..."

info "Checking OpenTelemetry Collector resources..."
kubectl get deploy,pod,svc -n "${NAMESPACE_MONITORING}" | grep otel || true

step_end=$(date +%s)
step_timer "STEP 7" "$step_start" "$step_end"
