#!/usr/bin/env bash

source "$(dirname "$0")/common.sh"

step_start=$(date +%s)
info "STEP 11 start: $(date '+%Y-%m-%d %H:%M:%S')"

info "Waiting for frontend service to stabilize..."
wait_pods "default" "app=otel-demo-frontendproxy" 120

# Get demo app IP
DEMO_IP=$(kubectl get svc otel-demo-frontendproxy -n "${NAMESPACE_DEMO}" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ -z "$DEMO_IP" ]; then
  warn "Could not obtain demo app LoadBalancer IP; skipping traffic generation"
  step_end=$(date +%s)
  step_timer "STEP 11" "$step_start" "$step_end"
  exit 0
fi

DEMO_URL="http://$DEMO_IP:8080"
info "Generating traffic to $DEMO_URL..."

ITERATIONS=60
for i in $(seq 1 "$ITERATIONS"); do
  curl -s "$DEMO_URL" > /dev/null 2>&1 || true
  curl -s "$DEMO_URL/api/products" > /dev/null 2>&1 || true
  curl -s "$DEMO_URL/api/cart" > /dev/null 2>&1 || true
  curl -s "$DEMO_URL/api/checkout" > /dev/null 2>&1 || true
  
  if [ $((i % 10)) -eq 0 ]; then
    info "Traffic generation: $i/$ITERATIONS requests sent"
  fi
  
  sleep 1
done

info "Traffic generation complete: $ITERATIONS iterations"

step_end=$(date +%s)
step_timer "STEP 11" "$step_start" "$step_end"
