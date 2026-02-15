#!/usr/bin/env bash
# =============================================================================
#
#   ██████╗ ███████╗██╗  ████████╗ █████╗
#   ██╔══██╗██╔════╝██║  ╚══██╔══╝██╔══██╗
#   ██║  ██║█████╗  ██║     ██║   ███████║
#   ██║  ██║██╔══╝  ██║     ██║   ██╔══██║
#   ██████╔╝███████╗███████╗██║   ██║  ██║
#   ╚═════╝ ╚══════╝╚══════╝╚═╝   ╚═╝  ╚═╝
#   S T A R T E R   v2
#
#   Modular Fullstack Monorepo Generator
#   Always installs the latest packages from npm.
#
# =============================================================================
#   bash <(curl -fsSL https://raw.githubusercontent.com/deltasamantha/delta-starter/main/create.sh)
#   bash <(curl -fsSL .../create.sh) my-app --all
# =============================================================================

set -euo pipefail

VERSION="2.0.0"
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

checkbox_prompt() {
  local var_name="$1"; shift; local question="$1"; shift
  local -a options=("$@") keys=() labels=() selected=()
  for opt in "${options[@]}"; do keys+=("${opt%%:*}"); labels+=("${opt#*:}"); selected+=(true); done
  if [ "$IS_INTERACTIVE" = false ]; then eval "$var_name=\"$(IFS=,; echo "${keys[*]}")\""; return; fi
  echo -e "\n  ${BOLD}${question}${NC} ${DIM}(space to toggle, enter to confirm)${NC}\n"
  local cursor=0 count=${#keys[@]}
  tput civis 2>/dev/null < "$INPUT_TTY" || true
  for i in $(seq 0 $((count - 1))); do
    local check="◉" color="$GREEN"; [ "${selected[$i]}" = false ] && check="○" && color="$DIM"
    local pointer="  "; [ $i -eq $cursor ] && pointer="❯ "
    echo -e "  ${pointer}${color}${check}${NC} ${labels[$i]}" >&2
  done
  while true; do
    read -rsn1 key < "$INPUT_TTY"
    if [[ "$key" == $'\x1b' ]]; then
      read -rsn2 -t 0.1 seq < "$INPUT_TTY" || true
      case "$seq" in '[A') cursor=$(( (cursor - 1 + count) % count )) ;; '[B') cursor=$(( (cursor + 1) % count )) ;; esac
    elif [[ "$key" == " " ]]; then
      [ "${selected[$cursor]}" = true ] && selected[$cursor]=false || selected[$cursor]=true
    elif [[ "$key" == "" ]]; then break; fi
    for _ in $(seq 1 $count); do echo -en "\033[1A\033[2K" >&2; done
    for i in $(seq 0 $((count - 1))); do
      local check="◉" color="$GREEN"; [ "${selected[$i]}" = false ] && check="○" && color="$DIM"
      local pointer="  "; [ $i -eq $cursor ] && pointer="❯ "
      echo -e "  ${pointer}${color}${check}${NC} ${labels[$i]}" >&2
    done
  done
  tput cnorm 2>/dev/null < "$INPUT_TTY" || true
  local result=""
  for i in $(seq 0 $((count - 1))); do
    [ "${selected[$i]}" = true ] && { [ -n "$result" ] && result+=","; result+="${keys[$i]}"; }
  done
  eval "$var_name=\"\$result\""; echo "" >&2
}

# ─── Parse Args ─────────────────────────────────────────────────
PROJECT_NAME="" APPS_FLAG="" PACKAGES_FLAG="" SCOPE="" DISPLAY_NAME=""
SKIP_GIT=false SKIP_DB=false SELECT_ALL=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apps) APPS_FLAG="$2"; shift 2;; --packages) PACKAGES_FLAG="$2"; shift 2;;
    --scope) SCOPE="$2"; shift 2;; --name) DISPLAY_NAME="$2"; shift 2;;
    --skip-git) SKIP_GIT=true; shift;; --skip-db) SKIP_DB=true; shift;;
    --all) SELECT_ALL=true; shift;;
    -h|--help) echo "Usage: create.sh [name] [--apps api,web,mobile] [--packages shared,logic,client,ui,tokens] [--all] [--skip-git] [--skip-db]"; exit 0;;
    -*) fatal "Unknown: $1";; *) PROJECT_NAME="$1"; shift;;
  esac
done
[ "$SELECT_ALL" = true ] && APPS_FLAG="${APPS_FLAG:-api,web,mobile}" && PACKAGES_FLAG="${PACKAGES_FLAG:-shared,logic,client,ui,tokens}"

# ─── Banner ─────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}  ┌──────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}${CYAN}  │           ▲ Delta Starter v${VERSION}                │${NC}"
echo -e "${BOLD}${CYAN}  │     Modular Fullstack Monorepo Generator         │${NC}"
echo -e "${BOLD}${CYAN}  │     Always installs latest packages              │${NC}"
echo -e "${BOLD}${CYAN}  └──────────────────────────────────────────────────┘${NC}"
echo ""

# ─── 1. Project Name ───────────────────────────────────────────
[ -z "$PROJECT_NAME" ] && prompt PROJECT_NAME "Project name" "my-app"
PROJECT_SLUG=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' _' '-' | sed 's/[^a-z0-9-]//g')
[ -z "$PROJECT_SLUG" ] && fatal "Invalid project name"
[ -z "$SCOPE" ] && SCOPE="@${PROJECT_SLUG}"
[ -z "$DISPLAY_NAME" ] && DISPLAY_NAME=$(echo "$PROJECT_SLUG" | sed -r 's/(^|-)(\w)/\U\2/g')

# ─── 2. Select Apps ────────────────────────────────────────────
if [ -z "$APPS_FLAG" ]; then
  checkbox_prompt APPS_FLAG "Which apps do you need?" \
    "api:Backend API        (Express + Prisma + PostgreSQL)" \
    "web:Web App            (Next.js + Turbopack)" \
    "mobile:Mobile App        (React Native + Expo)"
fi
HAS_API=false; HAS_WEB=false; HAS_MOBILE=false
IFS=',' read -ra APPS_ARR <<< "$APPS_FLAG"
for app in "${APPS_ARR[@]}"; do case "$(echo "$app" | xargs)" in api) HAS_API=true;; web) HAS_WEB=true;; mobile) HAS_MOBILE=true;; esac; done
[ "$HAS_API" = false ] && [ "$HAS_WEB" = false ] && [ "$HAS_MOBILE" = false ] && fatal "Select at least one app"

# ─── 3. Select Packages ────────────────────────────────────────
if [ -z "$PACKAGES_FLAG" ]; then
  PKG_OPTS=("shared:Schemas & Types     (Zod validation, shared types)" "logic:Business Logic      (Pure shared functions)")
  { [ "$HAS_API" = true ] && { [ "$HAS_WEB" = true ] || [ "$HAS_MOBILE" = true ]; }; } && PKG_OPTS+=("client:API Client          (HTTP client + React Query hooks)")
  { [ "$HAS_WEB" = true ] || [ "$HAS_MOBILE" = true ]; } && PKG_OPTS+=("ui:UI Components       (Cross-platform Tamagui components)" "tokens:Design Tokens       (Shared colors, spacing, typography)")
  checkbox_prompt PACKAGES_FLAG "Which shared packages?" "${PKG_OPTS[@]}"
fi
HAS_SHARED=false; HAS_LOGIC=false; HAS_CLIENT=false; HAS_UI=false; HAS_TOKENS=false
IFS=',' read -ra PKGS_ARR <<< "$PACKAGES_FLAG"
for pkg in "${PKGS_ARR[@]}"; do case "$(echo "$pkg" | xargs)" in shared) HAS_SHARED=true;; logic) HAS_LOGIC=true;; client) HAS_CLIENT=true;; ui) HAS_UI=true;; tokens) HAS_TOKENS=true;; esac; done
[ "$HAS_UI" = true ] && [ "$HAS_TOKENS" = false ] && HAS_TOKENS=true && info "Auto-enabling Tokens (required by UI)"
[ "$HAS_CLIENT" = true ] && [ "$HAS_SHARED" = false ] && HAS_SHARED=true && info "Auto-enabling Shared (required by Client)"

# ─── Show Config ────────────────────────────────────────────────
APPS_DISPLAY=""; [ "$HAS_API" = true ] && APPS_DISPLAY+="api "; [ "$HAS_WEB" = true ] && APPS_DISPLAY+="web "; [ "$HAS_MOBILE" = true ] && APPS_DISPLAY+="mobile "
PKGS_DISPLAY=""; [ "$HAS_SHARED" = true ] && PKGS_DISPLAY+="shared "; [ "$HAS_LOGIC" = true ] && PKGS_DISPLAY+="logic "; [ "$HAS_CLIENT" = true ] && PKGS_DISPLAY+="client "; [ "$HAS_UI" = true ] && PKGS_DISPLAY+="ui "; [ "$HAS_TOKENS" = true ] && PKGS_DISPLAY+="tokens "
echo -e "\n  ${BOLD}Configuration:${NC}"
echo -e "    Directory:  ${CYAN}${PROJECT_SLUG}/${NC}    Scope: ${CYAN}${SCOPE}${NC}    Name: ${CYAN}${DISPLAY_NAME}${NC}"
echo -e "    Apps:       ${CYAN}${APPS_DISPLAY}${NC}"
echo -e "    Packages:   ${CYAN}${PKGS_DISPLAY}${NC}"
[ -d "$PROJECT_SLUG" ] && fatal "Directory '$PROJECT_SLUG' already exists"

# ─── 4. Prerequisites ──────────────────────────────────────────
step "Checking prerequisites"
MISSING=()
if command -v node &>/dev/null; then NODE_VER=$(node -v | sed 's/v//' | cut -d. -f1); [ "$NODE_VER" -ge 20 ] && success "Node.js $(node -v)" || { error "Node.js >= 20 required"; MISSING+=("node"); }; else error "Node.js not found"; MISSING+=("node"); fi
if command -v pnpm &>/dev/null; then success "pnpm $(pnpm -v)"; else info "Installing pnpm..."; corepack enable 2>/dev/null && corepack prepare pnpm@latest --activate 2>/dev/null && success "pnpm installed" || MISSING+=("pnpm"); fi
command -v git &>/dev/null && success "git" || { warn "git not found"; SKIP_GIT=true; }
[ ${#MISSING[@]} -gt 0 ] && fatal "Missing: ${MISSING[*]}"

# ─── 5. Resolve Templates ──────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null || echo ".")" && pwd)"
TMPL=""
if [ -d "$SCRIPT_DIR/base" ] && [ -d "$SCRIPT_DIR/apps" ]; then TMPL="$SCRIPT_DIR"; info "Using local templates"
else
  info "Downloading templates..."
  TMPDIR=$(mktemp -d); trap "rm -rf $TMPDIR" EXIT
  git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$TMPDIR/repo" 2>/dev/null || fatal "Clone failed"
  TMPL="$TMPDIR/repo"
fi

# ─── 6. Create Project ─────────────────────────────────────────
step "Initializing monorepo"
mkdir -p "$PROJECT_SLUG" && cd "$PROJECT_SLUG"

cat > pnpm-workspace.yaml << 'EOF'
packages:
  - "apps/*"
  - "packages/*"
EOF

cat > package.json << ROOTPKG
{ "name": "${PROJECT_SLUG}", "private": true, "scripts": {}, "packageManager": "pnpm@$(pnpm -v)" }
ROOTPKG

info "Installing turbo, typescript, prettier..."
pnpm add -Dw turbo@latest typescript@latest prettier@latest lefthook@latest 2>&1 | tail -1
success "Monorepo tooling"

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
if [ -d "$TMPL/packages/config" ]; then
  cp "$TMPL/packages/config/tsconfig/"*.json packages/config/tsconfig/ 2>/dev/null || true
  cp "$TMPL/packages/config/eslint/"*.js packages/config/eslint/ 2>/dev/null || true
fi
success "Config package"

# ─── Helper: copy source files from template ───────────────────
copy_src() {
  local src_base="$1" dst_base="$2"; shift 2
  for f in "$@"; do
    [ -f "$src_base/$f" ] && { mkdir -p "$(dirname "$dst_base/$f")"; cp "$src_base/$f" "$dst_base/$f"; }
  done
}

# ─── 8. Shared Package ─────────────────────────────────────────
if [ "$HAS_SHARED" = true ]; then
  step "Installing shared package"
  mkdir -p packages/shared/src/{schemas,types,constants}
  cat > packages/shared/package.json << PKG
{ "name": "${SCOPE}/shared", "version": "0.0.0", "private": true, "type": "module", "main": "src/index.ts", "types": "src/index.ts", "exports": { ".": "./src/index.ts" }, "scripts": { "type-check": "tsc --noEmit", "lint": "echo ok" }, "devDependencies": { "${SCOPE}/config": "workspace:*" } }
PKG
  echo "{ \"extends\": \"${SCOPE}/config/tsconfig/library\", \"include\": [\"src\"] }" > packages/shared/tsconfig.json
  pnpm --filter "${SCOPE}/shared" add zod@latest 2>&1 | tail -1
  copy_src "$TMPL/packages/shared/src" "packages/shared/src" index.ts schemas/index.ts types/index.ts constants/index.ts
  success "zod@latest installed → ${SCOPE}/shared"
fi

# ─── 9. Business Logic ─────────────────────────────────────────
if [ "$HAS_LOGIC" = true ]; then
  step "Setting up business-logic package"
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
  step "Installing tokens package"
  mkdir -p packages/tokens/src
  cat > packages/tokens/package.json << PKG
{ "name": "${SCOPE}/tokens", "version": "0.0.0", "private": true, "type": "module", "main": "src/index.ts", "types": "src/index.ts", "exports": { ".": "./src/index.ts", "./tamagui.config": "./src/tamagui.config.ts" }, "scripts": { "type-check": "tsc --noEmit", "lint": "echo ok" }, "devDependencies": { "${SCOPE}/config": "workspace:*" } }
PKG
  echo "{ \"extends\": \"${SCOPE}/config/tsconfig/library\", \"include\": [\"src\"] }" > packages/tokens/tsconfig.json
  info "Installing Tamagui core..."
  pnpm --filter "${SCOPE}/tokens" add tamagui@latest @tamagui/core@latest @tamagui/font-inter@latest @tamagui/animations-css@latest @tamagui/themes@latest 2>&1 | tail -1
  copy_src "$TMPL/packages/tokens/src" "packages/tokens/src" tamagui.config.ts index.ts
  success "tamagui@latest → ${SCOPE}/tokens"
fi

# ─── 11. UI ─────────────────────────────────────────────────────
if [ "$HAS_UI" = true ]; then
  step "Installing UI components package"
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
  step "Installing API client package"
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

  info "Installing Express + Prisma + dependencies..."
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
  success "Express API ready (all latest)"
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
  success "Next.js web app ready (all latest)"
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
  success "Expo mobile app ready (all latest)"
fi

# ─── 16. Replace Placeholders ──────────────────────────────────
step "Personalizing source files"
find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.json" -o -name "*.sh" -o -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.prisma" \) -not -path "*/node_modules/*" | while read -r file; do
  if [[ "$OSTYPE" == "darwin"* ]]; then sed -i '' -e "s|__SCOPE__|${SCOPE}|g" -e "s|__DISPLAY_NAME__|${DISPLAY_NAME}|g" -e "s|__SLUG__|${PROJECT_SLUG}|g" "$file"
  else sed -i -e "s|__SCOPE__|${SCOPE}|g" -e "s|__DISPLAY_NAME__|${DISPLAY_NAME}|g" -e "s|__SLUG__|${PROJECT_SLUG}|g" "$file"; fi
done
success "Placeholders replaced"

# ─── 17. Root Scripts ──────────────────────────────────────────
SCRIPTS='{"setup":"bash scripts/setup.sh","dev":"turbo dev"'
[ "$HAS_API" = true ] && SCRIPTS+=",\"dev:api\":\"pnpm --filter ${SCOPE}/api dev\""
[ "$HAS_WEB" = true ] && SCRIPTS+=",\"dev:web\":\"pnpm --filter ${SCOPE}/web dev\""
[ "$HAS_MOBILE" = true ] && SCRIPTS+=",\"dev:mobile\":\"pnpm --filter ${SCOPE}/mobile dev\""
SCRIPTS+=',"build":"turbo build"'
[ "$HAS_API" = true ] && SCRIPTS+=",\"build:api\":\"pnpm --filter ${SCOPE}/api build\""
[ "$HAS_WEB" = true ] && SCRIPTS+=",\"build:web\":\"pnpm --filter ${SCOPE}/web build\""
SCRIPTS+=',"lint":"turbo lint","type-check":"turbo type-check","typecheck":"bash scripts/typecheck.sh","test":"turbo test","format":"prettier --write \\\"**/*.{ts,tsx,js,jsx,json,md}\\\"","clean":"bash scripts/clean.sh","clean:all":"bash scripts/clean.sh --all"'
if [ "$HAS_API" = true ]; then SCRIPTS+=",\"db\":\"bash scripts/db.sh\",\"db:start\":\"bash scripts/db.sh start\",\"db:stop\":\"bash scripts/db.sh stop\",\"db:reset\":\"bash scripts/db.sh reset\",\"db:seed\":\"pnpm --filter ${SCOPE}/api db:seed\",\"db:studio\":\"bash scripts/db.sh studio\",\"db:migrate\":\"bash scripts/db.sh migrate\""; fi
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

## Commands
| Command | Description |
|---|---|
| \`pnpm dev\` | Start all apps |
| \`pnpm build\` | Build all |
| \`pnpm typecheck\` | Type-check all |
| \`pnpm generate\` | Scaffold features |
| \`pnpm clean\` | Remove artifacts |
README
[ "$HAS_API" = true ] && echo '| `pnpm db:start` | Start PostgreSQL |' >> README.md && echo '| `pnpm db:seed` | Seed database |' >> README.md && echo '| `pnpm db:studio` | Prisma Studio |' >> README.md

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
