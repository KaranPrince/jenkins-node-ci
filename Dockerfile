# Stage 1: dependencies
FROM node:18-alpine AS deps
WORKDIR /usr/src/app
ENV NODE_ENV=production
COPY package*.json ./
# Deterministic first; if lock is stale in CI, fall back so image still builds
RUN npm ci --omit=dev --no-audit --no-fund || npm install --omit=dev --no-audit --no-fund

# Stage 2: runtime
FROM node:18-alpine
WORKDIR /usr/src/app
ENV NODE_ENV=production

RUN apk add --no-cache curl

COPY --from=deps /usr/src/app/node_modules ./node_modules
COPY app ./app

# Drop privileges
USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://localhost:3000/ || exit 1

CMD ["node", "app/server.js"]
