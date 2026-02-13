#!/usr/bin/env bash
# =============================================================================
# __DISPLAY_NAME__ — Database Management Script
# =============================================================================
# Usage:
#   ./scripts/db.sh <command>
#
# Commands:
#   start     Start PostgreSQL container
#   stop      Stop PostgreSQL container
#   restart   Restart PostgreSQL container
#   reset     Drop and recreate database + push schema
#   seed      Run database seed script
#   studio    Open Prisma Studio
#   migrate   Create a new Prisma migration
#   push      Push schema to DB (no migration file)
#   generate  Regenerate Prisma client
#   status    Show database container status
#   logs      Show PostgreSQL logs
#   shell     Open psql shell
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

CONTAINER_NAME="__SLUG__-postgres"
DB_NAME="__SLUG___dev"
DB_USER="postgres"
DB_PASS="postgres"
DB_PORT="5432"

info()    { echo -e "${BLUE}ℹ ${NC} $1"; }
success() { echo -e "${GREEN}✔ ${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠ ${NC} $1"; }
error()   { echo -e "${RED}✖ ${NC} $1"; exit 1; }

# Check Docker is available
require_docker() {
  if ! command -v docker &> /dev/null; then
    error "Docker is required but not installed. https://docs.docker.com/get-docker/"
  fi
}

# Wait for PostgreSQL to be ready
wait_for_db() {
  info "Waiting for PostgreSQL to accept connections..."
  for i in $(seq 1 20); do
    if docker exec "$CONTAINER_NAME" pg_isready -U "$DB_USER" &> /dev/null; then
      success "PostgreSQL is ready"
      return 0
    fi
    sleep 1
  done
  error "PostgreSQL failed to start within 20 seconds"
}

case "${1:-help}" in

  start)
    require_docker
    if docker ps --format '{{.Names}}' | grep -q "$CONTAINER_NAME"; then
      success "PostgreSQL is already running"
    elif docker ps -a --format '{{.Names}}' | grep -q "$CONTAINER_NAME"; then
      info "Starting existing container..."
      docker start "$CONTAINER_NAME"
      wait_for_db
    else
      info "Creating new PostgreSQL container..."
      docker run -d \
        --name "$CONTAINER_NAME" \
        -e POSTGRES_USER="$DB_USER" \
        -e POSTGRES_PASSWORD="$DB_PASS" \
        -e POSTGRES_DB="$DB_NAME" \
        -p "$DB_PORT":5432 \
        -v __SLUG___pgdata:/var/lib/postgresql/data \
        postgres:16-alpine
      wait_for_db
    fi
    ;;

  stop)
    require_docker
    if docker ps --format '{{.Names}}' | grep -q "$CONTAINER_NAME"; then
      docker stop "$CONTAINER_NAME"
      success "PostgreSQL stopped"
    else
      warn "PostgreSQL is not running"
    fi
    ;;

  restart)
    require_docker
    $0 stop
    sleep 1
    $0 start
    ;;

  reset)
    require_docker
    warn "This will DROP and RECREATE the database. All data will be lost."
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      # Ensure container is running
      $0 start

      info "Dropping database..."
      docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -c "DROP DATABASE IF EXISTS $DB_NAME;"
      docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -c "CREATE DATABASE $DB_NAME;"
      success "Database recreated"

      info "Pushing schema..."
      pnpm --filter __SCOPE__/api db:push
      success "Schema pushed"

      info "Regenerating Prisma client..."
      pnpm --filter __SCOPE__/api db:generate
      success "Prisma client regenerated"

      # Run seed if it exists
      if [ -f "apps/api/src/prisma/seed.ts" ]; then
        info "Running seed..."
        pnpm --filter __SCOPE__/api db:seed
        success "Database seeded"
      fi

      success "Database reset complete"
    else
      info "Reset cancelled"
    fi
    ;;

  seed)
    info "Running database seed..."
    pnpm --filter __SCOPE__/api db:seed
    success "Database seeded"
    ;;

  studio)
    info "Opening Prisma Studio..."
    pnpm --filter __SCOPE__/api db:studio
    ;;

  migrate)
    MIGRATION_NAME="${2:-}"
    if [ -z "$MIGRATION_NAME" ]; then
      read -p "Migration name: " MIGRATION_NAME
    fi
    if [ -z "$MIGRATION_NAME" ]; then
      error "Migration name is required"
    fi
    info "Creating migration: $MIGRATION_NAME"
    pnpm --filter __SCOPE__/api exec prisma migrate dev \
      --schema=src/prisma/schema.prisma \
      --name "$MIGRATION_NAME"
    success "Migration created and applied"
    ;;

  push)
    info "Pushing schema to database..."
    pnpm --filter __SCOPE__/api db:push
    success "Schema pushed"
    ;;

  generate)
    info "Generating Prisma client..."
    pnpm --filter __SCOPE__/api db:generate
    success "Prisma client generated"
    ;;

  status)
    require_docker
    echo ""
    if docker ps --format '{{.Names}}' | grep -q "$CONTAINER_NAME"; then
      success "PostgreSQL is running"
      echo ""
      docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    elif docker ps -a --format '{{.Names}}' | grep -q "$CONTAINER_NAME"; then
      warn "PostgreSQL container exists but is stopped"
      echo "  Run: ./scripts/db.sh start"
    else
      warn "No PostgreSQL container found"
      echo "  Run: ./scripts/db.sh start"
    fi
    echo ""
    ;;

  logs)
    require_docker
    docker logs "$CONTAINER_NAME" --tail 50 -f
    ;;

  shell)
    require_docker
    info "Opening psql shell..."
    docker exec -it "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME"
    ;;

  help|*)
    echo ""
    echo -e "${BOLD}__DISPLAY_NAME__ Database Management${NC}"
    echo ""
    echo "Usage: ./scripts/db.sh <command>"
    echo ""
    echo "Commands:"
    echo "  start       Start PostgreSQL container"
    echo "  stop        Stop PostgreSQL container"
    echo "  restart     Restart PostgreSQL container"
    echo "  reset       Drop + recreate DB, push schema, seed"
    echo "  seed        Run database seed script"
    echo "  studio      Open Prisma Studio"
    echo "  migrate     Create a new Prisma migration"
    echo "  push        Push schema to DB (no migration)"
    echo "  generate    Regenerate Prisma client"
    echo "  status      Show container status"
    echo "  logs        Tail PostgreSQL logs"
    echo "  shell       Open psql interactive shell"
    echo ""
    ;;
esac
