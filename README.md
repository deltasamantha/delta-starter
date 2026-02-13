# ▲ Delta Starter

**Modular fullstack monorepo generator.** Pick your apps, pick your packages — get a production-ready monorepo in seconds.

Supports any combination of **Next.js 16** + **React Native (Expo)** + **Express API**, with shared packages for schemas, business logic, UI components, and design tokens.

## Quick Start

```bash
# Interactive (prompts for choices)
bash <(curl -fsSL https://raw.githubusercontent.com/<USER>/delta-starter/main/create.sh)

# With project name
bash <(curl -fsSL .../create.sh) my-saas-app

# Everything, no prompts
bash <(curl -fsSL .../create.sh) my-saas-app --all

# Just web + API
bash <(curl -fsSL .../create.sh) my-saas-app --apps api,web --packages shared,logic,client

# Just mobile
bash <(curl -fsSL .../create.sh) my-saas-app --apps mobile --packages shared,ui,tokens
```

## Interactive Mode

```
  ┌──────────────────────────────────────────────────┐
  │           ▲ Delta Starter v1.0.0                 │
  │     Modular Fullstack Monorepo Generator         │
  └──────────────────────────────────────────────────┘

  Project name: my-app

  Which apps do you need? (space to toggle, enter to confirm)

  ❯ ◉ Backend API        (Express + Prisma + PostgreSQL)
    ◉ Web App            (Next.js 16 + Turbopack)
    ◉ Mobile App         (React Native + Expo)

  Which shared packages?

  ❯ ◉ Schemas & Types     (Zod schemas, TypeScript types, constants)
    ◉ Business Logic      (Pure shared functions)
    ◉ API Client          (Typed HTTP client + React Query hooks)
    ◉ UI Components       (Cross-platform Tamagui components)
    ◉ Design Tokens       (Shared colors, spacing, typography)
```

## All Options

```
./create.sh [project-name] [options]

Options:
  --apps <list>        Comma-separated: api, web, mobile
  --packages <list>    Comma-separated: shared, logic, client, ui, tokens
  --scope <scope>      npm scope (default: @<project-slug>)
  --name <n>        Display name (default: PascalCase)
  --all                Select everything (no prompts)
  --skip-install       Don't run pnpm install
  --skip-git           Don't initialize git
  --skip-db            Don't start database
  -h, --help           Show help
```

## What Gets Generated

Depending on your selections:

```
my-app/
├── apps/
│   ├── api/              ← --apps api     Express 5 + Prisma + PostgreSQL
│   ├── web/              ← --apps web     Next.js 16 (App Router, Turbopack)
│   └── mobile/           ← --apps mobile  React Native (Expo SDK 52)
│
├── packages/
│   ├── config/           ← always         ESLint, TSConfig, Prettier
│   ├── shared/           ← --packages shared    Zod schemas, types, constants
│   ├── business-logic/   ← --packages logic     Pure shared functions
│   ├── api-client/       ← --packages client    HTTP client + React Query hooks
│   ├── ui/               ← --packages ui        Cross-platform Tamagui components
│   └── tokens/           ← --packages tokens    Design tokens, themes, fonts
│
├── scripts/
│   ├── setup.sh          Full environment setup
│   ├── db.sh             Database management (only if api selected)
│   ├── generate.sh       Code scaffolding
│   ├── clean.sh          Cleanup
│   └── typecheck.sh      Per-package type checking
│
├── docker-compose.yml    Services vary by selection
├── turbo.json
├── pnpm-workspace.yaml
└── package.json          Scripts vary by selection
```

## Smart Defaults

The generator enforces dependency constraints:

- Selecting **UI Components** auto-enables **Design Tokens** (required)
- Selecting **API Client** auto-enables **Schemas & Types** (required)
- **API Client** is only offered if both a backend and a frontend are selected
- **UI / Tokens** are only offered if a frontend (web or mobile) is selected
- **db.sh** script is only included if backend is selected
- `docker-compose.yml` only includes PostgreSQL/Redis if backend is selected
- Root `package.json` scripts adapt to selected apps

## Example Configurations

### Full Stack (Web + Mobile + API)
```bash
./create.sh my-app --all
```

### SaaS Web App (No Mobile)
```bash
./create.sh my-saas --apps api,web --packages shared,logic,client,ui,tokens
```

### Mobile App with Backend
```bash
./create.sh my-mobile --apps api,mobile --packages shared,logic,client,ui,tokens
```

### API Microservice (No Frontend)
```bash
./create.sh my-api --apps api --packages shared,logic
```

### Static Website (No Backend)
```bash
./create.sh my-site --apps web --packages shared,ui,tokens
```

## Tech Stack

| Component | Technology |
|---|---|
| Monorepo | Turborepo + pnpm |
| Web | Next.js 16, React 19.2, React Compiler |
| Mobile | React Native 0.76+, Expo SDK 52 |
| API | Express 5, Prisma, PostgreSQL |
| Styling | Tamagui (cross-platform) |
| Validation | Zod (shared schemas) |
| Data fetching | TanStack React Query |
| Navigation | Solito + Expo Router + Next.js App Router |
| Runtime | Node.js 22 LTS |

## Prerequisites

- **Node.js** >= 22
- **pnpm** >= 9 (`corepack enable && corepack prepare pnpm@latest --activate`)
- **Docker** (optional, for PostgreSQL)

## License

MIT
