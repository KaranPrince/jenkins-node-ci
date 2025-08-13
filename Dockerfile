# ---------------------------
# 1. Base image
# ---------------------------
FROM node:18-alpine AS base

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json first for caching
COPY package*.json ./

# Install dependencies (production by default, tests will run in Jenkins before this step)
RUN npm install --production

# Copy application files
COPY . .

# ---------------------------
# 2. Production stage
# ---------------------------
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy only necessary files from build stage
COPY --from=base /app /app

# Expose the app port
EXPOSE 3000

# Start the application
CMD ["node", "server.js"]
