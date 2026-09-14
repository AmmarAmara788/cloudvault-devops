#!/usr/bin/env bash
set -euo pipefail

# 1. Clean auth-db archives (Port 5433)
echo "Scanning for archive databases on auth-db (port 5433)..."
AUTH_ARCHIVES=$(PGPASSWORD="authpass" psql -h localhost -p 5433 -U auth -d postgres -t -A -c \
    "SELECT datname FROM pg_database WHERE datname LIKE '%_archive_%';" 2>/dev/null || true)

if [ -n "${AUTH_ARCHIVES}" ]; then
    for db in ${AUTH_ARCHIVES}; do
        echo "Dropping archive: ${db} on port 5433..."
        PGPASSWORD="authpass" psql -h localhost -p 5433 -U auth -d postgres -c "DROP DATABASE \"${db}\";"
    done
else
    echo "No archives found on port 5433."
fi

# 2. Clean files-db archives (Port 5434 - filesdb & notifdb)
echo "Scanning for archive databases on files-db (port 5434)..."
FILES_ARCHIVES=$(PGPASSWORD="filespass" psql -h localhost -p 5434 -U files -d postgres -t -A -c \
    "SELECT datname FROM pg_database WHERE datname LIKE '%_archive_%';" 2>/dev/null || true)

if [ -n "${FILES_ARCHIVES}" ]; then
    for db in ${FILES_ARCHIVES}; do
        echo "Dropping archive: ${db} on port 5434..."
        PGPASSWORD="filespass" psql -h localhost -p 5434 -U files -d postgres -c "DROP DATABASE \"${db}\";"
    done
else
    echo "No archives found on port 5434."
fi

echo "All archive databases cleaned up successfully!"