#!/usr/bin/env bash
# ==============================================================================
# 🧹 $0.00 ZERO-COST TEARDOWN SCRIPT
# USER SURVIVAL PREDICTION & MLOPS INFRASTRUCTURE PLATFORM
# ==============================================================================

set -eo pipefail

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

echo -e "${CYAN}${BOLD}[*] Initiating $0.00 Zero-Cost Teardown for User Survival Platform...${NC}"

# Stop compose stack
if docker compose version &>/dev/null; then
  docker compose down --remove-orphans -v 2>/dev/null || true
elif command -v docker-compose &>/dev/null; then
  docker-compose down --remove-orphans -v 2>/dev/null || true
elif command -v sudo &>/dev/null; then
  sudo docker compose down --remove-orphans -v 2>/dev/null || true
fi

# Stop any orphan standalone containers
docker rm -f survival-web survival-redis survival-prometheus survival-grafana >/dev/null 2>&1 || true

# Prune unused networks
docker network prune -f >/dev/null 2>&1 || true

echo -e "${GREEN}${BOLD}[✓] Teardown complete. All services stopped and $0.00 compute state restored.${NC}"
