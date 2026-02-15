#!/usr/bin/env bash
# =============================================================================
# __DISPLAY_NAME__ — Code Generator
# =============================================================================
# Usage:
#   ./scripts/generate.sh <type> <name>
#
# Types:
#   schema <Name>       Generate a Zod schema + types in __SCOPE__/shared
#   route <name>        Generate Express route + controller in API
#   page <path>         Generate Next.js page in web app
#   screen <name>       Generate Expo screen in mobile app
#   component <Name>    Generate shared Tamagui component in __SCOPE__/ui
#   hook <useName>      Generate React Query hook in __SCOPE__/api-client
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

success() { echo -e "${GREEN}✔ ${NC} $1"; }
error()   { echo -e "${RED}✖ ${NC} $1"; exit 1; }
info()    { echo -e "${CYAN}ℹ ${NC} $1"; }

TYPE="${1:-}"
NAME="${2:-}"

if [ -z "$TYPE" ] || [ -z "$NAME" ]; then
  echo ""
  echo -e "${BOLD}__DISPLAY_NAME__ Code Generator${NC}"
  echo ""
  echo "Usage: ./scripts/generate.sh <type> <name>"
  echo ""
  echo "Types:"
  echo "  schema <Name>       Zod schema in __SCOPE__/shared"
  echo "  route <name>        Express route in API"
  echo "  page <path>         Next.js page in web app"
  echo "  screen <name>       Expo screen in mobile app"
  echo "  component <Name>    Tamagui component in __SCOPE__/ui"
  echo "  hook <useName>      React Query hook in __SCOPE__/api-client"
  echo ""
  echo "Examples:"
  echo "  ./scripts/generate.sh schema Invoice"
  echo "  ./scripts/generate.sh route invoices"
  echo "  ./scripts/generate.sh page invoices/[id]"
  echo "  ./scripts/generate.sh screen InvoiceDetail"
  echo "  ./scripts/generate.sh component InvoiceCard"
  echo "  ./scripts/generate.sh hook useInvoices"
  echo ""
  exit 0
fi

case "$TYPE" in

  schema)
    SCHEMA_FILE="packages/shared/src/schemas/${NAME,,}.ts"
    if [ -f "$SCHEMA_FILE" ]; then
      error "Schema file already exists: $SCHEMA_FILE"
    fi

    cat > "$SCHEMA_FILE" << EOF
import { z } from 'zod'

// ============================================================
// ${NAME}
// ============================================================

export const ${NAME}Status = z.enum(['active', 'inactive', 'archived'])
export type ${NAME}Status = z.infer<typeof ${NAME}Status>

export const ${NAME}Schema = z.object({
  id: z.string().uuid(),
  // TODO: Add your fields here
  status: ${NAME}Status.default('active'),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
})

export const Create${NAME}Schema = ${NAME}Schema.omit({
  id: true,
  status: true,
  createdAt: true,
  updatedAt: true,
})

export const Update${NAME}Schema = Create${NAME}Schema.partial()

export type ${NAME} = z.infer<typeof ${NAME}Schema>
export type Create${NAME} = z.infer<typeof Create${NAME}Schema>
export type Update${NAME} = z.infer<typeof Update${NAME}Schema>
EOF

    success "Created schema: $SCHEMA_FILE"
    info "Don't forget to export it from packages/shared/src/schemas/index.ts"
    ;;

  route)
    ROUTE_FILE="apps/api/src/routes/${NAME}.ts"
    if [ -f "$ROUTE_FILE" ]; then
      error "Route file already exists: $ROUTE_FILE"
    fi

    # Capitalize first letter for schema name guess
    SCHEMA_NAME="$(echo "${NAME}" | sed 's/s$//' | sed 's/./\U&/')"

    cat > "$ROUTE_FILE" << EOF
import { Router, type IRouter } from 'express'
// import { Create${SCHEMA_NAME}Schema } from '__SCOPE__/shared'

export const ${NAME}Router: IRouter = Router()

// GET /${NAME}
${NAME}Router.get('/', async (req, res, next) => {
  try {
    // TODO: Implement list with Prisma + pagination
    res.json({
      success: true,
      data: [],
      pagination: {
        page: 1,
        pageSize: 20,
        total: 0,
        totalPages: 0,
        hasNext: false,
        hasPrev: false,
      },
    })
  } catch (error) {
    next(error)
  }
})

// GET /${NAME}/:id
${NAME}Router.get('/:id', async (req, res, next) => {
  try {
    // TODO: Fetch by ID with Prisma
    res.json({ success: true, data: { id: req.params.id } })
  } catch (error) {
    next(error)
  }
})

// POST /${NAME}
${NAME}Router.post('/', async (req, res, next) => {
  try {
    // const data = Create${SCHEMA_NAME}Schema.parse(req.body)
    // TODO: Create with Prisma
    res.status(201).json({ success: true, data: req.body })
  } catch (error) {
    next(error)
  }
})

// PATCH /${NAME}/:id
${NAME}Router.patch('/:id', async (req, res, next) => {
  try {
    // TODO: Update with Prisma
    res.json({ success: true, data: { id: req.params.id, ...req.body } })
  } catch (error) {
    next(error)
  }
})

// DELETE /${NAME}/:id
${NAME}Router.delete('/:id', async (req, res, next) => {
  try {
    // TODO: Delete with Prisma
    res.json({ success: true, data: { id: req.params.id } })
  } catch (error) {
    next(error)
  }
})
EOF

    success "Created route: $ROUTE_FILE"
    info "Register it in apps/api/src/index.ts:"
    echo "  import { ${NAME}Router } from './routes/${NAME}.js'"
    echo "  app.use(\`\${apiPrefix}/${NAME}\`, ${NAME}Router)"
    ;;

  page)
    PAGE_DIR="apps/web/app/${NAME}"
    PAGE_FILE="${PAGE_DIR}/page.tsx"
    mkdir -p "$PAGE_DIR"

    if [ -f "$PAGE_FILE" ]; then
      error "Page already exists: $PAGE_FILE"
    fi

    # Extract page title from path
    PAGE_TITLE="$(echo "$NAME" | sed 's/\// /g' | sed 's/\[.*\]//g' | sed 's/./\U&/' | xargs)"

    cat > "$PAGE_FILE" << EOF
import { YStack, H2, Paragraph } from '__SCOPE__/ui'

export const metadata = {
  title: '${PAGE_TITLE}',
}

export default function ${PAGE_TITLE//[^a-zA-Z]/}Page() {
  return (
    <YStack padding="\$4" gap="\$4">
      <H2>${PAGE_TITLE}</H2>
      <Paragraph color="\$colorMuted">
        TODO: Implement this page
      </Paragraph>
    </YStack>
  )
}
EOF

    success "Created page: $PAGE_FILE"
    ;;

  screen)
    SCREEN_FILE="apps/mobile/app/(tabs)/${NAME,,}.tsx"
    if [ -f "$SCREEN_FILE" ]; then
      error "Screen already exists: $SCREEN_FILE"
    fi

    cat > "$SCREEN_FILE" << EOF
import { ScrollView } from 'react-native'
import { YStack, H2, Paragraph } from '__SCOPE__/ui'

export default function ${NAME}Screen() {
  return (
    <ScrollView>
      <YStack padding="\$4" gap="\$4">
        <H2>${NAME}</H2>
        <Paragraph color="\$colorMuted">
          TODO: Implement this screen
        </Paragraph>
      </YStack>
    </ScrollView>
  )
}
EOF

    success "Created screen: $SCREEN_FILE"
    info "Add it to the tab layout in apps/mobile/app/(tabs)/_layout.tsx"
    ;;

  component)
    COMPONENT_FILE="packages/ui/src/components/${NAME}.tsx"
    if [ -f "$COMPONENT_FILE" ]; then
      error "Component already exists: $COMPONENT_FILE"
    fi

    cat > "$COMPONENT_FILE" << EOF
'use client'

import { Card, H4, Paragraph, YStack } from 'tamagui'

interface ${NAME}Props {
  title: string
  description?: string
  onPress?: () => void
}

export function ${NAME}({ title, description, onPress }: ${NAME}Props) {
  return (
    <Card
      elevate
      bordered
      padding="\$4"
      gap="\$2"
      pressTheme
      animation="fast"
      hoverStyle={{ scale: 1.02 }}
      pressStyle={{ scale: 0.98 }}
      onPress={onPress}
      cursor={onPress ? 'pointer' : undefined}
    >
      <YStack gap="\$1">
        <H4>{title}</H4>
        {description && (
          <Paragraph color="\$colorMuted" numberOfLines={2}>
            {description}
          </Paragraph>
        )}
      </YStack>
    </Card>
  )
}
EOF

    success "Created component: $COMPONENT_FILE"
    info "Export it from packages/ui/src/index.ts:"
    echo "  export { ${NAME} } from './components/${NAME}'"
    ;;

  hook)
    HOOK_FILE="packages/api-client/src/hooks/${NAME}.ts"
    if [ -f "$HOOK_FILE" ]; then
      error "Hook file already exists: $HOOK_FILE"
    fi

    # Derive entity name from hook name (useInvoices -> Invoice)
    ENTITY=$(echo "$NAME" | sed 's/^use//' | sed 's/s$//')
    ENTITY_LOWER="$(echo "$ENTITY" | tr '[:upper:]' '[:lower:]')"
    ENTITY_PLURAL="${ENTITY_LOWER}s"

    cat > "$HOOK_FILE" << EOF
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import type { ApiResponse, PaginatedResponse } from '__SCOPE__/shared'
// import type { ${ENTITY}, Create${ENTITY} } from '__SCOPE__/shared'
import type { ApiClient } from '../client'

export const ${ENTITY_LOWER}Keys = {
  all: ['${ENTITY_PLURAL}'] as const,
  lists: () => [...${ENTITY_LOWER}Keys.all, 'list'] as const,
  list: (filters: Record<string, unknown>) => [...${ENTITY_LOWER}Keys.lists(), filters] as const,
  details: () => [...${ENTITY_LOWER}Keys.all, 'detail'] as const,
  detail: (id: string) => [...${ENTITY_LOWER}Keys.details(), id] as const,
}

export function create${ENTITY}Hooks(client: ApiClient) {
  function ${NAME}(filters: Record<string, unknown> = {}) {
    return useQuery({
      queryKey: ${ENTITY_LOWER}Keys.list(filters),
      queryFn: () =>
        client.get<PaginatedResponse<unknown>>('/api/v1/${ENTITY_PLURAL}', {
          params: filters as Record<string, string | number | boolean | undefined>,
        }),
    })
  }

  function use${ENTITY}(id: string) {
    return useQuery({
      queryKey: ${ENTITY_LOWER}Keys.detail(id),
      queryFn: () => client.get<ApiResponse<unknown>>(\`/api/v1/${ENTITY_PLURAL}/\${id}\`),
      enabled: !!id,
    })
  }

  function useCreate${ENTITY}() {
    const queryClient = useQueryClient()
    return useMutation({
      mutationFn: (data: unknown) =>
        client.post<ApiResponse<unknown>>('/api/v1/${ENTITY_PLURAL}', data),
      onSuccess: () => {
        queryClient.invalidateQueries({ queryKey: ${ENTITY_LOWER}Keys.lists() })
      },
    })
  }

  function useUpdate${ENTITY}(id: string) {
    const queryClient = useQueryClient()
    return useMutation({
      mutationFn: (data: unknown) =>
        client.patch<ApiResponse<unknown>>(\`/api/v1/${ENTITY_PLURAL}/\${id}\`, data),
      onSuccess: () => {
        queryClient.invalidateQueries({ queryKey: ${ENTITY_LOWER}Keys.detail(id) })
        queryClient.invalidateQueries({ queryKey: ${ENTITY_LOWER}Keys.lists() })
      },
    })
  }

  return { ${NAME}, use${ENTITY}, useCreate${ENTITY}, useUpdate${ENTITY} }
}
EOF

    success "Created hook: $HOOK_FILE"
    info "Export it from packages/api-client/src/index.ts:"
    echo "  export { create${ENTITY}Hooks, ${ENTITY_LOWER}Keys } from './hooks/${NAME}'"
    ;;

  *)
    error "Unknown type: $TYPE. Run without arguments to see usage."
    ;;
esac
