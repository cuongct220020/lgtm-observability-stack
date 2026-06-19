#!/usr/bin/env bash

source "$(dirname "$0")/common.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

step_start=$(date +%s)
info "STEP 6 start: $(date '+%Y-%m-%d %H:%M:%S')"

# Mimir
info "Installing Mimir..."
helm upgrade --install lgtm-mimir grafana/mimir-distributed \
  --namespace "${NAMESPACE_MONITORING}" \
  --version "5.3.0" \
  -f "${PROJECT_ROOT}/values/mimir.yaml" \
  --wait --timeout 10m || warn "Mimir install failed; continuing..."

# Loki
info "Installing Loki..."
helm upgrade --install lgtm-loki grafana/loki \
  --namespace "${NAMESPACE_MONITORING}" \
  --version "6.6.4" \
  -f "${PROJECT_ROOT}/values/loki.yaml" \
  --wait --timeout 8m || warn "Loki install failed; continuing..."

# Tempo
info "Installing Tempo..."
helm upgrade --install lgtm-tempo grafana/tempo \
  --namespace "${NAMESPACE_MONITORING}" \
  --version "1.9.0" \
  -f "${PROJECT_ROOT}/values/tempo.yaml" \
  --wait --timeout 8m || warn "Tempo install failed; continuing..."

# Promtail
info "Installing Promtail for Kubernetes logs..."
helm upgrade --install lgtm-promtail grafana/promtail \
  --namespace "${NAMESPACE_MONITORING}" \
  -f "${PROJECT_ROOT}/values/promtail.yaml" \
  --wait --timeout 5m || warn "Promtail install failed; continuing..."

# Grafana
info "Installing Grafana with datasources and dashboard sidecar..."
helm upgrade --install lgtm-grafana grafana/grafana \
  --namespace "${NAMESPACE_MONITORING}" \
  --version "7.3.9" \
  -f "${PROJECT_ROOT}/values/grafana.yaml" \
  --wait --timeout 8m || warn "Grafana install failed; continuing..."

step_end=$(date +%s)
step_timer "STEP 6" "$step_start" "$step_end"
