# ---------- Build stage ----------
FROM node:18 AS build
WORKDIR /app

# Copy dependency files, install
COPY package*.json ./
RUN npm ci || npm install

# Copy the rest
COPY . .

# ---------- Runtime stage ----------
FROM node:18-alpine
WORKDIR /app

# Copy built app & node_modules from build stage
COPY --from=build /app /app

EXPOSE 3000
CMD ["node", "app/server.js"]
