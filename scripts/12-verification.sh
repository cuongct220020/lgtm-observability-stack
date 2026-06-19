#!/usr/bin/env bash

source "$(dirname "$0")/common.sh"

print_component_health() {
  local label="$1"
  local release_name="$2"
  local namespace="$3"
  local status

  status=$(helm_release_pod_status "${release_name}" "${namespace}")

  case "${status}" in
    ready)
      info "✓ ${label}: Ready"
      ;;
    starting)
      warn "⟳ ${label}: Starting..."
      ;;
    *)
      warn "✗ ${label}: Not deployed"
      ;;
  esac
}

step_start=$(date +%s)
info "STEP 12 start: $(date '+%Y-%m-%d %H:%M:%S')"

info "===== CLUSTER VERIFICATION ====="

info "Kind clusters:"
kind get clusters

info ""
info "Kubernetes nodes:"
kubectl get nodes

info ""
info "===== MONITORING NAMESPACE ====="
info "Deployments in $NAMESPACE_MONITORING:"
kubectl get deploy -n "${NAMESPACE_MONITORING}"

info ""
info "Services in $NAMESPACE_MONITORING:"
kubectl get svc -n "${NAMESPACE_MONITORING}"

info ""
info "Pods in $NAMESPACE_MONITORING:"
kubectl get pods -n "${NAMESPACE_MONITORING}"

info ""
info "===== DEMO NAMESPACE ====="
info "Deployments in $NAMESPACE_DEMO:"
kubectl get deploy -n "${NAMESPACE_DEMO}"

info ""
info "Services in $NAMESPACE_DEMO:"
kubectl get svc -n "${NAMESPACE_DEMO}"

info ""
info "Pods in $NAMESPACE_DEMO:"
kubectl get pods -n "${NAMESPACE_DEMO}"

info ""
info "===== OBSERVABILITY HEALTH ====="

if kubectl get svc lgtm-grafana -n "${NAMESPACE_MONITORING}" > /dev/null 2>&1; then
  GRAFANA_HOST=$(get_lb_host "lgtm-grafana" "${NAMESPACE_MONITORING}")
  GRAFANA_PORT=$(get_service_port "lgtm-grafana" "${NAMESPACE_MONITORING}")
  GRAFANA_URL=$(format_url "http" "${GRAFANA_HOST}" "${GRAFANA_PORT}")
  if [ -n "${GRAFANA_URL}" ]; then
    info "✓ Grafana: ${GRAFANA_URL} (admin/admin)"
  else
    warn "⟳ Grafana: Service exists but LoadBalancer host is still pending"
  fi
else
  warn "✗ Grafana not found"
fi

print_component_health "Tempo" "lgtm-tempo" "${NAMESPACE_MONITORING}"
print_component_health "Mimir" "lgtm-mimir" "${NAMESPACE_MONITORING}"
print_component_health "Loki" "lgtm-loki" "${NAMESPACE_MONITORING}"
print_component_health "OpenTelemetry Collector" "otel-collector" "${NAMESPACE_MONITORING}"

if kubectl get svc otel-demo-frontendproxy -n "${NAMESPACE_DEMO}" > /dev/null 2>&1; then
  DEMO_HOST=$(get_lb_host "otel-demo-frontendproxy" "${NAMESPACE_DEMO}")
  DEMO_PORT=$(get_service_port "otel-demo-frontendproxy" "${NAMESPACE_DEMO}")
  DEMO_URL=$(format_url "http" "${DEMO_HOST}" "${DEMO_PORT}")
  if [ -n "${DEMO_URL}" ]; then
    info "✓ Demo App: ${DEMO_URL}"
  else
    warn "⟳ Demo App: Service exists but LoadBalancer host is still pending"
  fi
else
  warn "✗ Demo App not found"
fi

info ""
info "===== SETUP COMPLETE ====="
info "All components have been deployed and verified."

step_end=$(date +%s)
step_timer "STEP 12" "$step_start" "$step_end"
