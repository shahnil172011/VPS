#!/usr/bin/env bash
#
# verify.sh - Checks that the VPS is correctly configured.
#
set -uo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

FAILED=0

check_cmd() {
  local name="$1"
  local cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    local out
    out=$($cmd --version 2>&1 | head -n1)
    echo -e "${GREEN}[OK]${NC} $name: $out"
  else
    echo -e "${RED}[MISSING]${NC} $name"
    FAILED=$((FAILED + 1))
  fi
}

check_cmd "Git"      "git"
check_cmd "Python"   "python3"
check_cmd "Node.js"  "node"
check_cmd "npm"      "npm"

if command -v docker >/dev/null 2>&1; then
  check_cmd "Docker" "docker"
fi

if command -v tailscale >/dev/null 2>&1; then
  echo -e "${GREEN}[OK]${NC} Tailscale installed"
  if tailscale status >/dev/null 2>&1; then
    TS_IP=$(tailscale ip -4 2>/dev/null || echo "")
    if [ -n "$TS_IP" ]; then
      echo -e "${GREEN}[OK]${NC} Tailscale connected — IP: $TS_IP"
    else
      echo -e "${YELLOW}[WARN]${NC} Tailscale running but no IPv4 assigned"
    fi
  else
    echo -e "${YELLOW}[WARN]${NC} Tailscale not connected"
  fi
else
  echo -e "${RED}[MISSING]${NC} Tailscale"
  FAILED=$((FAILED + 1))
fi

if command -v sshd >/dev/null 2>&1 || systemctl is-active ssh >/dev/null 2>&1; then
  echo -e "${GREEN}[OK]${NC} SSH server active"
else
  echo -e "${RED}[MISSING]${NC} SSH server"
  FAILED=$((FAILED + 1))
fi

if [ "$FAILED" -gt 0 ]; then
  echo -e "${RED}$FAILED check(s) need attention.${NC}"
  exit 1
fi

echo -e "${GREEN}All VPS checks passed.${NC}"