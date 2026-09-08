# =============================================================================
# thumbnail-worker — DELIBERATELY NAIVE image (works, not production-grade).
# See services/auth-service/Dockerfile for the full hardening checklist.
# TODO (student): multi-stage, non-root, slim base, pinned digest, npm ci.
# Note: image processing libs can pull native deps — mind the final image size.
# =============================================================================
# =============================================================================
# Stage 1: Builder Stage (Build environment & dependencies)
# =============================================================================
FROM node:20-slim@sha256:2cf067cfed83d5ea958367df9f966191a942351a2df77d6f0193e162b5febfc0 AS builder

WORKDIR /app

# Copy package files for dependency caching
COPY package*.json ./

# Install exact production dependencies securely (including native builds if required)
RUN npm ci --omit=dev

# Copy application source code
COPY . .

# =============================================================================
# Stage 2: Runtime / Production Stage (Secure execution environment)
# =============================================================================
FROM node:20-slim@sha256:2cf067cfed83d5ea958367df9f966191a942351a2df77d6f0193e162b5febfc0

WORKDIR /app

# Copy necessary production files and assign ownership to the built-in 'node' user
COPY --from=builder --chown=node:node /app/package.json ./
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
COPY --from=builder --chown=node:node /app/src ./src

# Switch to the non-root user (UID 1000)
USER node

# Expose the health check port for the worker
EXPOSE 3005

CMD ["npm", "start"]