#!/usr/bin/env bash

source "$(dirname "$0")/common.sh"

step_start=$(date +%s)
info "STEP 2 start: $(date '+%Y-%m-%d %H:%M:%S')"

kubectl label node "${CLUSTER_NAME}-control-plane" \
  node.kubernetes.io/exclude-from-external-load-balancers- \
  --overwrite || true

step_end=$(date +%s)
step_timer "STEP 2" "$step_start" "$step_end"
