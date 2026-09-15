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
FROM node:20-alpine@sha256:fb4cd12c85ee03686f6af5362a0b0d56d50c58a04632e6c0fb8363f609372293 AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --legacy-peer-deps

COPY . .
RUN npm run build

# =============================================================================
# Stage 2: Runtime Stage (Serve static files using secured Nginx)
# =============================================================================
FROM nginx:alpine@sha256:72ba65eb42c10344912a84ff42408db7d34f2feb642204570ab8fc5ffd29f1d3

# Hardening: Upgrade OS packages and configure Nginx to run as non-root
RUN apk upgrade --no-cache \
    && sed -i 's/listen  *80;/listen 8080;/g' /etc/nginx/conf.d/default.conf \
    && chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d \
    && touch /var/run/nginx.pid \
    && chown -R nginx:nginx /var/run/nginx.pid

COPY --from=builder --chown=nginx:nginx /app/dist /usr/share/nginx/html

# Switch to standard non-root user
USER nginx

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]