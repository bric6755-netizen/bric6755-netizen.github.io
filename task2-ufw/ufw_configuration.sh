#!/usr/bin/env bash
# =============================================================================
# ufw_configuration.sh
# AICTE Oasis Infobyte Internship — Task 2: Basic Firewall Configuration
# Author : Richard Boakye Danquah
# Date   : June 2026
# Desc   : Installs UFW (if needed), applies a secure baseline ruleset,
#          and prints a final status report.
# =============================================================================

set -euo pipefail

# ── Colour helpers ──────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }

# ── Root check ───────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  error "This script must be run as root (sudo)."
  exit 1
fi

echo
echo -e "${BOLD}=====================================================${RESET}"
echo -e "${BOLD}  AICTE Oasis Infobyte — Task 2: UFW Firewall Setup  ${RESET}"
echo -e "${BOLD}=====================================================${RESET}"
echo

# ── Step 1 : Install UFW ─────────────────────────────────────────────────────
info "Step 1 — Installing UFW (if not already installed)..."
if ! command -v ufw &>/dev/null; then
  apt-get update -qq
  apt-get install -y ufw
  success "UFW installed."
else
  success "UFW is already installed ($(ufw version | head -1))."
fi

# ── Step 2 : Reset to clean state ────────────────────────────────────────────
info "Step 2 — Resetting UFW to a clean state..."
ufw --force reset
success "UFW reset complete."

# ── Step 3 : Default policies ────────────────────────────────────────────────
info "Step 3 — Setting default policies..."
ufw default deny incoming
ufw default allow outgoing
success "Default: DENY incoming, ALLOW outgoing."

# ── Step 4 : Allow SSH (port 22/tcp) ─────────────────────────────────────────
info "Step 4 — Allowing SSH (port 22/tcp)..."
ufw allow 22/tcp comment 'Allow SSH — remote management'
success "SSH (22/tcp) — ALLOWED."

# ── Step 5 : Deny HTTP (port 80/tcp) ─────────────────────────────────────────
info "Step 5 — Explicitly denying HTTP (port 80/tcp)..."
ufw deny 80/tcp comment 'Deny HTTP — unencrypted web traffic blocked'
success "HTTP (80/tcp) — DENIED."

# ── Step 6 : Deny HTTPS for completeness (optional — remove if web server needed)
info "Step 6 — Explicitly denying HTTPS (port 443/tcp)..."
ufw deny 443/tcp comment 'Deny HTTPS — no web server on this host'
success "HTTPS (443/tcp) — DENIED."

# ── Step 7 : Enable UFW ──────────────────────────────────────────────────────
info "Step 7 — Enabling UFW..."
ufw --force enable
success "UFW is now ACTIVE."

# ── Step 8 : Display final status ────────────────────────────────────────────
echo
echo -e "${BOLD}──────────────── UFW STATUS REPORT ────────────────${RESET}"
ufw status verbose
echo -e "${BOLD}────────────────────────────────────────────────────${RESET}"
echo

success "Firewall configuration complete."
echo -e "  ${GREEN}▸${RESET} SSH  (22/tcp)  → ${GREEN}ALLOWED${RESET}"
echo -e "  ${RED}▸${RESET} HTTP (80/tcp)  → ${RED}DENIED${RESET}"
echo -e "  ${RED}▸${RESET} HTTPS(443/tcp) → ${RED}DENIED${RESET}"
echo -e "  ${CYAN}▸${RESET} All other inbound traffic → ${CYAN}DENIED (default)${RESET}"
echo
