#!/usr/bin/env bash
# =============================================================================
#
#   ██████╗ ███████╗██╗  ████████╗ █████╗
#   ██╔══██╗██╔════╝██║  ╚══██╔══╝██╔══██╗
#   ██║  ██║█████╗  ██║     ██║   ███████║
#   ██║  ██║██╔══╝  ██║     ██║   ██╔══██║
#   ██████╔╝███████╗███████╗██║   ██║  ██║
#   ╚═════╝ ╚══════╝╚══════╝╚═╝   ╚═╝  ╚═╝
#   S T A R T E R
#
#   Modular Fullstack Monorepo Generator
#   Assemble your stack: Next.js 16 · Expo · Express · Tamagui · Turborepo
#
# =============================================================================
#
#   Interactive:
#     ./create.sh
#
#   With flags (works via curl pipe):
#     curl -fsSL <URL>/create.sh | bash -s -- my-app --apps api,web,mobile
#
#   All flags:
#     ./create.sh <project-name> [options]
#       --apps <list>        Comma-separated: api,web,mobile (default: all)
#       --packages <list>    Comma-separated: shared,logic,client,ui,tokens (default: all)
#       --scope <scope>      npm scope (default: @<slug>)
#       --name <name>        Display name (default: PascalCase of slug)
#       --skip-install       Don't run pnpm install
#       --skip-git           Don't initialize git repo
#       --skip-db            Don't start database
#       --all                Select all apps and packages (no prompts)
#       -h, --help           Show this help
#
# =============================================================================

set -euo pipefail

VERSION="1.0.0"
REPO_URL="https://github.com/<USER>/delta-starter.git"
REPO_BRANCH="main"

# ─── Colors ─────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

info()    { echo -e "  ${BLUE}ℹ${NC}  $1"; }
success() { echo -e "  ${GREEN}✔${NC}  $1"; }
warn()    { echo -e "  ${YELLOW}⚠${NC}  $1"; }
error()   { echo -e "  ${RED}✖${NC}  $1"; }
fatal()   { error "$1"; exit 1; }
step()    { echo -e "\n${BOLD}${MAGENTA}  ▸ $1${NC}\n"; }

# ─── TTY detection (for interactive prompts via curl pipe) ──────
INPUT_TTY="/dev/tty"
IS_INTERACTIVE=false
if [ -t 0 ]; then
  IS_INTERACTIVE=true
  INPUT_TTY="/dev/stdin"
elif [ -e /dev/tty ]; then
  IS_INTERACTIVE=true
fi

prompt() {
  local var_name="$1" prompt_text="$2" default="${3:-}"
  if [ "$IS_INTERACTIVE" = true ]; then
    echo -en "  ${BOLD}${prompt_text}${NC}"
    if [ -n "$default" ]; then echo -en " ${DIM}(${default})${NC}"; fi
    echo -en ": "
    read -r REPLY < "$INPUT_TTY"
    if [ -z "$REPLY" ]; then REPLY="$default"; fi
    eval "$var_name=\"\$REPLY\""
  else
    eval "$var_name=\"\$default\""
  fi
}

# Multi-select checkbox prompt. Sets the named variable to comma-separated result.
# Usage: checkbox_prompt VAR_NAME "Question" "opt1:Label 1" "opt2:Label 2" ...
checkbox_prompt() {
  local var_name="$1"; shift
  local question="$1"; shift
  local -a options=("$@")
  local -a keys=() labels=() selected=()

  for opt in "${options[@]}"; do
    keys+=("${opt%%:*}")
    labels+=("${opt#*:}")
    selected+=(true)  # all selected by default
  done

  if [ "$IS_INTERACTIVE" = false ]; then
    # Non-interactive: select all
    eval "$var_name=\"$(IFS=,; echo "${keys[*]}")\""
    return
  fi

  echo -e "\n  ${BOLD}${question}${NC} ${DIM}(space to toggle, enter to confirm)${NC}\n"

  local cursor=0 count=${#keys[@]}

  # Hide cursor
  tput civis 2>/dev/null < "$INPUT_TTY" || true

  # Draw initial state
  for i in $(seq 0 $((count - 1))); do
    local check="◉" color="$GREEN"
    if [ "${selected[$i]}" = false ]; then check="○"; color="$DIM"; fi
    local pointer="  "
    if [ $i -eq $cursor ]; then pointer="❯ "; fi
    echo -e "  ${pointer}${color}${check}${NC} ${labels[$i]}" >&2
  done

  # Input loop
  while true; do
    read -rsn1 key < "$INPUT_TTY"

    # Handle arrow keys (escape sequences)
    if [[ "$key" == $'\x1b' ]]; then
      read -rsn2 -t 0.1 seq < "$INPUT_TTY" || true
      case "$seq" in
        '[A') cursor=$(( (cursor - 1 + count) % count )) ;; # Up
        '[B') cursor=$(( (cursor + 1) % count )) ;;         # Down
      esac
    elif [[ "$key" == " " ]]; then
      # Toggle selection
      if [ "${selected[$cursor]}" = true ]; then
        selected[$cursor]=false
      else
        selected[$cursor]=true
      fi
    elif [[ "$key" == "" ]]; then
      # Enter: confirm
      break
    fi

    # Redraw: move cursor up N lines then redraw
    for _ in $(seq 1 $count); do echo -en "\033[1A\033[2K" >&2; done

    for i in $(seq 0 $((count - 1))); do
      local check="◉" color="$GREEN"
      if [ "${selected[$i]}" = false ]; then check="○"; color="$DIM"; fi
      local pointer="  "
      if [ $i -eq $cursor ]; then pointer="❯ "; fi
      echo -e "  ${pointer}${color}${check}${NC} ${labels[$i]}" >&2
    done
  done

  # Show cursor
  tput cnorm 2>/dev/null < "$INPUT_TTY" || true

  # Build result
  local result=""
  for i in $(seq 0 $((count - 1))); do
    if [ "${selected[$i]}" = true ]; then
      if [ -n "$result" ]; then result+=","; fi
      result+="${keys[$i]}"
    fi
  done

  eval "$var_name=\"\$result\""
  echo "" >&2
}

# ─── Parse Arguments ────────────────────────────────────────────
PROJECT_NAME=""
APPS_FLAG=""
PACKAGES_FLAG=""
SCOPE=""
DISPLAY_NAME=""
SKIP_INSTALL=false
SKIP_GIT=false
SKIP_DB=false
SELECT_ALL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apps)          APPS_FLAG="$2";      shift 2 ;;
    --packages)      PACKAGES_FLAG="$2";  shift 2 ;;
    --scope)         SCOPE="$2";          shift 2 ;;
    --name)          DISPLAY_NAME="$2";   shift 2 ;;
    --skip-install)  SKIP_INSTALL=true;   shift ;;
    --skip-git)      SKIP_GIT=true;       shift ;;
    --skip-db)       SKIP_DB=true;        shift ;;
    --all)           SELECT_ALL=true;     shift ;;
    -h|--help)
      echo ""
      echo "Delta Starter v${VERSION} — Modular Fullstack Monorepo Generator"
      echo ""
      echo "Usage: create.sh [project-name] [options]"
      echo ""
      echo "Options:"
      echo "  --apps <list>        Comma-separated: api,web,mobile"
      echo "  --packages <list>    Comma-separated: shared,logic,client,ui,tokens"
      echo "  --scope <scope>      npm scope (default: @<slug>)"
      echo "  --name <name>        Display name"
      echo "  --all                Select all apps and packages"
      echo "  --skip-install       Don't run pnpm install"
      echo "  --skip-git           Don't initialize git repo"
      echo "  --skip-db            Don't start database"
      echo "  -h, --help           Show this help"
      echo ""
      echo "Examples:"
      echo "  ./create.sh my-app"
      echo "  ./create.sh my-app --apps api,web --packages shared,logic"
      echo "  ./create.sh my-app --all --skip-db"
      echo "  curl ... | bash -s -- my-app --all"
      echo ""
      exit 0
      ;;
    -*) fatal "Unknown option: $1 (use --help)" ;;
    *)  PROJECT_NAME="$1"; shift ;;
  esac
done

if [ "$SELECT_ALL" = true ]; then
  APPS_FLAG="${APPS_FLAG:-api,web,mobile}"
  PACKAGES_FLAG="${PACKAGES_FLAG:-shared,logic,client,ui,tokens}"
fi

# ─── Banner ─────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}  ┌──────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}${CYAN}  │           ▲ Delta Starter v${VERSION}                │${NC}"
echo -e "${BOLD}${CYAN}  │     Modular Fullstack Monorepo Generator         │${NC}"
echo -e "${BOLD}${CYAN}  └──────────────────────────────────────────────────┘${NC}"
echo ""

# ─── Step 1: Project Name ──────────────────────────────────────
if [ -z "$PROJECT_NAME" ]; then
  prompt PROJECT_NAME "Project name" "my-app"
fi

PROJECT_SLUG=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' _' '-' | sed 's/[^a-z0-9-]//g')
[ -z "$PROJECT_SLUG" ] && fatal "Invalid project name: '$PROJECT_NAME'"
[ -z "$SCOPE" ] && SCOPE="@${PROJECT_SLUG}"
[ -z "$DISPLAY_NAME" ] && DISPLAY_NAME=$(echo "$PROJECT_SLUG" | sed -r 's/(^|-)(\w)/\U\2/g')

# ─── Step 2: Select Apps ───────────────────────────────────────
if [ -z "$APPS_FLAG" ]; then
  checkbox_prompt APPS_FLAG "Which apps do you need?" \
    "api:Backend API        (Express + Prisma + PostgreSQL)" \
    "web:Web App            (Next.js 16 + Turbopack)" \
    "mobile:Mobile App        (React Native + Expo)"
fi

# Parse apps into booleans
HAS_API=false; HAS_WEB=false; HAS_MOBILE=false
IFS=',' read -ra APPS_ARR <<< "$APPS_FLAG"
for app in "${APPS_ARR[@]}"; do
  case "$(echo "$app" | xargs)" in
    api)    HAS_API=true ;;
    web)    HAS_WEB=true ;;
    mobile) HAS_MOBILE=true ;;
  esac
done

[ "$HAS_API" = false ] && [ "$HAS_WEB" = false ] && [ "$HAS_MOBILE" = false ] && \
  fatal "At least one app must be selected"

# ─── Step 3: Select Packages ───────────────────────────────────
if [ -z "$PACKAGES_FLAG" ]; then
  # Build options based on selected apps
  PKG_OPTS=("shared:Schemas & Types     (Zod schemas, TypeScript types, constants)")
  PKG_OPTS+=("logic:Business Logic      (Pure shared functions)")

  if [ "$HAS_API" = true ] && { [ "$HAS_WEB" = true ] || [ "$HAS_MOBILE" = true ]; }; then
    PKG_OPTS+=("client:API Client          (Typed HTTP client + React Query hooks)")
  fi

  if [ "$HAS_WEB" = true ] || [ "$HAS_MOBILE" = true ]; then
    PKG_OPTS+=("ui:UI Components       (Cross-platform Tamagui components)")
    PKG_OPTS+=("tokens:Design Tokens       (Shared colors, spacing, typography)")
  fi

  checkbox_prompt PACKAGES_FLAG "Which shared packages?" "${PKG_OPTS[@]}"
fi

# Parse packages into booleans
HAS_SHARED=false; HAS_LOGIC=false; HAS_CLIENT=false; HAS_UI=false; HAS_TOKENS=false
IFS=',' read -ra PKGS_ARR <<< "$PACKAGES_FLAG"
for pkg in "${PKGS_ARR[@]}"; do
  case "$(echo "$pkg" | xargs)" in
    shared) HAS_SHARED=true ;;
    logic)  HAS_LOGIC=true ;;
    client) HAS_CLIENT=true ;;
    ui)     HAS_UI=true ;;
    tokens) HAS_TOKENS=true ;;
  esac
done

# Dependency enforcement
if [ "$HAS_UI" = true ] && [ "$HAS_TOKENS" = false ]; then
  HAS_TOKENS=true
  info "Auto-enabling Design Tokens (required by UI Components)"
fi
if [ "$HAS_CLIENT" = true ] && [ "$HAS_SHARED" = false ]; then
  HAS_SHARED=true
  info "Auto-enabling Schemas & Types (required by API Client)"
fi

# ─── Show Configuration ────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Configuration:${NC}"
echo -e "    Directory:     ${CYAN}${PROJECT_SLUG}/${NC}"
echo -e "    Scope:         ${CYAN}${SCOPE}${NC}"
echo -e "    Display name:  ${CYAN}${DISPLAY_NAME}${NC}"

APPS_DISPLAY=""
[ "$HAS_API" = true ]    && APPS_DISPLAY+="api "
[ "$HAS_WEB" = true ]    && APPS_DISPLAY+="web "
[ "$HAS_MOBILE" = true ] && APPS_DISPLAY+="mobile "
echo -e "    Apps:          ${CYAN}${APPS_DISPLAY}${NC}"

PKGS_DISPLAY=""
[ "$HAS_SHARED" = true ] && PKGS_DISPLAY+="shared "
[ "$HAS_LOGIC" = true ]  && PKGS_DISPLAY+="business-logic "
[ "$HAS_CLIENT" = true ] && PKGS_DISPLAY+="api-client "
[ "$HAS_UI" = true ]     && PKGS_DISPLAY+="ui "
[ "$HAS_TOKENS" = true ] && PKGS_DISPLAY+="tokens "
echo -e "    Packages:      ${CYAN}${PKGS_DISPLAY}${NC}"
echo ""

# Check target directory
[ -d "$PROJECT_SLUG" ] && fatal "Directory '$PROJECT_SLUG' already exists"

# ─── Step 4: Check Prerequisites ───────────────────────────────
step "Checking prerequisites"

MISSING=()

if command -v node &>/dev/null; then
  NODE_VER=$(node -v | sed 's/v//' | cut -d. -f1)
  [ "$NODE_VER" -ge 22 ] && success "Node.js $(node -v)" || { error "Node.js >= 22 required"; MISSING+=("node"); }
else
  error "Node.js not found"; MISSING+=("node")
fi

if command -v pnpm &>/dev/null; then
  success "pnpm $(pnpm -v)"
else
  info "Installing pnpm via corepack..."
  if corepack enable 2>/dev/null && corepack prepare pnpm@latest --activate 2>/dev/null; then
    success "pnpm installed"
  else
    error "Could not install pnpm"; MISSING+=("pnpm")
  fi
fi

command -v git &>/dev/null && success "git $(git --version | awk '{print $3}')" || { warn "git not found"; SKIP_GIT=true; }

[ ${#MISSING[@]} -gt 0 ] && fatal "Missing: ${MISSING[*]}"

# ─── Step 5: Download & Assemble ───────────────────────────────
step "Assembling project"

# Locate template source
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null || echo ".")" && pwd)"
TMPL=""

if [ -d "$SCRIPT_DIR/base" ] && [ -d "$SCRIPT_DIR/apps" ]; then
  TMPL="$SCRIPT_DIR"
  info "Using local template"
else
  info "Downloading template..."
  TMPDIR=$(mktemp -d)
  trap "rm -rf $TMPDIR" EXIT
  git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$TMPDIR/repo" 2>/dev/null \
    || fatal "Failed to clone. Check URL/network."
  TMPL="$TMPDIR/repo"
fi

mkdir -p "$PROJECT_SLUG"

# ── Copy base (always) ──
cp -r "$TMPL/base/." "$PROJECT_SLUG/"
success "Base config"

# Always include config package
mkdir -p "$PROJECT_SLUG/packages/config"
cp -r "$TMPL/packages/config/." "$PROJECT_SLUG/packages/config/"
success "Config package"

# ── Copy selected apps ──
if [ "$HAS_API" = true ]; then
  mkdir -p "$PROJECT_SLUG/apps/api"
  cp -r "$TMPL/apps/api/." "$PROJECT_SLUG/apps/api/"
  success "App: api (Express + Prisma)"
fi

if [ "$HAS_WEB" = true ]; then
  mkdir -p "$PROJECT_SLUG/apps/web"
  cp -r "$TMPL/apps/web/." "$PROJECT_SLUG/apps/web/"
  success "App: web (Next.js 16)"
fi

if [ "$HAS_MOBILE" = true ]; then
  mkdir -p "$PROJECT_SLUG/apps/mobile"
  cp -r "$TMPL/apps/mobile/." "$PROJECT_SLUG/apps/mobile/"
  success "App: mobile (Expo)"
fi

# ── Copy selected packages ──
if [ "$HAS_SHARED" = true ]; then
  mkdir -p "$PROJECT_SLUG/packages/shared"
  cp -r "$TMPL/packages/shared/." "$PROJECT_SLUG/packages/shared/"
  success "Package: shared (schemas, types, constants)"
fi

if [ "$HAS_LOGIC" = true ]; then
  mkdir -p "$PROJECT_SLUG/packages/business-logic"
  cp -r "$TMPL/packages/business-logic/." "$PROJECT_SLUG/packages/business-logic/"
  success "Package: business-logic"
fi

if [ "$HAS_CLIENT" = true ]; then
  mkdir -p "$PROJECT_SLUG/packages/api-client"
  cp -r "$TMPL/packages/api-client/." "$PROJECT_SLUG/packages/api-client/"
  success "Package: api-client (React Query hooks)"
fi

if [ "$HAS_TOKENS" = true ]; then
  mkdir -p "$PROJECT_SLUG/packages/tokens"
  cp -r "$TMPL/packages/tokens/." "$PROJECT_SLUG/packages/tokens/"
  success "Package: tokens (Tamagui config)"
fi

if [ "$HAS_UI" = true ]; then
  mkdir -p "$PROJECT_SLUG/packages/ui"
  cp -r "$TMPL/packages/ui/." "$PROJECT_SLUG/packages/ui/"
  success "Package: ui (Tamagui components)"
fi

# ─── Step 6: Generate Dynamic Files ────────────────────────────
step "Generating configuration"

cd "$PROJECT_SLUG"

# ── Build root package.json dynamically ──
SCRIPTS='"setup": "bash scripts/setup.sh",'
SCRIPTS+='\n    "dev": "turbo dev",'

[ "$HAS_API" = true ]    && SCRIPTS+='\n    "dev:api": "pnpm --filter __SCOPE__/api dev",'
[ "$HAS_WEB" = true ]    && SCRIPTS+='\n    "dev:web": "pnpm --filter __SCOPE__/web dev",'
[ "$HAS_MOBILE" = true ] && SCRIPTS+='\n    "dev:mobile": "pnpm --filter __SCOPE__/mobile dev",'

SCRIPTS+='\n    "build": "turbo build",'

[ "$HAS_API" = true ] && SCRIPTS+='\n    "build:api": "pnpm --filter __SCOPE__/api build",'
[ "$HAS_WEB" = true ] && SCRIPTS+='\n    "build:web": "pnpm --filter __SCOPE__/web build",'

SCRIPTS+='\n    "lint": "turbo lint",'
SCRIPTS+='\n    "type-check": "turbo type-check",'
SCRIPTS+='\n    "typecheck": "bash scripts/typecheck.sh",'
SCRIPTS+='\n    "test": "turbo test",'
SCRIPTS+='\n    "format": "prettier --write \"**/*.{ts,tsx,js,jsx,json,md}\"",'
SCRIPTS+='\n    "format:check": "prettier --check \"**/*.{ts,tsx,js,jsx,json,md}\"",'
SCRIPTS+='\n    "clean": "bash scripts/clean.sh",'
SCRIPTS+='\n    "clean:all": "bash scripts/clean.sh --all",'

if [ "$HAS_API" = true ]; then
  SCRIPTS+='\n    "db": "bash scripts/db.sh",'
  SCRIPTS+='\n    "db:start": "bash scripts/db.sh start",'
  SCRIPTS+='\n    "db:stop": "bash scripts/db.sh stop",'
  SCRIPTS+='\n    "db:reset": "bash scripts/db.sh reset",'
  SCRIPTS+='\n    "db:seed": "pnpm --filter __SCOPE__/api db:seed",'
  SCRIPTS+='\n    "db:studio": "bash scripts/db.sh studio",'
  SCRIPTS+='\n    "db:migrate": "bash scripts/db.sh migrate",'
fi

SCRIPTS+='\n    "generate": "bash scripts/generate.sh",'
SCRIPTS+='\n    "docker:up": "docker compose up -d",'
SCRIPTS+='\n    "docker:down": "docker compose down",'
SCRIPTS+='\n    "docker:logs": "docker compose logs -f",'
SCRIPTS+='\n    "prepare": "lefthook install || true"'

cat > package.json << ROOTPKG
{
  "name": "__SLUG__",
  "private": true,
  "scripts": {
    $(echo -e "$SCRIPTS")
  },
  "devDependencies": {
    "__SCOPE__/config": "workspace:*",
    "lefthook": "^1.9.0",
    "prettier": "^3.4.2",
    "turbo": "^2.3.3",
    "typescript": "^5.7.2"
  },
  "packageManager": "pnpm@9.15.0",
  "engines": {
    "node": ">=22.0.0"
  }
}
ROOTPKG

success "Root package.json"

# ── Build turbo.json dynamically ──
cat > turbo.json << 'TURBO'
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env.*local"],
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "!.next/cache/**", "dist/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "lint": {
      "dependsOn": ["^build"]
    },
    "type-check": {
      "dependsOn": ["^build"]
    },
    "clean": {
      "cache": false
    }
  }
}
TURBO
success "turbo.json"

# ── Build docker-compose.yml dynamically ──
cat > docker-compose.yml << COMPOSE
services:
COMPOSE

if [ "$HAS_API" = true ]; then
  cat >> docker-compose.yml << COMPOSE
  postgres:
    image: postgres:16-alpine
    container_name: __SLUG__-postgres
    restart: unless-stopped
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: __SLUG___dev
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: __SLUG__-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redisdata:/data

  mailpit:
    image: axllent/mailpit:latest
    container_name: __SLUG__-mailpit
    restart: unless-stopped
    ports:
      - "1025:1025"
      - "8025:8025"

COMPOSE
fi

cat >> docker-compose.yml << COMPOSE
volumes:
COMPOSE

if [ "$HAS_API" = true ]; then
  cat >> docker-compose.yml << COMPOSE
  pgdata:
    driver: local
  redisdata:
    driver: local
COMPOSE
else
  echo "  {}" >> docker-compose.yml
fi

success "docker-compose.yml"

# ── Build README.md dynamically ──
cat > README.md << 'READMETOP'
# __DISPLAY_NAME__

A fullstack monorepo application.

## Tech Stack

| Layer | Technology |
|---|---|
| **Monorepo** | Turborepo + pnpm workspaces |
READMETOP

[ "$HAS_WEB" = true ]    && echo '| **Web** | Next.js 16 (App Router, Turbopack, React Compiler) |' >> README.md
[ "$HAS_MOBILE" = true ] && echo '| **Mobile** | React Native (Expo SDK 52, New Architecture) |' >> README.md
[ "$HAS_API" = true ]    && echo '| **API** | Express 5 + Prisma + PostgreSQL |' >> README.md
([ "$HAS_WEB" = true ] || [ "$HAS_MOBILE" = true ]) && echo '| **Styling** | Tamagui (cross-platform tokens & components) |' >> README.md
echo '| **Runtime** | Node.js 22 LTS |' >> README.md

cat >> README.md << 'READMEMID'

## Getting Started

```bash
pnpm install
pnpm dev
```

READMEMID

if [ "$HAS_API" = true ]; then
  cat >> README.md << 'READMEDB'
### Database

```bash
pnpm db:start          # Start PostgreSQL (Docker)
pnpm db:seed           # Seed with sample data
pnpm db:studio         # Open Prisma Studio
pnpm db:migrate <name> # Create migration
```

READMEDB
fi

cat >> README.md << READMEEND

## Commands

| Command | Description |
|---|---|
| \`pnpm dev\` | Start all apps |
| \`pnpm build\` | Build all packages |
| \`pnpm lint\` | Lint all packages |
| \`pnpm typecheck\` | Type-check all packages |
| \`pnpm generate\` | Scaffold schemas, routes, components |
| \`pnpm clean\` | Remove build artifacts |
READMEEND

success "README.md"

# ── Remove unused scripts from base ──
if [ "$HAS_API" = false ]; then
  rm -f scripts/db.sh
  info "Removed db.sh (no backend)"
fi

# ── Trim typecheck.sh to only include selected packages ──
if [ -f scripts/typecheck.sh ]; then
  # Rebuild the check lines
  CHECKS=""
  [ "$HAS_SHARED" = true ] && CHECKS+='check_package "__SCOPE__/shared"          "packages/shared"\n'
  [ "$HAS_LOGIC" = true ]  && CHECKS+='check_package "__SCOPE__/business-logic"  "packages/business-logic"\n'
  [ "$HAS_TOKENS" = true ] && CHECKS+='check_package "__SCOPE__/tokens"          "packages/tokens"\n'
  [ "$HAS_CLIENT" = true ] && CHECKS+='check_package "__SCOPE__/api-client"      "packages/api-client"\n'
  [ "$HAS_UI" = true ]     && CHECKS+='check_package "__SCOPE__/ui"              "packages/ui"\n'
  [ "$HAS_API" = true ]    && CHECKS+='check_package "__SCOPE__/api"             "apps/api"\n'
  [ "$HAS_WEB" = true ]    && CHECKS+='check_package "__SCOPE__/web"             "apps/web"\n'
  [ "$HAS_MOBILE" = true ] && CHECKS+='check_package "__SCOPE__/mobile"          "apps/mobile"\n'

  # We keep typecheck.sh but will do placeholder replacement next
fi

# ─── Step 7: Replace Placeholders ──────────────────────────────
step "Personalizing project"

find . -type f \( \
  -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
  -o -name "*.json" -o -name "*.sh" -o -name "*.yml" -o -name "*.yaml" \
  -o -name "*.md" -o -name "*.prisma" -o -name "*.css" \
\) | while read -r file; do
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' \
      -e "s|__SCOPE__|${SCOPE}|g" \
      -e "s|__DISPLAY_NAME__|${DISPLAY_NAME}|g" \
      -e "s|__SLUG__|${PROJECT_SLUG}|g" \
      "$file"
  else
    sed -i \
      -e "s|__SCOPE__|${SCOPE}|g" \
      -e "s|__DISPLAY_NAME__|${DISPLAY_NAME}|g" \
      -e "s|__SLUG__|${PROJECT_SLUG}|g" \
      "$file"
  fi
done

REMAINING=$(grep -rn "__SCOPE__\|__DISPLAY_NAME__\|__SLUG__" . --include="*.ts" --include="*.tsx" --include="*.json" --include="*.sh" --include="*.yml" --include="*.md" --include="*.prisma" 2>/dev/null | wc -l | xargs)
if [ "$REMAINING" -eq 0 ]; then
  success "All placeholders replaced"
else
  warn "${REMAINING} placeholders remaining"
fi

# ── Setup .env files ──
for env_example in $(find . -name ".env.example" -type f 2>/dev/null); do
  env_file="${env_example%.example}"
  cp "$env_example" "$env_file"
done
success "Environment files created"

# Generate JWT secret
if [ -f "apps/api/.env" ]; then
  JWT=$(openssl rand -base64 48 2>/dev/null || head -c 48 /dev/urandom | base64 2>/dev/null || echo "change-me-$(date +%s)")
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|change-this-to-a-secure-random-string|${JWT}|g" apps/api/.env
  else
    sed -i "s|change-this-to-a-secure-random-string|${JWT}|g" apps/api/.env
  fi
  success "Generated JWT_SECRET"
fi

chmod +x scripts/*.sh 2>/dev/null || true

# ─── Step 8: Git Init ──────────────────────────────────────────
if [ "$SKIP_GIT" = false ]; then
  step "Initializing git"
  git init -q && git add -A && git commit -q -m "Initial commit — Delta Starter v${VERSION}

Apps: ${APPS_DISPLAY}
Packages: ${PKGS_DISPLAY}
Generated by Delta Starter"
  success "Git initialized with initial commit"
fi

# ─── Step 9: Install ───────────────────────────────────────────
if [ "$SKIP_INSTALL" = false ]; then
  step "Installing dependencies"
  info "Running pnpm install..."
  pnpm install 2>&1 | tail -3
  success "Dependencies installed"

  if [ "$HAS_API" = true ]; then
    info "Generating Prisma client..."
    pnpm --filter "${SCOPE}/api" db:generate 2>/dev/null && success "Prisma client ready" || warn "Run manually: pnpm --filter ${SCOPE}/api db:generate"

    if [ "$SKIP_DB" = false ] && command -v docker &>/dev/null; then
      info "Starting database..."
      bash scripts/db.sh start 2>/dev/null || warn "Start manually: pnpm db:start"
      pnpm --filter "${SCOPE}/api" db:push 2>/dev/null && success "Schema synced" || warn "Run: pnpm --filter ${SCOPE}/api db:push"
    fi
  fi
fi

# ─── Done! ──────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}  ┌──────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}${GREEN}  │                                                  │${NC}"
echo -e "${BOLD}${GREEN}  │   ${DISPLAY_NAME} is ready! 🚀${NC}"
echo -e "${BOLD}${GREEN}  │                                                  │${NC}"
echo -e "${BOLD}${GREEN}  └──────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "  ${BOLD}Get started:${NC}"
echo ""
echo -e "    ${CYAN}cd ${PROJECT_SLUG}${NC}"
[ "$SKIP_INSTALL" = true ] && echo -e "    ${CYAN}pnpm install${NC}"
echo -e "    ${CYAN}pnpm dev${NC}"
echo ""
echo -e "  ${BOLD}Your apps:${NC}"
[ "$HAS_API" = true ]    && echo -e "    ${CYAN}API${NC}     → http://localhost:3001"
[ "$HAS_WEB" = true ]    && echo -e "    ${CYAN}Web${NC}     → http://localhost:3000"
[ "$HAS_MOBILE" = true ] && echo -e "    ${CYAN}Mobile${NC}  → Expo DevTools (scan QR)"
echo ""
echo -e "  ${BOLD}Project:${NC}"
echo -e "    ${DIM}${PROJECT_SLUG}/${NC}"
echo -e "    ├── apps/"
[ "$HAS_API" = true ]    && echo -e "    │   ├── api/          ${DIM}Express + Prisma${NC}"
[ "$HAS_WEB" = true ]    && echo -e "    │   ├── web/          ${DIM}Next.js 16${NC}"
[ "$HAS_MOBILE" = true ] && echo -e "    │   └── mobile/       ${DIM}Expo${NC}"
echo -e "    └── packages/"
[ "$HAS_SHARED" = true ] && echo -e "        ├── shared/       ${DIM}Schemas, types, constants${NC}"
[ "$HAS_LOGIC" = true ]  && echo -e "        ├── business-logic/${DIM} Pure functions${NC}"
[ "$HAS_CLIENT" = true ] && echo -e "        ├── api-client/   ${DIM}HTTP client + hooks${NC}"
[ "$HAS_UI" = true ]     && echo -e "        ├── ui/           ${DIM}Tamagui components${NC}"
[ "$HAS_TOKENS" = true ] && echo -e "        ├── tokens/       ${DIM}Design tokens & theme${NC}"
echo -e "        └── config/       ${DIM}ESLint, TSConfig${NC}"
echo ""
echo -e "  ${DIM}Happy coding! ▲${NC}"
echo ""
