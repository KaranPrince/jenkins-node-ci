# Node runtime
FROM node:18-alpine

WORKDIR /usr/src/app

# Install only what runtime needs (no dev deps)
COPY package*.json ./
RUN npm install --omit=dev || npm install --only=production

# Copy app code
COPY app ./app

# Container port
EXPOSE 3000

# Start the server
CMD ["node", "app/server.js"]
