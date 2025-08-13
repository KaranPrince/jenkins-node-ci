# Use Node.js LTS
FROM node:18

# Set working directory
WORKDIR /app

# Copy package.json & package-lock.json first
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy the rest of the application
COPY . .

# Expose port 3000
EXPOSE 3000

# Start the app
CMD ["node", "server.js"]
