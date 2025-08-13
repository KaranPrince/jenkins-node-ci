# ---------- Stage 1: Build dependencies ----------
FROM node:18 AS build

# Set working directory
WORKDIR /usr/src/app

# Copy package.json and package-lock.json from root
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy application source
COPY app/ ./app

# ---------- Stage 2: Production image ----------
FROM node:18-slim

# Set working directory
WORKDIR /usr/src/app

# Copy dependencies from build stage
COPY --from=build /usr/src/app/node_modules ./node_modules

# Copy application files
COPY --from=build /usr/src/app/app ./app
COPY package*.json ./

# Expose application port
EXPOSE 3000

# Run the server
CMD ["node", "app/server.js"]
