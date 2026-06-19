#!/usr/bin/env bash

source "$(dirname "$0")/common.sh"

step_start=$(date +%s)
info "STEP 4 start: $(date '+%Y-%m-%d %H:%M:%S')"

helm repo add grafana https://grafana.github.io/helm-charts || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts || true
helm repo update grafana prometheus-community open-telemetry || true

step_end=$(date +%s)
step_timer "STEP 4" "$step_start" "$step_end"
