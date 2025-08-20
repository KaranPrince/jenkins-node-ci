# ---------- Build stage ----------
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Install dependencies only when needed
COPY package*.json ./

# Install all dependencies (including dev)
RUN npm install --frozen-lockfile

# Copy source code
COPY . .

# Run build step if needed (e.g., transpile TypeScript or bundle)
# RUN npm run build

# ---------- Production stage ----------
FROM node:18-alpine

WORKDIR /app

# Copy only production dependencies
COPY package*.json ./
RUN npm install --production --frozen-lockfile

# Copy built app from builder stage
COPY --from=builder /app . 

# Expose app port
EXPOSE 3000

# Run the app
CMD ["node", "app.js"]
