#!/usr/bin/env bash
# =============================================================================
# __DISPLAY_NAME__ — Type Check All Packages
# =============================================================================
# Runs TypeScript type checking across all packages and reports results.
# Useful for CI and pre-commit hooks.
#
# Usage:
#   ./scripts/typecheck.sh
# =============================================================================

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "\n${BOLD}🔍 Type-checking all packages...${NC}\n"

FAILED=()
PASSED=()

check_package() {
  local name="$1"
  local dir="$2"

  if [ ! -f "$dir/tsconfig.json" ]; then
    return
  fi

  printf "  %-30s " "$name"

  if (cd "$dir" && npx tsc --noEmit 2>&1) > /tmp/tsc_output_$$ 2>&1; then
    echo -e "${GREEN}✔ passed${NC}"
    PASSED+=("$name")
  else
    echo -e "${RED}✖ failed${NC}"
    FAILED+=("$name")
    # Show first 10 error lines
    head -20 /tmp/tsc_output_$$ | sed 's/^/    /'
    echo ""
  fi

  rm -f /tmp/tsc_output_$$
}

# Packages (check in dependency order)
check_package "__SCOPE__/shared"          "packages/shared"
check_package "__SCOPE__/business-logic"  "packages/business-logic"
check_package "__SCOPE__/tokens"          "packages/tokens"
check_package "__SCOPE__/api-client"      "packages/api-client"
check_package "__SCOPE__/ui"              "packages/ui"

# Apps
check_package "__SCOPE__/api"             "apps/api"
check_package "__SCOPE__/web"             "apps/web"
check_package "__SCOPE__/mobile"          "apps/mobile"

# Summary
echo ""
echo -e "${BOLD}━━━ Results ━━━${NC}"
echo ""
echo -e "  ${GREEN}Passed:${NC} ${#PASSED[@]}"
echo -e "  ${RED}Failed:${NC} ${#FAILED[@]}"

if [ ${#FAILED[@]} -gt 0 ]; then
  echo ""
  echo -e "  ${RED}Failed packages:${NC}"
  for pkg in "${FAILED[@]}"; do
    echo -e "    - $pkg"
  done
  echo ""
  exit 1
else
  echo ""
  echo -e "  ${GREEN}${BOLD}All packages passed type checking!${NC}"
  echo ""
  exit 0
fi
