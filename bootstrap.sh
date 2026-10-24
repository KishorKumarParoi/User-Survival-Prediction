#!/usr/bin/env bash
# ==============================================================================
# 🚀 ZERO-TOUCH 1-COMMAND AUTO-BOOTSTRAPPER FOR EC2 & CLOUD VMS
# USER SURVIVAL PREDICTION & MLOPS INFRASTRUCTURE PLATFORM
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/KishorKumarParoi/User-Survival-Prediction/main/bootstrap.sh | bash
# Or with options:
#   curl -fsSL https://raw.githubusercontent.com/KishorKumarParoi/User-Survival-Prediction/main/bootstrap.sh | bash -s -- --quick
#   curl -fsSL https://raw.githubusercontent.com/KishorKumarParoi/User-Survival-Prediction/main/bootstrap.sh | bash -s -- --host
# ==============================================================================

set -eo pipefail

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
cat << "EOF"
================================================================================
   🚢 USER SURVIVAL PREDICTION & MLOPS PLATFORM
   Zero-Touch Instant Cloud & EC2 Bootstrapper
================================================================================
EOF
echo -e "${NC}"

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

run_sudo() {
  if [ "$EUID" -eq 0 ]; then
    "$@"
  elif command -v sudo &>/dev/null; then
    sudo -E "$@"
  else
    "$@"
  fi
}

# 1. Install Git & Curl
echo -e "${CYAN}[1/5] Detecting OS and ensuring Git & Curl are available...${NC}"
if ! command -v git &>/dev/null || ! command -v curl &>/dev/null; then
  if [ -f /etc/debian_version ]; then
    run_sudo apt-get update -qq && run_sudo apt-get install -y -qq git curl ca-certificates build-essential >/dev/null 2>&1
  elif [ -f /etc/amazon-linux-release ] || [ -f /etc/redhat-release ]; then
    run_sudo yum install -y -q git curl ca-certificates tar gzip >/dev/null 2>&1 || true
  fi
fi

# 2. Memory & OOM Protection
echo -e "\n${CYAN}[2/5] Checking System Memory & OOM Protection...${NC}"
if command -v free &>/dev/null; then
  TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
  EXISTING_SWAP_MB=$(free -m | awk '/^Swap:/{print $2}')
  if [ "$TOTAL_RAM_MB" -lt 4000 ] && [ "$EXISTING_SWAP_MB" -lt 1000 ]; then
    echo -e "${YELLOW}[!] Host RAM < 4GB (${TOTAL_RAM_MB}MB). Creating 4GB swapfile for compilation & Docker stability...${NC}"
    if [ ! -f /swapfile ]; then
      run_sudo fallocate -l 4G /swapfile 2>/dev/null || run_sudo dd if=/dev/zero of=/swapfile bs=1M count=4096 2>/dev/null
      run_sudo chmod 600 /swapfile
      run_sudo mkswap /swapfile >/dev/null 2>&1
      run_sudo swapon /swapfile 2>/dev/null || true
    fi
  fi
fi

# 3. Docker Engine & Compose Verification
echo -e "\n${CYAN}[3/5] Verifying Docker Engine & Container Daemon...${NC}"
if ! command -v docker &>/dev/null; then
  echo -e "${YELLOW}[+] Installing Docker Engine via official automated script...${NC}"
  curl -fsSL https://get.docker.com | run_sudo sh
  run_sudo systemctl enable --now docker 2>/dev/null || run_sudo service docker start 2>/dev/null || true
  if [ -n "$SUDO_USER" ]; then
    run_sudo usermod -aG docker "$SUDO_USER" 2>/dev/null || true
  fi
fi

# 4. Clone or Update Repository
REPO_DIR="User-Survival-Prediction"
REPO_URL="https://github.com/KishorKumarParoi/User-Survival-Prediction.git"

echo -e "\n${CYAN}[4/5] Downloading Application Codebase (shallow depth=1)...${NC}"
if [ -d "$REPO_DIR/.git" ]; then
  cd "$REPO_DIR"
  git pull origin main 2>/dev/null || true
else
  git clone --depth 1 "$REPO_URL" "$REPO_DIR"
  cd "$REPO_DIR"
fi

# 5. Hand-off to deploy.sh
echo -e "\n${CYAN}[5/5] Executing Production Deployment Launcher...${NC}"
chmod +x deploy.sh clear.sh 2>/dev/null || true
exec ./deploy.sh "$@"
