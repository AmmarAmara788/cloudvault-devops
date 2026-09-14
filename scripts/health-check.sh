#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== Checking CloudVault System Health ==="

check_endpoint() {
    local name="$1"
    local url="$2"
    if curl -fsS -m 3 "${url}" > /dev/null 2>&1; then
        printf "[  ${GREEN}OK${NC}  ] %s (%s)\n" "${name}" "${url}"
    else
        printf "[ ${RED}FAIL${NC} ] %s (%s)\n" "${name}" "${url}"
        return 1
    fi
}

check_internal_node() {
    local service="$1"
    local port="$2"
    if docker compose exec -T "${service}" node -e "fetch('http://localhost:${port}/healthz').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))" > /dev/null 2>&1; then
        printf "[  ${GREEN}OK${NC}  ] %s (internal port %s)\n" "${service}" "${port}"
    else
        printf "[ ${RED}FAIL${NC} ] %s (internal port %s)\n" "${service}" "${port}"
        return 1
    fi
}

ERRORS=0

# 1. Edge & Frontend Services (Accessible from Host)
check_endpoint "Frontend UI" "http://localhost:5173" || ERRORS=$((ERRORS + 1))
check_endpoint "API Gateway" "http://localhost:8080/healthz" || ERRORS=$((ERRORS + 1))
check_endpoint "LocalStack S3" "http://localhost:4566/_localstack/health" || ERRORS=$((ERRORS + 1))

# 2. Internal Microservices (Docker Network)
check_internal_node "auth-service" "3001" || ERRORS=$((ERRORS + 1))
check_internal_node "files-service" "3002" || ERRORS=$((ERRORS + 1))
check_internal_node "upload-service" "3003" || ERRORS=$((ERRORS + 1))
check_internal_node "notification-service" "3004" || ERRORS=$((ERRORS + 1))
check_internal_node "thumbnail-worker" "3005" || ERRORS=$((ERRORS + 1))

# 3. Databases & Cache
if docker compose exec -T redis redis-cli ping | grep -q "PONG"; then
    printf "[  ${GREEN}OK${NC}  ] redis (cache/broker)\n"
else
    printf "[ ${RED}FAIL${NC} ] redis (cache/broker)\n"
    ERRORS=$((ERRORS + 1))
fi

if docker compose exec -T auth-db pg_isready -q; then
    printf "[  ${GREEN}OK${NC}  ] auth-db (Postgres 5433)\n"
else
    printf "[ ${RED}FAIL${NC} ] auth-db (Postgres 5433)\n"
    ERRORS=$((ERRORS + 1))
fi

if docker compose exec -T files-db pg_isready -q; then
    printf "[  ${GREEN}OK${NC}  ] files-db (Postgres 5434)\n"
else
    printf "[ ${RED}FAIL${NC} ] files-db (Postgres 5434)\n"
    ERRORS=$((ERRORS + 1))
fi

echo "========================================="
if [ "${ERRORS}" -eq 0 ]; then
    printf "${GREEN}All services are healthy and operational!${NC}\n"
    exit 0
else
    printf "${RED}Health check failed with %s error(s).${NC}\n" "${ERRORS}"
    exit 1
fi