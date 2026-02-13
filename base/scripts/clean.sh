#!/usr/bin/env bash
# =============================================================================
# __DISPLAY_NAME__ — Clean Script
# =============================================================================
# Removes build artifacts, caches, and optionally node_modules
#
# Usage:
#   ./scripts/clean.sh          Clean build artifacts + caches
#   ./scripts/clean.sh --all    Also remove node_modules (full reset)
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}ℹ ${NC} $1"; }
success() { echo -e "${GREEN}✔ ${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠ ${NC} $1"; }

FULL_CLEAN=false
if [ "${1:-}" = "--all" ] || [ "${1:-}" = "-a" ]; then
  FULL_CLEAN=true
fi

echo -e "\n${BOLD}🧹 Cleaning __DISPLAY_NAME__ monorepo...${NC}\n"

# Build outputs
info "Removing build outputs..."
rm -rf apps/api/dist
rm -rf apps/web/.next
rm -rf apps/web/out
rm -rf apps/mobile/.expo
rm -rf packages/shared/dist
rm -rf packages/business-logic/dist
rm -rf packages/api-client/dist
rm -rf packages/tokens/dist
rm -rf packages/ui/dist
success "Build outputs removed"

# Turbo cache
info "Removing Turbo cache..."
rm -rf .turbo
rm -rf apps/api/.turbo
rm -rf apps/web/.turbo
rm -rf apps/mobile/.turbo
rm -rf packages/shared/.turbo
rm -rf packages/business-logic/.turbo
rm -rf packages/api-client/.turbo
rm -rf packages/tokens/.turbo
rm -rf packages/ui/.turbo
rm -rf packages/config/.turbo
success "Turbo cache removed"

# TypeScript build info
info "Removing TypeScript incremental build files..."
find . -name "*.tsbuildinfo" -not -path "*/node_modules/*" -delete 2>/dev/null || true
success "TypeScript build info removed"

# Next.js cache
info "Removing Next.js cache..."
rm -rf apps/web/.next/cache
success "Next.js cache removed"

# Prisma generated files
info "Removing Prisma generated client..."
rm -rf apps/api/src/prisma/generated
rm -rf apps/api/node_modules/.prisma
success "Prisma generated files removed"

# OS files
info "Removing OS-generated files..."
find . -name ".DS_Store" -delete 2>/dev/null || true
find . -name "Thumbs.db" -delete 2>/dev/null || true
success "OS files removed"

# Full clean: node_modules
if [ "$FULL_CLEAN" = true ]; then
  echo ""
  warn "Removing ALL node_modules (this will require pnpm install to restore)..."
  rm -rf node_modules
  rm -rf apps/api/node_modules
  rm -rf apps/web/node_modules
  rm -rf apps/mobile/node_modules
  rm -rf packages/shared/node_modules
  rm -rf packages/business-logic/node_modules
  rm -rf packages/api-client/node_modules
  rm -rf packages/tokens/node_modules
  rm -rf packages/ui/node_modules
  rm -rf packages/config/node_modules
  rm -rf .pnpm-store
  success "All node_modules removed"
  echo ""
  echo -e "  Run ${CYAN}pnpm install${NC} to restore dependencies"
fi

echo ""
success "Clean complete!"
echo ""
