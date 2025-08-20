# ---------- Build stage ----------
FROM node:18-alpine AS builder
WORKDIR /app

# Install exact deps from lockfile (deterministic)
COPY package*.json ./
RUN npm ci --no-audit --no-fund

# Copy source and (optionally) build
COPY . .
# RUN npm run build

# Keep only production dependencies for the runtime image
RUN npm prune --omit=dev

# ---------- Runtime stage ----------
FROM node:18-alpine
ENV NODE_ENV=production
WORKDIR /app

# Non-root user
RUN addgroup -S app && adduser -S app -G app

# Copy app with pruned prod deps
COPY --from=builder /app/ /app/

USER app
EXPOSE 3000
CMD ["node", "app.js"]
