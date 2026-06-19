.PHONY: help setup clean logs status verify urls step-1 step-2 step-3 step-4 step-5 step-6 step-7 step-8 step-9 step-10 step-11 step-12

SCRIPTS_DIR := scripts

help:
	@echo "Observability Stack - Makefile"
	@echo ""
	@echo "Setup and Management:"
	@echo "  make setup          - Run full setup (steps 1-12)"
	@echo "  make clean          - Delete kind cluster and stop cloud-provider-kind"
	@echo "  make verify         - Run verification checks (step 12)"
	@echo ""
	@echo "Access & Information:"
	@echo "  make urls           - Get UI access URLs and component status"
	@echo ""
	@echo "Individual Steps:"
	@echo "  make step-1         - Create kind cluster"
	@echo "  make step-2         - Label control plane nodes"
	@echo "  make step-3         - Install cloud-provider-kind"
	@echo "  make step-4         - Add Helm repositories"
	@echo "  make step-5         - Deploy Prometheus stack"
	@echo "  make step-6         - Deploy LGTM stack (Loki, Grafana, Tempo, Mimir)"
	@echo "  make step-7         - Deploy OpenTelemetry Collector"
	@echo "  make step-8         - Deploy OpenTelemetry Demo App"
	@echo "  make step-9         - Create Grafana dashboard"
	@echo "  make step-10        - Wait for LoadBalancer IPs"
	@echo "  make step-11        - Generate synthetic traffic"
	@echo "  make step-12        - Run verification (same as 'make verify')"
	@echo ""
	@echo "Debugging:"
	@echo "  make logs           - Show cloud-provider-kind logs"
	@echo "  make status         - Show cluster and resource status"
	@echo ""

setup: step-1 step-2 step-3 step-4 step-5 step-6 step-7 step-8 step-9 step-10 step-11 step-12
	@echo ""
	@echo "Setup complete! All 12 steps executed."

step-1:
	@$(SCRIPTS_DIR)/01-create-cluster.sh

step-2:
	@$(SCRIPTS_DIR)/02-label-control-plane.sh

step-3:
	@$(SCRIPTS_DIR)/03-cloud-provider-kind.sh

step-4:
	@$(SCRIPTS_DIR)/04-helm-repos.sh

step-5:
	@$(SCRIPTS_DIR)/05-prometheus-stack.sh

step-6:
	@$(SCRIPTS_DIR)/06-lgtm-stack.sh

step-7:
	@$(SCRIPTS_DIR)/07-otel-collector.sh

step-8:
	@$(SCRIPTS_DIR)/08-otel-demo.sh

step-9:
	@$(SCRIPTS_DIR)/09-grafana-dashboard.sh

step-10:
	@$(SCRIPTS_DIR)/10-loadbalancer-ips.sh

step-11:
	@$(SCRIPTS_DIR)/11-traffic-generation.sh

step-12: verify

verify:
	@$(SCRIPTS_DIR)/12-verification.sh

urls:
	@$(SCRIPTS_DIR)/get-urls.sh

status:
	@echo "===== Kind Clusters ====="
	@kind get clusters || echo "No clusters found"
	@echo ""
	@echo "===== Kubernetes Nodes ====="
	@kubectl get nodes 2>/dev/null || echo "No nodes (cluster not running?)"
	@echo ""
	@echo "===== Monitoring Namespace ====="
	@kubectl get all -n monitoring 2>/dev/null || echo "Monitoring namespace not found"
	@echo ""
	@echo "===== Demo Namespace ====="
	@kubectl get all -n otel-demo 2>/dev/null || echo "Demo namespace not found"

logs:
	@echo "===== cloud-provider-kind logs ====="
	@if [ -f /tmp/cloud-provider-kind.log ]; then tail -50 /tmp/cloud-provider-kind.log; else echo "Log file not found: /tmp/cloud-provider-kind.log"; fi
	@echo ""
	@echo "===== Running cloud-provider-kind processes ====="
	@pgrep -af cloud-provider-kind || echo "No cloud-provider-kind processes running"

clean:
	@echo "Cleaning up..."
	@echo "Stopping cloud-provider-kind..."
	@pids=$$(pgrep -af cloud-provider-kind | grep -v 'make clean' | grep -v 'pkill' | awk '{print $$1}' || true); \
	if [ -n "$$pids" ]; then \
		echo "$$pids" | xargs kill; \
	else \
		echo "No cloud-provider-kind process to stop"; \
	fi
	@echo "Deleting kind cluster..."
	@kind delete cluster --name observability || echo "No cluster to delete"
	@echo "Cleanup complete!"

.PHONY: help setup clean logs status verify urls step-1 step-2 step-3 step-4 step-5 step-6 step-7 step-8 step-9 step-10 step-11 step-12
