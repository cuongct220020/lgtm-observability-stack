#!/usr/bin/env bash

source "$(dirname "$0")/common.sh"

step_start=$(date +%s)
info "STEP 1 start: $(date '+%Y-%m-%d %H:%M:%S')"

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  info "Kind cluster '${CLUSTER_NAME}' already exists. Skipping creation."
else
  info "Creating kind cluster '${CLUSTER_NAME}'..."

  cat <<EOF | kind create cluster --name "${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    image: ${KIND_NODE_IMAGE}
  - role: worker
    image: ${KIND_NODE_IMAGE}
  - role: worker
    image: ${KIND_NODE_IMAGE}
EOF
fi

kubectl cluster-info --context "kind-${CLUSTER_NAME}" || true
kubectl get nodes -o wide || true

step_end=$(date +%s)
step_timer "STEP 1" "$step_start" "$step_end"
