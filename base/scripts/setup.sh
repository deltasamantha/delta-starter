#!/usr/bin/env bash
# =============================================================================
# __DISPLAY_NAME__ Monorepo — Master Setup Script
# =============================================================================
# Usage:
#   chmod +x scripts/setup.sh
#   ./scripts/setup.sh
#
# This script:
#   1. Checks prerequisites (Node.js, pnpm, git, Docker)
#   2. Installs all dependencies
#   3. Sets up environment files
#   4. Starts and seeds the database
#   5. Generates Prisma client
#   6. Verifies everything works
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Colors & Helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info()    { echo -e "${BLUE}ℹ ${NC} $1"; }
success() { echo -e "${GREEN}✔ ${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠ ${NC} $1"; }
error()   { echo -e "${RED}✖ ${NC} $1"; }
header()  { echo -e "\n${BOLD}${CYAN}━━━ $1 ━━━${NC}\n"; }

# ---------------------------------------------------------------------------
# 1. Prerequisites Check
# ---------------------------------------------------------------------------
header "1/7 — Checking Prerequisites"

MISSING_DEPS=()

# Node.js >= 22
if command -v node &> /dev/null; then
  NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
  if [ "$NODE_VERSION" -ge 22 ]; then
    success "Node.js $(node -v) detected"
  else
    error "Node.js >= 22 required (found $(node -v))"
    MISSING_DEPS+=("node")
  fi
else
  error "Node.js not found"
  MISSING_DEPS+=("node")
fi

# pnpm >= 9
if command -v pnpm &> /dev/null; then
  PNPM_VERSION=$(pnpm -v | cut -d. -f1)
  if [ "$PNPM_VERSION" -ge 9 ]; then
    success "pnpm $(pnpm -v) detected"
  else
    warn "pnpm >= 9 recommended (found $(pnpm -v)). Attempting upgrade..."
    corepack enable
    corepack prepare pnpm@latest --activate
  fi
else
  warn "pnpm not found — installing via corepack"
  if command -v corepack &> /dev/null; then
    corepack enable
    corepack prepare pnpm@latest --activate
    success "pnpm installed via corepack"
  else
    error "pnpm not found and corepack unavailable"
    echo "  Install pnpm: https://pnpm.io/installation"
    MISSING_DEPS+=("pnpm")
  fi
fi

# Git
if command -v git &> /dev/null; then
  success "git $(git --version | awk '{print $3}') detected"
else
  warn "git not found — version control will not be initialized"
fi

# Docker (optional — for database)
if command -v docker &> /dev/null; then
  success "Docker $(docker --version | awk '{print $3}' | tr -d ',') detected"
  DOCKER_AVAILABLE=true
else
  warn "Docker not found — you'll need PostgreSQL running locally"
  DOCKER_AVAILABLE=false
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
  echo ""
  error "Missing required dependencies: ${MISSING_DEPS[*]}"
  echo ""
  echo "  Install Node.js 22+: https://nodejs.org or use nvm/fnm"
  echo "  Install pnpm:        corepack enable && corepack prepare pnpm@latest --activate"
  echo ""
  exit 1
fi

# ---------------------------------------------------------------------------
# 2. Git Initialization
# ---------------------------------------------------------------------------
header "2/7 — Initializing Git Repository"

if [ -d ".git" ]; then
  success "Git repository already initialized"
else
  if command -v git &> /dev/null; then
    git init
    success "Git repository initialized"
  else
    warn "Skipping git init (git not available)"
  fi
fi

# ---------------------------------------------------------------------------
# 3. Environment Files
# ---------------------------------------------------------------------------
header "3/7 — Setting Up Environment Files"

setup_env() {
  local src="$1"
  local dest="$2"
  local name="$3"

  if [ -f "$dest" ]; then
    warn "$name .env already exists — skipping (won't overwrite)"
  else
    cp "$src" "$dest"
    success "$name .env created from template"
  fi
}

setup_env "apps/api/.env.example"    "apps/api/.env"    "API"
setup_env "apps/web/.env.example"    "apps/web/.env"    "Web"
setup_env "apps/mobile/.env.example" "apps/mobile/.env" "Mobile"

# Generate a random JWT secret for API
if [ -f "apps/api/.env" ]; then
  if grep -q "change-this-to-a-secure-random-string" "apps/api/.env"; then
    JWT_SECRET=$(openssl rand -base64 48 2>/dev/null || head -c 48 /dev/urandom | base64)
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s|change-this-to-a-secure-random-string|$JWT_SECRET|g" apps/api/.env
    else
      sed -i "s|change-this-to-a-secure-random-string|$JWT_SECRET|g" apps/api/.env
    fi
    success "Generated random JWT_SECRET"
  fi
fi

# ---------------------------------------------------------------------------
# 4. Database Setup
# ---------------------------------------------------------------------------
header "4/7 — Setting Up Database"

DB_READY=false

if [ "$DOCKER_AVAILABLE" = true ]; then
  # Check if our container already exists
  if docker ps -a --format '{{.Names}}' | grep -q "__SLUG__-postgres"; then
    if docker ps --format '{{.Names}}' | grep -q "__SLUG__-postgres"; then
      success "PostgreSQL container already running"
      DB_READY=true
    else
      info "Starting existing PostgreSQL container..."
      docker start __SLUG__-postgres
      sleep 3
      success "PostgreSQL container started"
      DB_READY=true
    fi
  else
    info "Creating PostgreSQL container..."
    docker run -d \
      --name __SLUG__-postgres \
      -e POSTGRES_USER=postgres \
      -e POSTGRES_PASSWORD=postgres \
      -e POSTGRES_DB=__SLUG___dev \
      -p 5432:5432 \
      -v __SLUG___pgdata:/var/lib/postgresql/data \
      postgres:16-alpine

    info "Waiting for PostgreSQL to be ready..."
    sleep 5

    # Wait up to 30 seconds for PostgreSQL to accept connections
    for i in $(seq 1 15); do
      if docker exec __SLUG__-postgres pg_isready -U postgres &> /dev/null; then
        success "PostgreSQL is ready"
        DB_READY=true
        break
      fi
      sleep 2
    done

    if [ "$DB_READY" = false ]; then
      warn "PostgreSQL might not be ready yet — try again in a few seconds"
    fi
  fi
else
  # Check if PostgreSQL is running locally
  if command -v pg_isready &> /dev/null && pg_isready -q 2>/dev/null; then
    success "Local PostgreSQL detected and ready"
    DB_READY=true
  else
    warn "No PostgreSQL detected. Please start PostgreSQL manually."
    echo "  Option A: Install Docker and re-run this script"
    echo "  Option B: Install PostgreSQL locally"
    echo "  Option C: Update apps/api/.env with your database URL"
    echo ""
    echo "  Expected DATABASE_URL: postgresql://postgres:postgres@localhost:5432/__SLUG___dev"
  fi
fi

# ---------------------------------------------------------------------------
# 5. Install Dependencies
# ---------------------------------------------------------------------------
header "5/7 — Installing Dependencies"

info "Running pnpm install (this may take a minute on first run)..."
pnpm install

success "All dependencies installed"

# ---------------------------------------------------------------------------
# 6. Prisma Setup
# ---------------------------------------------------------------------------
header "6/7 — Setting Up Prisma"

if [ "$DB_READY" = true ]; then
  info "Generating Prisma client..."
  pnpm --filter __SCOPE__/api db:generate
  success "Prisma client generated"

  info "Pushing schema to database..."
  pnpm --filter __SCOPE__/api db:push
  success "Database schema synced"
else
  warn "Skipping Prisma setup — database not available"
  echo "  Run these manually once your database is ready:"
  echo "    pnpm --filter __SCOPE__/api db:generate"
  echo "    pnpm --filter __SCOPE__/api db:push"
fi

# ---------------------------------------------------------------------------
# 7. Verification
# ---------------------------------------------------------------------------
header "7/7 — Verifying Setup"

CHECKS_PASSED=0
CHECKS_TOTAL=0

verify() {
  local name="$1"
  local cmd="$2"
  CHECKS_TOTAL=$((CHECKS_TOTAL + 1))

  if eval "$cmd" &> /dev/null; then
    success "$name"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    warn "$name — may need attention"
  fi
}

verify "Root package.json exists"          "[ -f package.json ]"
verify "pnpm-workspace.yaml exists"        "[ -f pnpm-workspace.yaml ]"
verify "turbo.json exists"                 "[ -f turbo.json ]"
verify "API .env exists"                   "[ -f apps/api/.env ]"
verify "Web .env exists"                   "[ -f apps/web/.env ]"
verify "Mobile .env exists"               "[ -f apps/mobile/.env ]"
verify "node_modules installed"           "[ -d node_modules ]"
verify "API node_modules"                 "[ -d apps/api/node_modules ] || [ -d node_modules/.pnpm ]"
verify "Web node_modules"                 "[ -d apps/web/node_modules ] || [ -d node_modules/.pnpm ]"
verify "Shared package exists"            "[ -f packages/shared/src/index.ts ]"
verify "Tokens package exists"            "[ -f packages/tokens/src/tamagui.config.ts ]"
verify "UI package exists"                "[ -f packages/ui/src/index.ts ]"
verify "Business logic exists"            "[ -f packages/business-logic/src/index.ts ]"
verify "API client exists"                "[ -f packages/api-client/src/index.ts ]"
verify "Prisma schema exists"             "[ -f apps/api/src/prisma/schema.prisma ]"

# ---------------------------------------------------------------------------
# Done!
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${GREEN}  __DISPLAY_NAME__ Monorepo Setup Complete!${NC}"
echo -e "${BOLD}${GREEN}  $CHECKS_PASSED/$CHECKS_TOTAL checks passed${NC}"
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BOLD}Quick start:${NC}"
echo ""
echo -e "    ${CYAN}pnpm dev${NC}             Start all apps (API + Web + Mobile)"
echo -e "    ${CYAN}pnpm dev:api${NC}         Start API only"
echo -e "    ${CYAN}pnpm dev:web${NC}         Start Web only"
echo -e "    ${CYAN}pnpm dev:mobile${NC}      Start Mobile only"
echo ""
echo -e "  ${BOLD}Endpoints:${NC}"
echo ""
echo -e "    API:    ${CYAN}http://localhost:3001${NC}"
echo -e "    Web:    ${CYAN}http://localhost:3000${NC}"
echo -e "    Mobile: ${CYAN}Expo DevTools (scan QR)${NC}"
echo ""
echo -e "  ${BOLD}Useful commands:${NC}"
echo ""
echo -e "    ${CYAN}pnpm build${NC}           Build all packages"
echo -e "    ${CYAN}pnpm lint${NC}            Lint all packages"
echo -e "    ${CYAN}pnpm type-check${NC}      Type-check all packages"
echo -e "    ${CYAN}pnpm db:studio${NC}       Open Prisma Studio"
echo ""
