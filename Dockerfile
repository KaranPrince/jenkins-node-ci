# Use official Node.js LTS image
FROM node:18

# Set working directory
WORKDIR /usr/src/app

# Copy package.json and install dependencies
COPY package*.json ./
RUN npm install

# Copy application source code
COPY . .

# Expose application port
EXPOSE 3000

# Run the app
CMD ["node", "app/server.js"]
