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
FROM node:20-slim@sha256:2cf067cfed83d5ea958367df9f966191a942351a2df77d6f0193e162b5febfc0 AS builder

WORKDIR /app

# Copy package configurations first to leverage Docker layer caching
COPY package*.json ./

# Install strictly production dependencies to reduce image size and attack surface
RUN npm ci --omit=dev

# Copy the application source code
COPY . .

# =============================================================================
# Stage 2: Runtime / Production Stage (Secure execution environment)
# =============================================================================
# Use the exact same pinned image digest
FROM node:20-slim@sha256:2cf067cfed83d5ea958367df9f966191a942351a2df77d6f0193e162b5febfc0

WORKDIR /app

# Copy files from builder stage and immediately assign ownership to the built-in 'node' user
COPY --from=builder --chown=node:node /app/package.json ./
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
COPY --from=builder --chown=node:node /app/src ./src

# Switch to the built-in non-root user (UID 1000) for security
USER node

EXPOSE 3001

CMD ["npm", "start"]
