
# =============================================================================
# 🧩 restore.sh — STUB. This is YOUR work (graded). Do not expect it to run yet.
# =============================================================================
# GOAL
#   Restore a chosen backup (produced by backup.sh) into a target database, and
#   PROVE that CloudVault comes back to a working state afterwards.
#
# WHAT A DONE SOLUTION MUST DO (acceptance criteria)
#   [ ] Take arguments: which database, and which backup (e.g. "latest" or a key).
#   [ ] Fetch the dump from S3, decompress, and restore it into the target DB.
#   [ ] Be safe: refuse to clobber a non-empty DB unless an explicit --force is given.
#   [ ] After restore, run a sanity check (row counts / a known record) and report.
#   [ ] Exit non-zero on failure.
#
# HINTS (questions — NOT commands)
#   - What is your Recovery Point Objective (RPO) and Recovery Time Objective (RTO)?
#     How does backup frequency relate to RPO?
#   - How do you list available backups and pick the newest deterministically?
#   - What's the difference between restoring into a fresh DB vs. an existing one?
#     Which does your pipeline assume?
#   - Rehearse it: schedule a periodic restore into a throwaway DB to keep the
#     "backups actually work" guarantee honest.
#
# Definition of done for the whole backup/restore milestone:
#   You can delete a database, run restore.sh, and the app works again — demonstrated.
# =============================================================================
#!/usr/bin/env bash
# =============================================================================
# CloudVault — Smart Self-Configuring Restore Script
# =============================================================================
set -euo pipefail

# Load .env if present
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

TARGET_DB="${1:-}"
BACKUP_TARGET="${2:-latest}"
FORCE_FLAG="${3:-}"

if [ -z "${TARGET_DB}" ]; then
    echo "Usage: $0 <database_name> [backup_key|latest] [--force]"
    exit 1
fi

# Explicit port, user, and password mapping (overrides any stale shell variables)
case "${TARGET_DB}" in
    authdb)
        DB_PORT="5433"
        DB_USER="${AUTH_DB_USER:-auth}"
        DB_PASSWORD="${AUTH_DB_PASSWORD:-authpass}"
        ;;
    filesdb|notifdb)
        DB_PORT="5434"
        DB_USER="${FILES_DB_USER:-files}"
        DB_PASSWORD="${FILES_DB_PASSWORD:-filespass}"
        ;;
    *)
        echo "Error: Unknown target database '${TARGET_DB}'. Expected: authdb, filesdb, or notifdb."
        exit 1
        ;;
esac

DB_HOST="localhost"
AWS_ENDPOINT_URL="${AWS_ENDPOINT_URL:-http://localhost:4566}"
S3_BUCKET="${S3_BUCKET:-cloudvault-storage-dev-20260913184158502900000001}"

TIMESTAMP=$(date -u +"%Y%m%d_%H%M%Sz")
SCRATCH_DB="${TARGET_DB}_scratch_${TIMESTAMP}_$$"
OLD_ARCHIVE_DB="${TARGET_DB}_archive_${TIMESTAMP}"

# Safe cleanup: drops scratch database on failure or abrupt exit
cleanup() {
    local exit_code=$?
    if [ ${exit_code} -ne 0 ]; then
        echo "Error encountered. Cleaning up scratch database if present..."
        PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "postgres" -c \
            "DROP DATABASE IF EXISTS \"${SCRATCH_DB}\";" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

# 1. Privilege & Pre-flight Verification
echo "Verifying administrative privileges for user '${DB_USER}' on port ${DB_PORT}..."
PRIVILEGE_CHECK=$(PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "postgres" -t -A -c \
    "SELECT rolsuper OR rolcreatedb FROM pg_roles WHERE rolname = '${DB_USER}';" 2>/dev/null || echo "false")

if [ "${PRIVILEGE_CHECK}" != "t" ]; then
    echo "Error: Database user '${DB_USER}' lacks superuser or CREATEDB privileges required for safe swapping."
    exit 1
fi

# 2. Determine Backup Key from S3
if [ "${BACKUP_TARGET}" = "latest" ]; then
    echo "Resolving latest backup key from S3 for '${TARGET_DB}'..."
    S3_KEY=$(aws --endpoint-url="${AWS_ENDPOINT_URL}" s3 ls "s3://${S3_BUCKET}/backups/${TARGET_DB}/" | \
        awk '{print $4}' | \
        sort -r | \
        head -n 1)

    if [ -z "${S3_KEY}" ]; then
        echo "Error: No backups found for '${TARGET_DB}' in s3://${S3_BUCKET}/backups/${TARGET_DB}/."
        exit 1
    fi
    FULL_S3_PATH="s3://${S3_BUCKET}/backups/${TARGET_DB}/${S3_KEY}"
else
    FULL_S3_PATH="s3://${S3_BUCKET}/${BACKUP_TARGET}"
fi

# 3. Safety Flag Check
DB_EXISTS=$(PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "postgres" -t -A -c \
    "SELECT 1 FROM pg_database WHERE datname = '${TARGET_DB}';")

if [ "${DB_EXISTS}" = "1" ]; then
    TABLE_COUNT=$(PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${TARGET_DB}" -t -A -c \
        "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';")

    if [ "${TABLE_COUNT}" -gt 0 ] && [ "${FORCE_FLAG}" != "--force" ]; then
        echo "Error: Target database '${TARGET_DB}' is not empty (${TABLE_COUNT} tables found)."
        echo "Use '--force' as the 3rd argument to authorize swapping active databases."
        exit 1
    fi
fi

# 4. Provision Isolated Scratch Database
echo "Creating scratch database: ${SCRATCH_DB}..."
PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "postgres" -c \
    "CREATE DATABASE \"${SCRATCH_DB}\";"

# 5. Stream S3 to Memory Decompression & Restore
echo "Streaming backup from ${FULL_S3_PATH} directly into '${SCRATCH_DB}'..."
aws --endpoint-url="${AWS_ENDPOINT_URL}" s3 cp "${FULL_S3_PATH}" - | \
    gzip -dc | \
    PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${SCRATCH_DB}"

# 6. Post-Restore Verification
echo "Verifying restored schema inside scratch database..."
RESTORED_TABLES=$(PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${SCRATCH_DB}" -t -A -c \
    "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';")

if [ "${RESTORED_TABLES}" -eq 0 ]; then
    echo "Critical Failure: Verification found 0 tables inside '${SCRATCH_DB}'."
    echo "Restoration aborted. Original '${TARGET_DB}' remains active and untouched."
    exit 1
fi

echo "Verification successful: ${RESTORED_TABLES} tables confirmed."

# 7. Atomic Swap and Archive Preservation
echo "Promoting scratch database to target database..."

if [ "${DB_EXISTS}" = "1" ]; then
    PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "postgres" -c \
        "ALTER DATABASE \"${TARGET_DB}\" WITH ALLOW_CONNECTIONS false;" >/dev/null

    PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "postgres" -c \
        "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${TARGET_DB}' AND pid <> pg_backend_pid();" >/dev/null

    echo "Archiving existing database to '${OLD_ARCHIVE_DB}'..."
    PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "postgres" -c \
        "ALTER DATABASE \"${TARGET_DB}\" RENAME TO \"${OLD_ARCHIVE_DB}\";"
fi

PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "postgres" -c \
    "ALTER DATABASE \"${SCRATCH_DB}\" RENAME TO \"${TARGET_DB}\";"

if [ "${DB_EXISTS}" = "1" ]; then
    echo "Rollback safeguard: Previous database preserved as '${OLD_ARCHIVE_DB}'."
fi

echo "=== Restore completed safely! '${TARGET_DB}' is active with verified data. ==="
exit 0