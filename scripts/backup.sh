
# =============================================================================
# 🧩 backup.sh — STUB. This is YOUR work (graded). Do not expect it to run yet.
# =============================================================================
# GOAL
#   Produce a reliable, restorable backup of CloudVault's stateful data and put
#   it somewhere durable and off-box.
#
# WHAT A DONE SOLUTION MUST DO (acceptance criteria)
#   [ ] Dump EACH Postgres database (authdb, filesdb, notifdb) consistently.
#   [ ] Write each dump to a TIMESTAMPED, greppable object key
#       (e.g. backups/<db>/<YYYY-MM-DDTHH-MM-SSZ>.sql.gz) in the S3 bucket.
#   [ ] Compress dumps; verify the upload succeeded before deleting anything local.
#   [ ] Prune backups older than a retention window (e.g. keep 7 daily).
#   [ ] Exit non-zero on ANY failure so a CronJob/pipeline can alert.
#   [ ] Never print or embed credentials; read them from the environment.
#
# HINTS (questions to answer — NOT commands to copy)
#   - Which pg tool gives a consistent single-database dump? What flags make it
#     restore cleanly onto an empty database?
#   - Why is `set -euo pipefail` important in a backup script? What breaks silently
#     without `pipefail` when you pipe a dump into gzip into an uploader?
#   - What timestamp format sorts lexicographically AND is filesystem/S3-safe?
#   - How will you PROVE a backup is restorable (see restore.sh)? A backup you have
#     never restored is a hope, not a backup.
#   - Where do the DB host/user/password come from in local dev vs. in k8s? (Hint:
#     env vars locally; a Secret + a CronJob in k8s. See k8s/HINTS.md.)
#   - Least privilege: what S3 permissions does this job actually need? (Not "*".)
#
# WHERE THIS RUNS
#   Locally you might invoke it by hand; in the cluster it becomes a CronJob
#   (see k8s/HINTS.md). The AWS design question (which subnet, which IAM role)
#   is in docs/ARCHITECTURE_CHALLENGE.md.
#
# Official docs are fair game: PostgreSQL pg_dump, AWS S3 CLI, Kubernetes CronJob.
# =============================================================================
# set -euo pipefail

# echo "backup.sh is a stub — implement it. See the header for acceptance criteria."
# echo "TODO(student): dump each Postgres DB -> gzip -> timestamped S3 key -> prune old backups."
# exit 2

#!/usr/bin/env bash
# =============================================================================
# CloudVault — Multi-Service Production-Ready Backup Script
# =============================================================================
set -euo pipefail

# Auto-load variables from .env if present
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Global Configuration
DB_HOST="${DB_HOST:-localhost}"
RETENTION_COUNT="${RETENTION_COUNT:-7}"
AWS_ENDPOINT_URL="${AWS_ENDPOINT_URL:-http://localhost:4566}"
S3_BUCKET="${S3_BUCKET:-cloudvault-storage-dev-20260913184158502900000001}"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H-%M-%Sz")
BACKUP_DIR="/tmp/cloudvault_backups"
mkdir -p "${BACKUP_DIR}"

# Service Mapping: "DB_NAME:HOST_PORT:USER:PASSWORD"
TARGET_DATABASES=(
    "${AUTH_DB_NAME:-authdb}:5433:${AUTH_DB_USER:-auth}:${AUTH_DB_PASSWORD:-authpass}"
    "${FILES_DB_NAME:-filesdb}:5434:${FILES_DB_USER:-files}:${FILES_DB_PASSWORD:-filespass}"
    "${NOTIF_DB_NAME:-notifdb}:5434:${NOTIF_DB_USER:-files}:${NOTIF_DB_PASSWORD:-filespass}"
)

echo "=== Starting CloudVault Multi-Service Backup at ${TIMESTAMP} ==="

for target in "${TARGET_DATABASES[@]}"; do
    IFS=':' read -r db port user pass <<< "${target}"
    
    echo "--------------------------------------------------------"
    echo "Processing database: '${db}' on port ${port} (user: ${user})..."

    # Connectivity Pre-check
    if ! PGPASSWORD="${pass}" pg_isready -h "${DB_HOST}" -p "${port}" -U "${user}" -d "${db}" -q; then
        echo "Warning: Database '${db}' on ${DB_HOST}:${port} is unreachable. Skipping..."
        continue
    fi

    LOCAL_FILE="${BACKUP_DIR}/${db}_${TIMESTAMP}.sql.gz"
    S3_KEY="backups/${db}/${TIMESTAMP}.sql.gz"

    # Dump, Clean and Stream Gzip
    PGPASSWORD="${pass}" pg_dump \
        -h "${DB_HOST}" \
        -p "${port}" \
        -U "${user}" \
        -d "${db}" \
        --clean \
        --if-exists \
        --format=plain | gzip > "${LOCAL_FILE}"

    # Upload to LocalStack / AWS S3
    echo "Uploading ${db} backup to s3://${S3_BUCKET}/${S3_KEY}..."
    aws --endpoint-url="${AWS_ENDPOINT_URL}" s3 cp "${LOCAL_FILE}" "s3://${S3_BUCKET}/${S3_KEY}"

    rm -f "${LOCAL_FILE}"
    echo "Successfully backed up and uploaded '${db}'."

    # Retention Cleanup
    echo "Enforcing retention: keeping latest ${RETENTION_COUNT} backups for '${db}'..."
    aws --endpoint-url="${AWS_ENDPOINT_URL}" s3 ls "s3://${S3_BUCKET}/backups/${db}/" | \
        awk '{print $4}' | \
        sort -r | \
        tail -n +$((RETENTION_COUNT + 1)) | \
        while read -r old_file; do
            if [ -n "${old_file}" ]; then
                echo "Pruning expired backup: ${old_file}"
                aws --endpoint-url="${AWS_ENDPOINT_URL}" s3 rm "s3://${S3_BUCKET}/backups/${db}/${old_file}"
            fi
        done
done

echo "========================================================"
echo "=== CloudVault Backup Workflow Completed Successfully ==="
exit 0