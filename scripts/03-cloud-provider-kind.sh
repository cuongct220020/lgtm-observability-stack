#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

step_start=$(date +%s)
info "STEP 3 start: $(date '+%Y-%m-%d %H:%M:%S')"

export PATH="${PATH}:$(go env GOPATH)/bin"

if ! command -v cloud-provider-kind &>/dev/null; then
  info "Installing cloud-provider-kind..."
  go install sigs.k8s.io/cloud-provider-kind@latest
fi

is_cloud_provider_kind_running() {
  pgrep -fa '(^|[[:space:]/])cloud-provider-kind([[:space:]]|$)' >/dev/null 2>&1
}

if is_cloud_provider_kind_running; then
  info "cloud-provider-kind is already running."
else
  info "Starting cloud-provider-kind in background..."

  rm -f /tmp/cloud-provider-kind.log /tmp/cloud-provider-kind.pid

  nohup cloud-provider-kind >> /tmp/cloud-provider-kind.log 2>&1 &
  CLOUD_PROVIDER_PID=$!

  echo "${CLOUD_PROVIDER_PID}" > /tmp/cloud-provider-kind.pid
  info "cloud-provider-kind PID: ${CLOUD_PROVIDER_PID}"

  sleep 5

  if kill -0 "${CLOUD_PROVIDER_PID}" 2>/dev/null; then
    info "cloud-provider-kind started successfully."
  else
    error "cloud-provider-kind failed to start. Log:"
    tail -n 100 /tmp/cloud-provider-kind.log || true
    exit 1
  fi
fi

step_end=$(date +%s)
step_timer "STEP 3" "$step_start" "$step_end"