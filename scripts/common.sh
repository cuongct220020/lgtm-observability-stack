#!/usr/bin/env bash

set -uo pipefail

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-observability}"
NAMESPACE_MONITORING="${NAMESPACE_MONITORING:-monitoring}"
NAMESPACE_DEMO="${NAMESPACE_DEMO:-otel-demo}"
KIND_NODE_IMAGE="${KIND_NODE_IMAGE:-kindest/node:v1.32.8}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging functions
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Error handling
on_error() {
  local line_no=$1
  warn "Error at line ${line_no}; continuing..."
}
trap 'on_error $LINENO' ERR

# Helper functions
wait_pods() {
  local namespace="$1"
  local timeout="${2:-300s}"

  info "Waiting for pods in namespace '${namespace}'..."
  kubectl wait --for=condition=Ready pod --all -n "${namespace}" --timeout="${timeout}" || true
  kubectl get pods -n "${namespace}" || true
}

get_lb_ip() {
  kubectl get svc "$1" -n "$2" \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "<pending>"
}

get_lb_host() {
  local service_name="$1"
  local namespace="$2"
  local host

  host=$(kubectl get svc "${service_name}" -n "${namespace}" \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

  if [ -z "${host}" ]; then
    host=$(kubectl get svc "${service_name}" -n "${namespace}" \
      -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
  fi

  echo "${host}"
}

get_service_port() {
  kubectl get svc "$1" -n "$2" \
    -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo ""
}

format_url() {
  local scheme="$1"
  local host="$2"
  local port="$3"

  if [ -z "${host}" ]; then
    echo ""
  elif [ -z "${port}" ] || { [ "${scheme}" = "http" ] && [ "${port}" = "80" ]; } || { [ "${scheme}" = "https" ] && [ "${port}" = "443" ]; }; then
    echo "${scheme}://${host}"
  else
    echo "${scheme}://${host}:${port}"
  fi
}

helm_release_exists() {
  local release_name="$1"
  local namespace="$2"

  helm status "${release_name}" -n "${namespace}" > /dev/null 2>&1
}

helm_release_pod_status() {
  local release_name="$1"
  local namespace="$2"
  local pod_lines
  local pod_line
  local phase
  local statuses
  local any_pods=0

  if ! helm_release_exists "${release_name}" "${namespace}"; then
    echo "not-deployed"
    return
  fi

  pod_lines=$(kubectl get pods -n "${namespace}" \
    -l "app.kubernetes.io/instance=${release_name}" \
    -o jsonpath='{range .items[*]}{.status.phase}{"|"}{range .status.containerStatuses[*]}{.ready}{" "}{end}{"\n"}{end}' 2>/dev/null || true)

  if [ -z "${pod_lines}" ]; then
    echo "starting"
    return
  fi

  while IFS= read -r pod_line; do
    [ -z "${pod_line}" ] && continue
    any_pods=1
    phase=${pod_line%%|*}
    statuses=${pod_line#*|}

    if [ "${phase}" != "Running" ] && [ "${phase}" != "Succeeded" ]; then
      echo "starting"
      return
    fi

    case " ${statuses} " in
      *" false "*)
        echo "starting"
        return
        ;;
    esac
  done <<EOPODS
${pod_lines}
EOPODS

  if [ "${any_pods}" -eq 0 ]; then
    echo "starting"
  else
    echo "ready"
  fi
}

step_timer() {
  local step_name="$1"
  local start_time=$2
  local end_time=$3

  info "${step_name} end: $(date -d "@${end_time}" '+%Y-%m-%d %H:%M:%S')"
  info "${step_name} duration: $((end_time - start_time)) seconds"
}

export CLUSTER_NAME NAMESPACE_MONITORING NAMESPACE_DEMO KIND_NODE_IMAGE
export -f info warn error wait_pods get_lb_ip get_lb_host get_service_port format_url
export -f helm_release_exists helm_release_pod_status step_timer
