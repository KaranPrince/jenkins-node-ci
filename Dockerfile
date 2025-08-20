# ---------- Build stage ----------
FROM node:18-alpine AS builder
WORKDIR /app

COPY package*.json ./
RUN npm ci --no-audit --no-fund

COPY . .
RUN npm prune --omit=dev

# ---------- Runtime stage ----------
FROM node:18-alpine
ENV NODE_ENV=production
WORKDIR /app

RUN addgroup -S app && adduser -S app -G app

COPY --from=builder /app/ /app/

USER app
EXPOSE 3000
CMD ["node", "app/server.js"]
