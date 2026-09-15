# =============================================================================
# auth-service — DELIBERATELY NAIVE image (it works, but it is not production-grade)
# =============================================================================
# This builds and runs. Making it *good* is your graded work. Do NOT look for a
# hardened Dockerfile elsewhere in the repo — there isn't one on purpose.
#
# TODO (student): harden this image. Acceptance criteria in k8s/HINTS.md, but at
# minimum address every point below:
#   - [ ] Multi-stage build: builder installs deps, final stage copies only what runs.
#   - [ ] Smaller base: node:20-slim or a distroless/runtime image.
#   - [ ] Pin the base by digest (FROM node:20@sha256:...) for reproducibility.
#   - [ ] Run as non-root (add `USER node`, ensure file ownership is correct).
#   - [ ] Prod-only, reproducible install (`npm ci --omit=dev`) with a committed lockfile.
#   - [ ] Improve .dockerignore so build context stays small.
#   - Done when: `docker scout` / `trivy image` shows no HIGH/CRITICAL you introduced,
#     the image runs as UID != 0, and final image size is a fraction of this one.
# -----------------------------------------------------------------------------
# =============================================================================
# Stage 1: Builder Stage (Build environment & dependencies)
# =============================================================================
# Pinning base image by digest for 100% reproducibility and security
# Multi-stage build pinned by strict digest for security and reproducibility
FROM node:20-alpine@sha256:fb4cd12c85ee03686f6af5362a0b0d56d50c58a04632e6c0fb8363f609372293 AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

# =============================================================================
# Stage 2: Runtime / Production Stage (Secure execution environment)
# =============================================================================
# Use the exact same pinned image digest
# Production runtime stage
FROM node:20-alpine@sha256:fb4cd12c85ee03686f6af5362a0b0d56d50c58a04632e6c0fb8363f609372293

WORKDIR /app

# Security Hardening: Upgrade OS packages and completely remove npm to eliminate its vulnerabilities
RUN apk upgrade --no-cache \
    && rm -rf /usr/local/lib/node_modules/npm \
    && rm -f /usr/local/bin/npm \
    && rm -f /usr/local/bin/npx

COPY --from=builder --chown=node:node /app/package.json ./
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
COPY --from=builder --chown=node:node /app/src ./src

USER node

EXPOSE 3001

CMD ["node", "src/index.js"]
