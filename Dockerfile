# Stage 1: install dependencies
FROM node:18-alpine AS deps
WORKDIR /usr/src/app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --omit=dev --no-audit --no-fund

# Stage 2: runtime
FROM node:18-alpine
WORKDIR /usr/src/app
ENV NODE_ENV=production

RUN apk add --no-cache curl

# Copy deps + app code
COPY --from=deps /usr/src/app/node_modules ./node_modules
COPY app ./app

# Run as non-root user (security best practice)
USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://localhost:3000/ || exit 1

CMD ["node", "app/server.js"]
