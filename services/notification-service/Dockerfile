# =============================================================================
# notification-service — DELIBERATELY NAIVE image (works, not production-grade).
# See services/auth-service/Dockerfile for the full hardening checklist.
# TODO (student): multi-stage, non-root, slim base, pinned digest, npm ci.
# =============================================================================]
# =============================================================================
# Stage 1: Builder Stage (Build environment & dependencies)
# =============================================================================
# Use pinned slim base image for reproducibility and smaller footprint
FROM node:20-slim@sha256:2cf067cfed83d5ea958367df9f966191a942351a2df77d6f0193e162b5febfc0 AS builder

WORKDIR /app

# Copy package files first to utilize Docker layer caching
COPY package*.json ./

# Install exact production dependencies (npm ci) without dev dependencies
RUN npm ci --omit=dev

# Copy the application source code
COPY . .

# =============================================================================
# Stage 2: Runtime / Production Stage (Secure execution environment)
# =============================================================================
# Use the exact same pinned digest for consistency
FROM node:20-slim@sha256:2cf067cfed83d5ea958367df9f966191a942351a2df77d6f0193e162b5febfc0

WORKDIR /app

# Copy necessary runtime files and assign ownership to the built-in 'node' user
COPY --from=builder --chown=node:node /app/package.json ./
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
COPY --from=builder --chown=node:node /app/src ./src

# Switch to the non-root user (UID 1000)
USER node

# Expose the notification service port
EXPOSE 3004

CMD ["npm", "start"]