#!/usr/bin/env bash

source "$(dirname "$0")/common.sh"

print_component_status() {
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

info "===== OBSERVABILITY STACK ACCESS URLS ====="
info ""

GRAFANA_HOST=$(get_lb_host "lgtm-grafana" "${NAMESPACE_MONITORING}")
GRAFANA_PORT=$(get_service_port "lgtm-grafana" "${NAMESPACE_MONITORING}")
GRAFANA_URL=$(format_url "http" "${GRAFANA_HOST}" "${GRAFANA_PORT}")

if [ -n "${GRAFANA_URL}" ]; then
  info "✓ Grafana:"
  info "  URL:      ${GRAFANA_URL}"
  info "  Username: admin"
  info "  Password: admin"
  info "  Datasources:"
  info "    - Prometheus (metrics)"
  info "    - Loki (logs)"
  info "    - Tempo (traces)"
else
  warn "✗ Grafana LoadBalancer host not yet assigned"
  warn "  Run 'make step-10' to wait for assignment"
fi

info ""

DEMO_HOST=$(get_lb_host "otel-demo-frontendproxy" "${NAMESPACE_DEMO}")
DEMO_PORT=$(get_service_port "otel-demo-frontendproxy" "${NAMESPACE_DEMO}")
DEMO_URL=$(format_url "http" "${DEMO_HOST}" "${DEMO_PORT}")

if [ -n "${DEMO_URL}" ]; then
  info "✓ OpenTelemetry Demo App:"
  info "  URL:       ${DEMO_URL}"
  info "  Endpoints:"
  info "    - /               (Frontend shopping app)"
  info "    - /api/products   (Product catalog)"
  info "    - /api/cart       (Shopping cart)"
  info "    - /api/checkout   (Checkout service)"
else
  warn "✗ Demo App LoadBalancer host not yet assigned"
  warn "  Run 'make step-10' to wait for assignment"
fi

info ""
info "===== COMPONENT STATUS ====="
info ""

print_component_status "Grafana" "lgtm-grafana" "${NAMESPACE_MONITORING}"
print_component_status "Tempo" "lgtm-tempo" "${NAMESPACE_MONITORING}"
print_component_status "Mimir" "lgtm-mimir" "${NAMESPACE_MONITORING}"
print_component_status "Loki" "lgtm-loki" "${NAMESPACE_MONITORING}"
print_component_status "OpenTelemetry Collector" "otel-collector" "${NAMESPACE_MONITORING}"
print_component_status "Demo App" "otel-demo" "${NAMESPACE_DEMO}"

info ""
info "===== QUICK LINKS ====="
info ""
info "Open Grafana dashboard:"
if [ -n "${GRAFANA_URL}" ]; then
  info "  open ${GRAFANA_URL}"
else
  info "  (Run 'make step-10' first to get URL)"
fi

info ""
info "Open Demo App:"
if [ -n "${DEMO_URL}" ]; then
  info "  open ${DEMO_URL}"
else
  info "  (Run 'make step-10' first to get URL)"
fi

info ""
info "View logs from components:"
info "  kubectl logs -n monitoring -l app.kubernetes.io/instance=lgtm-grafana"
info "  kubectl logs -n monitoring -l app.kubernetes.io/instance=otel-collector"
info "  kubectl logs -n otel-demo -l app.kubernetes.io/instance=otel-demo"

info ""
