#!/usr/bin/env bash
# =============================================================================
#   ██████╗ ███████╗██╗  ████████╗ █████╗
#   ██╔══██╗██╔════╝██║  ╚══██╔══╝██╔══██╗
#   ██║  ██║█████╗  ██║     ██║   ███████║
#   ██║  ██║██╔══╝  ██║     ██║   ██╔══██║
#   ██████╔╝███████╗███████╗██║   ██║  ██║
#   ╚═════╝ ╚══════╝╚══════╝╚═╝   ╚═╝  ╚═╝
#   S T A R T E R   v2.1
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/deltasamantha/delta-starter/master/create.sh)
#   bash <(curl -fsSL .../create.sh) my-app --apps api,web,mobile
# =============================================================================

set -euo pipefail

VERSION="2.1.0"
REPO_URL="https://github.com/deltasamantha/delta-starter.git"
REPO_BRANCH="master"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

info()    { echo -e "  ${BLUE}ℹ${NC}  $1"; }
success() { echo -e "  ${GREEN}✔${NC}  $1"; }
warn()    { echo -e "  ${YELLOW}⚠${NC}  $1"; }
error()   { echo -e "  ${RED}✖${NC}  $1"; }
fatal()   { error "$1"; exit 1; }
step()    { echo -e "\n${BOLD}${MAGENTA}  ▸ $1${NC}\n"; }
pkg_info(){ echo -e "    ${DIM}+${NC} $1"; }

# ─── TTY for curl pipe ─────────────────────────────────────────
INPUT_TTY="/dev/tty"
IS_INTERACTIVE=false
if [ -t 0 ]; then IS_INTERACTIVE=true; INPUT_TTY="/dev/stdin"
elif [ -e /dev/tty ]; then IS_INTERACTIVE=true; fi

prompt() {
  local var_name="$1" prompt_text="$2" default="${3:-}"
  if [ "$IS_INTERACTIVE" = true ]; then
    echo -en "  ${BOLD}${prompt_text}${NC}"
    [ -n "$default" ] && echo -en " ${DIM}(${default})${NC}"
    echo -en ": "
    read -r REPLY < "$INPUT_TTY"
    [ -z "$REPLY" ] && REPLY="$default"
    eval "$var_name=\"\$REPLY\""
  else
    eval "$var_name=\"\$default\""
  fi
}

# Simple numbered menu — user picks a number. Works reliably via curl pipe.
# Usage: numbered_select VAR "Question" "1:Full Stack (API + Web + Mobile)" "2:Web + API" ...
numbered_select() {
  local var_name="$1"; shift
  local question="$1"; shift
  local -a options=("$@")

  if [ "$IS_INTERACTIVE" = false ]; then
    # Non-interactive: pick first option
    eval "$var_name=\"${options[0]%%:*}\""
    return
  fi

  echo -e "\n  ${BOLD}${question}${NC}\n"
  local i=1
  for opt in "${options[@]}"; do
    local label="${opt#*:}"
    echo -e "    ${CYAN}${i})${NC} ${label}"
    i=$((i + 1))
  done
  echo ""
  echo -en "  ${BOLD}Enter choice${NC} ${DIM}(1-${#options[@]})${NC}: "
  read -r choice < "$INPUT_TTY"

  # Validate
  if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#options[@]} ]; then
    local selected="${options[$((choice - 1))]}"
    eval "$var_name=\"${selected%%:*}\""
  else
    warn "Invalid choice, using option 1"
    eval "$var_name=\"${options[0]%%:*}\""
  fi
  echo ""
}

# ─── Parse Args ─────────────────────────────────────────────────
PROJECT_NAME="" APPS_FLAG="" SCOPE="" DISPLAY_NAME=""
SKIP_GIT=false SKIP_DB=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apps) APPS_FLAG="$2"; shift 2;;
    --scope) SCOPE="$2"; shift 2;;
    --name) DISPLAY_NAME="$2"; shift 2;;
    --skip-git) SKIP_GIT=true; shift;;
    --skip-db) SKIP_DB=true; shift;;
    --all) APPS_FLAG="api,web,mobile"; shift;;
    -h|--help) echo "Usage: create.sh [name] [--apps api,web,mobile | --all] [--scope @x] [--name X] [--skip-git] [--skip-db]"; exit 0;;
    -*) fatal "Unknown: $1";; *) PROJECT_NAME="$1"; shift;;
  esac
done

# ─── Banner ─────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}  ┌──────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}${CYAN}  │           ▲ Delta Starter v${VERSION}               │${NC}"
echo -e "${BOLD}${CYAN}  │     Modular Fullstack Monorepo Generator         │${NC}"
echo -e "${BOLD}${CYAN}  │     Always installs latest packages              │${NC}"
echo -e "${BOLD}${CYAN}  └──────────────────────────────────────────────────┘${NC}"
echo ""

# ─── 1. Project Name ───────────────────────────────────────────
[ -z "$PROJECT_NAME" ] && prompt PROJECT_NAME "Project name" "my-app"

# Sanitize: lowercase, replace spaces/underscores with hyphens, strip non-ascii and special chars
PROJECT_SLUG=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' _' '-' | LC_ALL=C sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
[ -z "$PROJECT_SLUG" ] && fatal "Invalid project name: '$PROJECT_NAME'"
[ -z "$SCOPE" ] && SCOPE="@${PROJECT_SLUG}"

# PascalCase: split on hyphens, capitalize each word
if [ -z "$DISPLAY_NAME" ]; then
  DISPLAY_NAME=""
  IFS='-' read -ra PARTS <<< "$PROJECT_SLUG"
  for part in "${PARTS[@]}"; do
    DISPLAY_NAME+="$(echo "${part:0:1}" | tr '[:lower:]' '[:upper:]')${part:1}"
  done
fi

# ─── 2. Select Apps ────────────────────────────────────────────
if [ -z "$APPS_FLAG" ]; then
  numbered_select APPS_FLAG "What would you like to build?" \
    "api,web,mobile:Full Stack          (API + Web + Mobile)" \
    "api,web:Web App + Backend   (API + Web)" \
    "api,mobile:Mobile + Backend   (API + Mobile)" \
    "web,mobile:Web + Mobile        (Web + Mobile, no backend)" \
    "api:Backend Only        (API only)" \
    "web:Web Only            (Next.js only)" \
    "mobile:Mobile Only         (Expo only)"
fi

HAS_API=false; HAS_WEB=false; HAS_MOBILE=false
IFS=',' read -ra APPS_ARR <<< "$APPS_FLAG"
for app in "${APPS_ARR[@]}"; do
  case "$(echo "$app" | xargs)" in api) HAS_API=true;; web) HAS_WEB=true;; mobile) HAS_MOBILE=true;; esac
done
[ "$HAS_API" = false ] && [ "$HAS_WEB" = false ] && [ "$HAS_MOBILE" = false ] && fatal "No apps selected"

# ─── 3. Auto-determine Packages (no prompt) ────────────────────
HAS_SHARED=true    # Always include schemas/types
HAS_LOGIC=true     # Always include business logic
HAS_CLIENT=false
HAS_UI=false
HAS_TOKENS=false

# API Client: only when there's a backend AND a frontend
if [ "$HAS_API" = true ] && { [ "$HAS_WEB" = true ] || [ "$HAS_MOBILE" = true ]; }; then
  HAS_CLIENT=true
fi

# UI + Tokens: only when there's a frontend (web or mobile)
if [ "$HAS_WEB" = true ] || [ "$HAS_MOBILE" = true ]; then
  HAS_UI=true
  HAS_TOKENS=true
fi

# ─── Show Config ────────────────────────────────────────────────
APPS_DISPLAY=""; [ "$HAS_API" = true ] && APPS_DISPLAY+="api "; [ "$HAS_WEB" = true ] && APPS_DISPLAY+="web "; [ "$HAS_MOBILE" = true ] && APPS_DISPLAY+="mobile "
PKGS_DISPLAY="config shared logic"; [ "$HAS_CLIENT" = true ] && PKGS_DISPLAY+=" api-client"; [ "$HAS_UI" = true ] && PKGS_DISPLAY+=" ui"; [ "$HAS_TOKENS" = true ] && PKGS_DISPLAY+=" tokens"

echo -e "  ${BOLD}Configuration:${NC}"
echo -e "    Project:    ${CYAN}${PROJECT_SLUG}/${NC}"
echo -e "    Scope:      ${CYAN}${SCOPE}${NC}"
echo -e "    Name:       ${CYAN}${DISPLAY_NAME}${NC}"
echo -e "    Apps:       ${CYAN}${APPS_DISPLAY}${NC}"
echo -e "    Packages:   ${CYAN}${PKGS_DISPLAY}${NC}"
echo ""

[ -d "$PROJECT_SLUG" ] && fatal "Directory '$PROJECT_SLUG' already exists"

# ─── 4. Prerequisites ──────────────────────────────────────────
step "Checking prerequisites"
MISSING=()
if command -v node &>/dev/null; then
  NODE_VER=$(node -v | sed 's/v//' | cut -d. -f1)
  [ "$NODE_VER" -ge 20 ] && success "Node.js $(node -v)" || { error "Node.js >= 20 required"; MISSING+=("node"); }
else error "Node.js not found"; MISSING+=("node"); fi
if command -v pnpm &>/dev/null; then success "pnpm $(pnpm -v)"
else info "Installing pnpm..."; corepack enable 2>/dev/null && corepack prepare pnpm@latest --activate 2>/dev/null && success "pnpm installed" || MISSING+=("pnpm"); fi
command -v git &>/dev/null && success "git" || { warn "git not found"; SKIP_GIT=true; }
[ ${#MISSING[@]} -gt 0 ] && fatal "Missing: ${MISSING[*]}"

# ─── 5. Resolve Templates ──────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null || echo ".")" && pwd)"
TMPL=""
if [ -d "$SCRIPT_DIR/base" ] && [ -d "$SCRIPT_DIR/apps" ]; then
  TMPL="$SCRIPT_DIR"; info "Using local templates"
else
  info "Downloading templates..."
  TMPDIR=$(mktemp -d); trap "rm -rf $TMPDIR" EXIT
  git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$TMPDIR/repo" 2>/dev/null || fatal "Failed to download templates. Check your network."
  TMPL="$TMPDIR/repo"
fi

# ─── Helper ─────────────────────────────────────────────────────
copy_src() {
  local src_base="$1" dst_base="$2"; shift 2
  for f in "$@"; do
    [ -f "$src_base/$f" ] && { mkdir -p "$(dirname "$dst_base/$f")"; cp "$src_base/$f" "$dst_base/$f"; }
  done
}

# ─── 6. Create Project ─────────────────────────────────────────
step "Initializing monorepo"
mkdir -p "$PROJECT_SLUG" && cd "$PROJECT_SLUG"

cat > pnpm-workspace.yaml << 'EOF'
packages:
  - "apps/*"
  - "packages/*"
EOF

PNPM_VER=$(pnpm -v)
node -e "
const pkg = { name: process.argv[1], private: true, scripts: {}, packageManager: 'pnpm@' + process.argv[2] };
require('fs').writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
" "$PROJECT_SLUG" "$PNPM_VER"

info "Installing turbo, typescript, prettier..."
pnpm add -Dw turbo@latest typescript@latest prettier@latest lefthook@latest 2>&1 | tail -1
success "Monorepo tooling installed"

cat > turbo.json << 'EOF'
{ "$schema": "https://turbo.build/schema.json", "globalDependencies": ["**/.env.*local"], "tasks": { "build": { "dependsOn": ["^build"], "outputs": [".next/**","!.next/cache/**","dist/**"] }, "dev": { "cache": false, "persistent": true }, "lint": { "dependsOn": ["^build"] }, "type-check": { "dependsOn": ["^build"] }, "clean": { "cache": false } } }
EOF

cp "$TMPL/base/.gitignore" .gitignore
cp "$TMPL/base/.prettierrc" .prettierrc
cp "$TMPL/base/lefthook.yml" lefthook.yml
mkdir -p scripts .github/workflows
for s in clean.sh typecheck.sh generate.sh setup.sh; do [ -f "$TMPL/base/scripts/$s" ] && cp "$TMPL/base/scripts/$s" "scripts/$s"; done
[ "$HAS_API" = true ] && [ -f "$TMPL/base/scripts/db.sh" ] && cp "$TMPL/base/scripts/db.sh" scripts/db.sh
chmod +x scripts/*.sh 2>/dev/null || true
[ -f "$TMPL/base/.github/workflows/ci.yml" ] && cp "$TMPL/base/.github/workflows/ci.yml" .github/workflows/ci.yml
success "Base config + scripts"

# ─── 7. Config Package ─────────────────────────────────────────
mkdir -p packages/config/{tsconfig,eslint}
cat > packages/config/package.json << PKG
{ "name": "${SCOPE}/config", "version": "0.0.0", "private": true, "exports": { "./eslint/*": "./eslint/*.js", "./tsconfig/*": "./tsconfig/*.json" } }
PKG
cp "$TMPL/packages/config/tsconfig/"*.json packages/config/tsconfig/ 2>/dev/null || true
cp "$TMPL/packages/config/eslint/"*.js packages/config/eslint/ 2>/dev/null || true
success "Config package"

# ─── 8. Shared ──────────────────────────────────────────────────
if [ "$HAS_SHARED" = true ]; then
  step "Installing shared schemas & types"
  mkdir -p packages/shared/src/{schemas,types,constants}
  cat > packages/shared/package.json << PKG
{ "name": "${SCOPE}/shared", "version": "0.0.0", "private": true, "type": "module", "main": "src/index.ts", "types": "src/index.ts", "exports": { ".": "./src/index.ts" }, "scripts": { "type-check": "tsc --noEmit", "lint": "echo ok" }, "devDependencies": { "${SCOPE}/config": "workspace:*" } }
PKG
  echo "{ \"extends\": \"${SCOPE}/config/tsconfig/library\", \"include\": [\"src\"] }" > packages/shared/tsconfig.json
  pnpm --filter "${SCOPE}/shared" add zod@latest 2>&1 | tail -1
  copy_src "$TMPL/packages/shared/src" "packages/shared/src" index.ts schemas/index.ts types/index.ts constants/index.ts
  success "zod@latest → ${SCOPE}/shared"
fi

# ─── 9. Business Logic ─────────────────────────────────────────
if [ "$HAS_LOGIC" = true ]; then
  step "Setting up business logic"
  mkdir -p packages/business-logic/src/{matching,scheduling,pricing}
  cat > packages/business-logic/package.json << PKG
{ "name": "${SCOPE}/business-logic", "version": "0.0.0", "private": true, "type": "module", "main": "src/index.ts", "types": "src/index.ts", "exports": { ".": "./src/index.ts" }, "scripts": { "type-check": "tsc --noEmit", "lint": "echo ok" }, "dependencies": { "${SCOPE}/shared": "workspace:*" }, "devDependencies": { "${SCOPE}/config": "workspace:*" } }
PKG
  echo "{ \"extends\": \"${SCOPE}/config/tsconfig/library\", \"include\": [\"src\"] }" > packages/business-logic/tsconfig.json
  copy_src "$TMPL/packages/business-logic/src" "packages/business-logic/src" index.ts matching/index.ts scheduling/index.ts pricing/index.ts
  success "${SCOPE}/business-logic"
fi

# ─── 10. Tokens ─────────────────────────────────────────────────
if [ "$HAS_TOKENS" = true ]; then
  step "Installing design tokens"
  mkdir -p packages/tokens/src
  cat > packages/tokens/package.json << PKG
{ "name": "${SCOPE}/tokens", "version": "0.0.0", "private": true, "type": "module", "main": "src/index.ts", "types": "src/index.ts", "exports": { ".": "./src/index.ts", "./tamagui.config": "./src/tamagui.config.ts" }, "scripts": { "type-check": "tsc --noEmit", "lint": "echo ok" }, "devDependencies": { "${SCOPE}/config": "workspace:*" } }
PKG
  echo "{ \"extends\": \"${SCOPE}/config/tsconfig/library\", \"include\": [\"src\"] }" > packages/tokens/tsconfig.json
  pnpm --filter "${SCOPE}/tokens" add tamagui@latest @tamagui/core@latest @tamagui/font-inter@latest @tamagui/animations-css@latest @tamagui/themes@latest 2>&1 | tail -1
  copy_src "$TMPL/packages/tokens/src" "packages/tokens/src" tamagui.config.ts index.ts
  success "tamagui@latest → ${SCOPE}/tokens"
fi

# ─── 11. UI ─────────────────────────────────────────────────────
if [ "$HAS_UI" = true ]; then
  step "Installing UI components"
  mkdir -p packages/ui/src/components
  cat > packages/ui/package.json << PKG
{ "name": "${SCOPE}/ui", "version": "0.0.0", "private": true, "type": "module", "main": "src/index.ts", "types": "src/index.ts", "exports": { ".": "./src/index.ts" }, "scripts": { "type-check": "tsc --noEmit", "lint": "echo ok" }, "dependencies": { "${SCOPE}/shared": "workspace:*", "${SCOPE}/tokens": "workspace:*" }, "devDependencies": { "${SCOPE}/config": "workspace:*" } }
PKG
  echo "{ \"extends\": \"${SCOPE}/config/tsconfig/library\", \"include\": [\"src\"] }" > packages/ui/tsconfig.json
  pnpm --filter "${SCOPE}/ui" add tamagui@latest @tamagui/core@latest 2>&1 | tail -1
  copy_src "$TMPL/packages/ui/src" "packages/ui/src" index.ts components/Badge.tsx components/JobCard.tsx components/StatusBadge.tsx
  success "tamagui@latest → ${SCOPE}/ui"
fi

# ─── 12. API Client ────────────────────────────────────────────
if [ "$HAS_CLIENT" = true ]; then
  step "Installing API client"
  mkdir -p packages/api-client/src/hooks
  cat > packages/api-client/package.json << PKG
{ "name": "${SCOPE}/api-client", "version": "0.0.0", "private": true, "type": "module", "main": "src/index.ts", "types": "src/index.ts", "exports": { ".": "./src/index.ts" }, "scripts": { "type-check": "tsc --noEmit", "lint": "echo ok" }, "dependencies": { "${SCOPE}/shared": "workspace:*" }, "devDependencies": { "${SCOPE}/config": "workspace:*" } }
PKG
  echo "{ \"extends\": \"${SCOPE}/config/tsconfig/library\", \"include\": [\"src\"] }" > packages/api-client/tsconfig.json
  pnpm --filter "${SCOPE}/api-client" add @tanstack/react-query@latest 2>&1 | tail -1
  copy_src "$TMPL/packages/api-client/src" "packages/api-client/src" index.ts client.ts hooks/useJobs.ts hooks/useAuth.ts
  success "@tanstack/react-query@latest → ${SCOPE}/api-client"
fi

# ─── 13. Express API ───────────────────────────────────────────
if [ "$HAS_API" = true ]; then
  step "Installing Express API"
  mkdir -p apps/api/src/{routes,middleware,prisma}
  cat > apps/api/package.json << PKG
{ "name": "${SCOPE}/api", "version": "0.0.0", "private": true, "type": "module", "scripts": { "dev": "tsx watch src/index.ts", "build": "tsc", "start": "node dist/index.js", "lint": "eslint src/", "type-check": "tsc --noEmit", "db:generate": "prisma generate --schema=src/prisma/schema.prisma", "db:migrate": "prisma migrate dev --schema=src/prisma/schema.prisma", "db:push": "prisma db push --schema=src/prisma/schema.prisma", "db:studio": "prisma studio --schema=src/prisma/schema.prisma", "db:seed": "tsx src/prisma/seed.ts" }, "devDependencies": { "${SCOPE}/config": "workspace:*" } }
PKG
  echo "{ \"extends\": \"${SCOPE}/config/tsconfig/node\", \"include\": [\"src\"] }" > apps/api/tsconfig.json

  info "Installing Express + Prisma..."
  pnpm --filter "${SCOPE}/api" add express@latest @prisma/client@latest cors@latest helmet@latest compression@latest jsonwebtoken@latest zod@latest 2>&1 | tail -1
  pkg_info "express, @prisma/client, cors, helmet, compression, jsonwebtoken, zod"
  [ "$HAS_SHARED" = true ] && pnpm --filter "${SCOPE}/api" add "${SCOPE}/shared@workspace:*" 2>&1 | tail -1
  [ "$HAS_LOGIC" = true ] && pnpm --filter "${SCOPE}/api" add "${SCOPE}/business-logic@workspace:*" 2>&1 | tail -1

  pnpm --filter "${SCOPE}/api" add -D prisma@latest tsx@latest typescript@latest @types/express@latest @types/cors@latest @types/compression@latest @types/jsonwebtoken@latest @types/node@latest 2>&1 | tail -1
  pkg_info "prisma, tsx, @types/* (dev)"

  cat > apps/api/.env.example << ENV
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/${PROJECT_SLUG}_dev"
JWT_SECRET=change-this-to-a-secure-random-string
PORT=3001
CORS_ORIGIN=http://localhost:3000
ENV
  cp apps/api/.env.example apps/api/.env
  JWT=$(openssl rand -base64 48 2>/dev/null || echo "change-me-$(date +%s)")
  if [[ "$OSTYPE" == "darwin"* ]]; then sed -i '' "s|change-this-to-a-secure-random-string|${JWT}|g" apps/api/.env
  else sed -i "s|change-this-to-a-secure-random-string|${JWT}|g" apps/api/.env; fi

  copy_src "$TMPL/apps/api/src" "apps/api/src" index.ts routes/auth.ts routes/jobs.ts routes/shifts.ts routes/profile.ts middleware/errorHandler.ts middleware/requestLogger.ts prisma/schema.prisma prisma/seed.ts
  success "Express API ready"
fi

# ─── 14. Next.js Web ───────────────────────────────────────────
if [ "$HAS_WEB" = true ]; then
  step "Installing Next.js web app"
  mkdir -p apps/web/app
  cat > apps/web/package.json << PKG
{ "name": "${SCOPE}/web", "version": "0.0.0", "private": true, "scripts": { "dev": "next dev --port 3000", "build": "next build", "start": "next start", "lint": "next lint", "type-check": "tsc --noEmit" }, "devDependencies": { "${SCOPE}/config": "workspace:*" } }
PKG
  echo "{ \"extends\": \"${SCOPE}/config/tsconfig/nextjs\", \"include\": [\"next-env.d.ts\",\"**/*.ts\",\"**/*.tsx\",\".next/types/**/*.ts\"] }" > apps/web/tsconfig.json

  info "Installing Next.js + React..."
  pnpm --filter "${SCOPE}/web" add next@latest react@latest react-dom@latest 2>&1 | tail -1
  pkg_info "next, react, react-dom"

  if [ "$HAS_TOKENS" = true ] || [ "$HAS_UI" = true ]; then
    info "Installing Tamagui web adapters..."
    pnpm --filter "${SCOPE}/web" add tamagui@latest @tamagui/core@latest @tamagui/font-inter@latest @tamagui/next-plugin@latest @tamagui/react-native-media-driver@latest react-native-web@latest 2>&1 | tail -1
    pkg_info "tamagui, @tamagui/next-plugin, react-native-web"
  fi
  [ "$HAS_CLIENT" = true ] && pnpm --filter "${SCOPE}/web" add @tanstack/react-query@latest 2>&1 | tail -1
  [ "$HAS_MOBILE" = true ] && pnpm --filter "${SCOPE}/web" add solito@latest 2>&1 | tail -1
  [ "$HAS_SHARED" = true ] && pnpm --filter "${SCOPE}/web" add "${SCOPE}/shared@workspace:*" 2>&1 | tail -1
  [ "$HAS_LOGIC" = true ] && pnpm --filter "${SCOPE}/web" add "${SCOPE}/business-logic@workspace:*" 2>&1 | tail -1
  [ "$HAS_CLIENT" = true ] && pnpm --filter "${SCOPE}/web" add "${SCOPE}/api-client@workspace:*" 2>&1 | tail -1
  [ "$HAS_TOKENS" = true ] && pnpm --filter "${SCOPE}/web" add "${SCOPE}/tokens@workspace:*" 2>&1 | tail -1
  [ "$HAS_UI" = true ] && pnpm --filter "${SCOPE}/web" add "${SCOPE}/ui@workspace:*" 2>&1 | tail -1
  pnpm --filter "${SCOPE}/web" add -D @types/react@latest @types/react-dom@latest @types/node@latest typescript@latest 2>&1 | tail -1

  cat > apps/web/.env.example << ENV
NEXT_PUBLIC_API_URL=http://localhost:3001
ENV
  cp apps/web/.env.example apps/web/.env
  copy_src "$TMPL/apps/web" "apps/web" app/layout.tsx app/page.tsx app/providers.tsx next.config.ts tamagui.config.ts proxy.ts
  success "Next.js web app ready"
fi

# ─── 15. Expo Mobile ───────────────────────────────────────────
if [ "$HAS_MOBILE" = true ]; then
  step "Installing Expo mobile app"
  mkdir -p "apps/mobile/app/(tabs)"
  cat > apps/mobile/package.json << PKG
{ "name": "${SCOPE}/mobile", "version": "0.0.0", "private": true, "main": "expo-router/entry", "scripts": { "dev": "expo start", "android": "expo run:android", "ios": "expo run:ios", "build": "echo 'Use EAS Build'", "lint": "eslint app/", "type-check": "tsc --noEmit" }, "devDependencies": { "${SCOPE}/config": "workspace:*" } }
PKG
  echo "{ \"extends\": \"${SCOPE}/config/tsconfig/react-native\", \"include\": [\"app\",\"**/*.ts\",\"**/*.tsx\"] }" > apps/mobile/tsconfig.json

  info "Installing Expo + React Native..."
  pnpm --filter "${SCOPE}/mobile" add expo@latest react@latest react-native@latest expo-router@latest expo-constants@latest expo-linking@latest expo-status-bar@latest react-native-safe-area-context@latest react-native-screens@latest 2>&1 | tail -1
  pkg_info "expo, react-native, expo-router"

  if [ "$HAS_TOKENS" = true ] || [ "$HAS_UI" = true ]; then
    pnpm --filter "${SCOPE}/mobile" add tamagui@latest @tamagui/core@latest @tamagui/font-inter@latest @tamagui/animations-react-native@latest @tamagui/react-native-media-driver@latest 2>&1 | tail -1
    pkg_info "tamagui + RN adapters"
  fi
  [ "$HAS_CLIENT" = true ] && pnpm --filter "${SCOPE}/mobile" add @tanstack/react-query@latest 2>&1 | tail -1
  [ "$HAS_WEB" = true ] && pnpm --filter "${SCOPE}/mobile" add solito@latest 2>&1 | tail -1
  [ "$HAS_SHARED" = true ] && pnpm --filter "${SCOPE}/mobile" add "${SCOPE}/shared@workspace:*" 2>&1 | tail -1
  [ "$HAS_LOGIC" = true ] && pnpm --filter "${SCOPE}/mobile" add "${SCOPE}/business-logic@workspace:*" 2>&1 | tail -1
  [ "$HAS_CLIENT" = true ] && pnpm --filter "${SCOPE}/mobile" add "${SCOPE}/api-client@workspace:*" 2>&1 | tail -1
  [ "$HAS_TOKENS" = true ] && pnpm --filter "${SCOPE}/mobile" add "${SCOPE}/tokens@workspace:*" 2>&1 | tail -1
  [ "$HAS_UI" = true ] && pnpm --filter "${SCOPE}/mobile" add "${SCOPE}/ui@workspace:*" 2>&1 | tail -1
  pnpm --filter "${SCOPE}/mobile" add -D @types/react@latest typescript@latest 2>&1 | tail -1

  cat > apps/mobile/.env.example << ENV
EXPO_PUBLIC_API_URL=http://localhost:3001
ENV
  cp apps/mobile/.env.example apps/mobile/.env
  copy_src "$TMPL/apps/mobile" "apps/mobile" app.json metro.config.js app/_layout.tsx "app/(tabs)/_layout.tsx" "app/(tabs)/index.tsx"
  success "Expo mobile app ready"
fi

# ─── 16. Replace Placeholders ──────────────────────────────────
step "Personalizing source files"
find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.json" -o -name "*.sh" -o -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.prisma" \) -not -path "*/node_modules/*" | while read -r file; do
  if [[ "$OSTYPE" == "darwin"* ]]; then sed -i '' -e "s|__SCOPE__|${SCOPE}|g" -e "s|__DISPLAY_NAME__|${DISPLAY_NAME}|g" -e "s|__SLUG__|${PROJECT_SLUG}|g" "$file"
  else sed -i -e "s|__SCOPE__|${SCOPE}|g" -e "s|__DISPLAY_NAME__|${DISPLAY_NAME}|g" -e "s|__SLUG__|${PROJECT_SLUG}|g" "$file"; fi
done
success "All placeholders replaced"

# ─── 17. Root Scripts ──────────────────────────────────────────
SCRIPTS='{"setup":"bash scripts/setup.sh","dev":"turbo dev"'
[ "$HAS_API" = true ] && SCRIPTS+=",\"dev:api\":\"pnpm --filter ${SCOPE}/api dev\""
[ "$HAS_WEB" = true ] && SCRIPTS+=",\"dev:web\":\"pnpm --filter ${SCOPE}/web dev\""
[ "$HAS_MOBILE" = true ] && SCRIPTS+=",\"dev:mobile\":\"pnpm --filter ${SCOPE}/mobile dev\""
SCRIPTS+=',"build":"turbo build"'
[ "$HAS_API" = true ] && SCRIPTS+=",\"build:api\":\"pnpm --filter ${SCOPE}/api build\""
[ "$HAS_WEB" = true ] && SCRIPTS+=",\"build:web\":\"pnpm --filter ${SCOPE}/web build\""
SCRIPTS+=',"lint":"turbo lint","type-check":"turbo type-check","typecheck":"bash scripts/typecheck.sh","test":"turbo test","format":"prettier --write \\\"**/*.{ts,tsx,js,jsx,json,md}\\\"","clean":"bash scripts/clean.sh","clean:all":"bash scripts/clean.sh --all"'
[ "$HAS_API" = true ] && SCRIPTS+=",\"db\":\"bash scripts/db.sh\",\"db:start\":\"bash scripts/db.sh start\",\"db:stop\":\"bash scripts/db.sh stop\",\"db:reset\":\"bash scripts/db.sh reset\",\"db:seed\":\"pnpm --filter ${SCOPE}/api db:seed\",\"db:studio\":\"bash scripts/db.sh studio\",\"db:migrate\":\"bash scripts/db.sh migrate\""
SCRIPTS+=',"generate":"bash scripts/generate.sh","docker:up":"docker compose up -d","docker:down":"docker compose down","prepare":"lefthook install || true"}'
node -e "const pkg=JSON.parse(require('fs').readFileSync('package.json','utf8'));pkg.scripts=JSON.parse(process.argv[1]);require('fs').writeFileSync('package.json',JSON.stringify(pkg,null,2)+'\n');" "$SCRIPTS"
success "Root scripts configured"

# ─── 18. Docker Compose ────────────────────────────────────────
if [ "$HAS_API" = true ]; then
  cat > docker-compose.yml << COMPOSE
services:
  postgres:
    image: postgres:16-alpine
    container_name: ${PROJECT_SLUG}-postgres
    ports: ["5432:5432"]
    environment: { POSTGRES_USER: postgres, POSTGRES_PASSWORD: postgres, POSTGRES_DB: ${PROJECT_SLUG}_dev }
    volumes: [pgdata:/var/lib/postgresql/data]
    healthcheck: { test: ["CMD-SHELL","pg_isready -U postgres"], interval: 5s, timeout: 5s, retries: 5 }
  redis:
    image: redis:7-alpine
    container_name: ${PROJECT_SLUG}-redis
    ports: ["6379:6379"]
  mailpit:
    image: axllent/mailpit:latest
    container_name: ${PROJECT_SLUG}-mailpit
    ports: ["1025:1025","8025:8025"]
volumes:
  pgdata:
COMPOSE
  success "docker-compose.yml"
fi

# ─── 19. README ─────────────────────────────────────────────────
cat > README.md << README
# ${DISPLAY_NAME}

## Get Started
\`\`\`bash
pnpm dev
\`\`\`

| Command | Description |
|---|---|
| \`pnpm dev\` | Start all apps |
| \`pnpm build\` | Build all |
| \`pnpm typecheck\` | Type-check all |
| \`pnpm generate\` | Scaffold features |
README
[ "$HAS_API" = true ] && echo '| `pnpm db:start` | Start PostgreSQL |' >> README.md
success "README.md"

# ─── 20. Prisma ─────────────────────────────────────────────────
if [ "$HAS_API" = true ]; then
  step "Setting up Prisma"
  pnpm --filter "${SCOPE}/api" db:generate 2>&1 | tail -2
  success "Prisma client generated"
  if [ "$SKIP_DB" = false ] && command -v docker &>/dev/null; then
    info "Starting database..."
    bash scripts/db.sh start 2>/dev/null && success "PostgreSQL running" || warn "Start manually: pnpm db:start"
    pnpm --filter "${SCOPE}/api" db:push 2>/dev/null && success "Schema synced" || warn "Run: pnpm db:push"
  fi
fi

# ─── 21. Git ────────────────────────────────────────────────────
if [ "$SKIP_GIT" = false ]; then
  step "Initializing git"
  git init -q && git add -A && git commit -q -m "Initial commit — Delta Starter v${VERSION}
Apps: ${APPS_DISPLAY}| Packages: ${PKGS_DISPLAY}"
  success "Git initialized"
fi

# ─── Done! ──────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}  ┌──────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}${GREEN}  │   ${DISPLAY_NAME} is ready! 🚀${NC}"
echo -e "${BOLD}${GREEN}  └──────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "  ${CYAN}cd ${PROJECT_SLUG} && pnpm dev${NC}"
echo ""
[ "$HAS_API" = true ]    && echo -e "    ${CYAN}API${NC}     → http://localhost:3001"
[ "$HAS_WEB" = true ]    && echo -e "    ${CYAN}Web${NC}     → http://localhost:3000"
[ "$HAS_MOBILE" = true ] && echo -e "    ${CYAN}Mobile${NC}  → Expo DevTools (scan QR)"
echo ""
echo -e "  ${DIM}All packages installed at latest versions ▲${NC}"
echo ""
