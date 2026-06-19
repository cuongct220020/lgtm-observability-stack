#!/usr/bin/env bash

source "$(dirname "$0")/common.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

step_start=$(date +%s)
info "STEP 5 start: $(date '+%Y-%m-%d %H:%M:%S')"

kubectl create namespace "${NAMESPACE_MONITORING}" --dry-run=client -o yaml | kubectl apply -f -

info "Installing kube-prometheus-stack..."
helm upgrade --install prometheus-operator \
  prometheus-community/kube-prometheus-stack \
  --namespace "${NAMESPACE_MONITORING}" \
  --version "58.6.0" \
  -f "${PROJECT_ROOT}/values/prometheus.yaml" \
  --wait --timeout 8m || warn "kube-prometheus-stack install failed; continuing..."

step_end=$(date +%s)
step_timer "STEP 5" "$step_start" "$step_end"
