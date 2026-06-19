#!/usr/bin/env bash

source "$(dirname "$0")/common.sh"

step_start=$(date +%s)
info "STEP 10 start: $(date '+%Y-%m-%d %H:%M:%S')"

info "Waiting for LoadBalancer IPs to be assigned..."

GRAFANA_HOST=""
GRAFANA_PORT=""
DEMO_HOST=""
DEMO_PORT=""
MAX_ATTEMPTS=30
ATTEMPT=0
SLEEP_INTERVAL=10

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  ATTEMPT=$((ATTEMPT + 1))

  if [ -z "${GRAFANA_HOST}" ]; then
    GRAFANA_HOST=$(get_lb_host "lgtm-grafana" "${NAMESPACE_MONITORING}")
    GRAFANA_PORT=$(get_service_port "lgtm-grafana" "${NAMESPACE_MONITORING}")
    [ -n "${GRAFANA_HOST}" ] && info "Grafana LoadBalancer host: ${GRAFANA_HOST}"
  fi

  if [ -z "${DEMO_HOST}" ]; then
    DEMO_HOST=$(get_lb_host "otel-demo-frontendproxy" "${NAMESPACE_DEMO}")
    DEMO_PORT=$(get_service_port "otel-demo-frontendproxy" "${NAMESPACE_DEMO}")
    [ -n "${DEMO_HOST}" ] && info "Demo app LoadBalancer host: ${DEMO_HOST}"
  fi

  if [ -n "${GRAFANA_HOST}" ] && [ -n "${DEMO_HOST}" ]; then
    info "Both LoadBalancer hosts assigned!"
    break
  fi

  if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
    info "Attempt $ATTEMPT/$MAX_ATTEMPTS: Waiting for hosts... (${SLEEP_INTERVAL}s)"
    sleep "${SLEEP_INTERVAL}"
  fi
done

if [ -z "${GRAFANA_HOST}" ] || [ -z "${DEMO_HOST}" ]; then
  warn "Could not obtain all LoadBalancer hosts after $((ATTEMPT * SLEEP_INTERVAL)) seconds"
  [ -n "${GRAFANA_HOST}" ] && info "Grafana host: ${GRAFANA_HOST}"
  [ -n "${DEMO_HOST}" ] && info "Demo host: ${DEMO_HOST}"
else
  GRAFANA_URL=$(format_url "http" "${GRAFANA_HOST}" "${GRAFANA_PORT}")
  DEMO_URL=$(format_url "http" "${DEMO_HOST}" "${DEMO_PORT}")
  info "All LoadBalancer hosts ready:"
  info "  - Grafana: ${GRAFANA_URL}"
  info "  - Demo App: ${DEMO_URL}"
fi

step_end=$(date +%s)
step_timer "STEP 10" "$step_start" "$step_end"
