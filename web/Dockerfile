# =============================================================================
# web (React + Vite) — DELIBERATELY NAIVE image running the Vite DEV server.
# It works and hot-reloads, but it is NOT how you ship a frontend.
#
# TODO (student): this is prime hardening/optimization territory.
#   - [ ] Multi-stage build: `vite build` in a builder stage, then serve the
#         static `dist/` from a tiny web server (nginx:alpine or similar).
#   - [ ] Do not ship the dev server or node_modules to production.
#   - [ ] Non-root, pinned base, .dockerignore.
#   - Done when: the final image serves prebuilt static assets and is a fraction
#     of this image's size.
# =============================================================================
# =============================================================================
# Stage 1: Build Stage (Build Vite/React static assets)
# =============================================================================
FROM node:20-slim@sha256:2cf067cfed83d5ea958367df9f966191a942351a2df77d6f0193e162b5febfc0 AS builder

WORKDIR /app

# Copy dependency specifications
COPY package*.json ./

# Install all dependencies (including devDependencies needed for build)
RUN  npm ci --legacy-peer-deps

# Copy source code
COPY . .

# Build static production assets
RUN npm run build

# =============================================================================
# Stage 2: Runtime Stage (Serve static files using Nginx)
# =============================================================================
FROM nginx:1.25-alpine

# Copy built assets from builder stage to Nginx public directory
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose web port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]