# ---------- Build stage ----------
FROM node:18-alpine AS builder
WORKDIR /app

# Install dependencies first (cache-friendly)
COPY package*.json ./
RUN npm ci --no-audit --no-fund || npm install --no-audit --no-fund

# Copy rest of the app
COPY . .

# Run build steps (if you had TS transpile, asset build, etc.)
# For now, no-op since it's plain Node.js

# ---------- Runtime stage ----------
FROM node:18-alpine
ENV NODE_ENV=production
WORKDIR /app

# Create a non-root user
RUN addgroup -S app && adduser -S app -G app

# Install only production dependencies
COPY package*.json ./
RUN npm ci --omit=dev --no-audit --no-fund || npm install --omit=dev --no-audit --no-fund

# Copy built app from builder
COPY --from=builder /app/ /app/

USER app
EXPOSE 3000

CMD ["node", "app/server.js"]
