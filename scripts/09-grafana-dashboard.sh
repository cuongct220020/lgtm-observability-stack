#!/usr/bin/env bash

source "$(dirname "$0")/common.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

step_start=$(date +%s)
info "STEP 9 start: $(date '+%Y-%m-%d %H:%M:%S')"

info "Applying Grafana dashboards from manifests/..."

kubectl apply -n "${NAMESPACE_MONITORING}" -f "${PROJECT_ROOT}/manifests" || warn "Failed to apply one or more Grafana dashboards; continuing..."

info "Restarting Grafana to pick up dashboards..."
kubectl rollout restart deploy/lgtm-grafana -n "${NAMESPACE_MONITORING}" || true
kubectl rollout status deploy/lgtm-grafana -n "${NAMESPACE_MONITORING}" --timeout=3m || true

step_end=$(date +%s)
step_timer "STEP 9" "$step_start" "$step_end"
