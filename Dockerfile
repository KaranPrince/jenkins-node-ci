# ---------- Build stage ----------
FROM node:18-alpine AS builder
WORKDIR /app

# copy only dependency files first (better caching)
COPY package*.json ./

# use BuildKit cache mount for npm
RUN --mount=type=cache,target=/root/.npm \
    if [ -f package-lock.json ]; then \
      npm ci --no-audit --no-fund; \
    else \
      npm install --no-audit --no-fund; \
    fi

# now copy the rest of the source
COPY . .

# prune devDependencies
RUN npm prune --omit=dev

# ---------- Runtime stage ----------
FROM node:18-alpine
WORKDIR /app
ENV NODE_ENV=production

# create app user
RUN addgroup -S app && adduser -S app -G app

# copy only production node_modules and source
COPY --from=builder /app /app

USER app
EXPOSE 3000
CMD ["node", "app/server.js"]
