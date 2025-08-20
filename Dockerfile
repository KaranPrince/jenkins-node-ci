# Use a multi-stage build to keep the final image tiny and clean
FROM node:18-alpine AS deps
WORKDIR /usr/src/app
ENV NODE_ENV=production
COPY package*.json ./
# Reproducible installs; omit dev deps; no audit/fund noise
RUN npm ci --omit=dev --no-audit --no-fund

FROM node:18-alpine AS runtime
WORKDIR /usr/src/app
ENV NODE_ENV=production

# Add curl in a single layer (used by HEALTHCHECK)
RUN apk add --no-cache curl

# Copy only what we need
COPY --from=deps /usr/src/app/node_modules ./node_modules
COPY app ./app

# Run as the non-root 'node' user that ships with the image
USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://localhost:3000/ || exit 1

CMD ["node", "app/server.js"]
