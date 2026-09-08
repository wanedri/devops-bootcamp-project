# syntax=docker/dockerfile:1

# Multi-stage build for Infratify/ship (Vite + Three.js static site).
#
# Stage 1 needs the whole Node toolchain to produce dist/.
# Stage 2 needs none of it - just nginx and the built assets. The runtime
# image therefore carries no node_modules, no npm, and no source code, which
# is the entire point of going multi-stage.

# ---------------------------------------------------------------- build stage
FROM node:22-alpine AS builder

# vite.config.js shells out to `git rev-parse --short HEAD` to stamp the commit
# onto the telemetry HUD. It falls back to "dev" if git is missing, so this
# line is what makes the HUD show a real SHA.
RUN apk add --no-cache git

WORKDIR /app

# Manifests first: this layer is cached and only re-runs when dependencies
# change, so editing ship.config.json doesn't reinstall three.js.
COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# The repo's own pre-flight gate. A malformed ship.config.json exits non-zero
# and fails the image build here, rather than shipping a broken site.
RUN npm test

RUN npm run build

# -------------------------------------------------------------- runtime stage
FROM nginx:1.27-alpine AS runtime

# vite is configured with base './' so the assets resolve correctly from the
# server root with no extra nginx config.
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

# nginx:alpine's default CMD already runs nginx in the foreground.
