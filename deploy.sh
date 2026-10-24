#!/usr/bin/env bash
# ==============================================================================
# 🚀 USER SURVIVAL PREDICTION & MLOPS INFRASTRUCTURE DEPLOYMENT LAUNCHER
# Supported Flags:
#   ./deploy.sh            # Standard Docker Compose Deployment (Redis, App, Prometheus, Grafana)
#   ./deploy.sh --quick    # Lightweight Single-Container Deployment (Host / App Only)
#   ./deploy.sh --host     # Native Host Execution using uv/python
# ==============================================================================

set -eo pipefail

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

MODE="compose"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --quick) MODE="quick"; shift ;;
    --host) MODE="host"; shift ;;
    --compose) MODE="compose"; shift ;;
    *) echo -e "${YELLOW}Unknown flag $1; continuing in default compose mode.${NC}"; shift ;;
  esac
done

echo -e "${CYAN}${BOLD}"
cat << "EOF"
================================================================================
  🚢 USER SURVIVAL PREDICTION & MLOPS PLATFORM DEPLOYMENT
================================================================================
EOF
echo -e "${NC}"

run_compose() {
  if docker compose version &>/dev/null; then
    docker compose "$@"
  elif command -v docker-compose &>/dev/null; then
    docker-compose "$@"
  elif sudo docker compose version &>/dev/null; then
    sudo docker compose "$@"
  else
    sudo docker-compose "$@"
  fi
}

# 1. Native Host Execution
if [ "$MODE" = "host" ]; then
  echo -e "${YELLOW}[*] Launching in Host Python Mode...${NC}"
  export PORT="${PORT:-5001}"
  export PROMETHEUS_PORT="${PROMETHEUS_PORT:-8001}"
  export REDIS_HOST="${REDIS_HOST:-127.0.0.1}"
  export REDIS_PORT="${REDIS_PORT:-6379}"

  if command -v uv &>/dev/null; then
    echo -e "${GREEN}[✓] Using fast Python manager (uv)...${NC}"
    uv run python main.py
  elif command -v python3 &>/dev/null; then
    python3 main.py
  else
    python main.py
  fi
  exit 0
fi

# 2. Quick Single-Container Mode
if [ "$MODE" = "quick" ]; then
  echo -e "${YELLOW}[*] Deploying Lightweight Single-Container Mode (:5001)...${NC}"
  docker rm -f survival-web >/dev/null 2>&1 || true
  docker build -t kishorkumarparoi/user-survival-prediction:latest .
  docker run -d --name survival-web \
    --restart unless-stopped \
    -p 5001:5001 \
    -p 8001:8001 \
    kishorkumarparoi/user-survival-prediction:latest
else
  # 3. Standard Multi-Container Stack (Redis + App + Prometheus + Grafana)
  echo -e "${YELLOW}[*] Deploying Full MLOps Stack via Docker Compose...${NC}"
  run_compose down --remove-orphans >/dev/null 2>&1 || true
  run_compose up -d --build
fi

# 4. Readiness Health Probe
echo -e "\n${CYAN}[*] Awaiting Service Health Readiness (http://127.0.0.1:5001/health)...${NC}"
READY=false
for i in {1..30}; do
  if curl -sf http://127.0.0.1:5001/health >/dev/null 2>&1 || curl -sf http://localhost:5001/health >/dev/null 2>&1; then
    READY=true
    break
  fi
  sleep 2
done

PUBLIC_IP=$(curl -s -4 --max-time 2 ifconfig.me 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1")

echo -e "\n${GREEN}${BOLD}================================================================================${NC}"
if [ "$READY" = "true" ]; then
  echo -e "${GREEN}${BOLD} ✅ USER SURVIVAL PREDICTION & MLOPS PLATFORM IS LIVE & READY!${NC}"
else
  echo -e "${YELLOW}${BOLD} ⚠️  Containers launched. Waiting for complete background initialization.${NC}"
fi
echo -e "${GREEN}${BOLD}================================================================================${NC}"
echo -e "  🌐 ${BOLD}Interactive Web UI:${NC}    http://${PUBLIC_IP}:5001"
echo -e "  🔍 ${BOLD}REST Health API:${NC}       http://${PUBLIC_IP}:5001/health"
echo -e "  📊 ${BOLD}Prometheus Metrics:${NC}    http://${PUBLIC_IP}:9090 (Alt Exporter: :8001)"
echo -e "  📈 ${BOLD}Grafana AI Dashboard:${NC}  http://${PUBLIC_IP}:3000 (admin / admin)"
echo -e "  ⚡ ${BOLD}Redis Feature Store:${NC}   redis://${PUBLIC_IP}:6379"
echo -e "  🛑 ${BOLD}Teardown Command:${NC}      ./clear.sh"
echo -e "${GREEN}================================================================================${NC}\n"
