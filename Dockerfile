# Use official Node.js LTS image as base
FROM node:18-alpine

# Set working directory inside container
WORKDIR /usr/src/app

# Copy package files first for dependency caching
COPY package*.json ./

# Install dependencies
RUN npm install --only=production

# Copy app source code
COPY app/ ./app/

# Expose app port
EXPOSE 3000

# Start the application
CMD ["node", "app/server.js"]
