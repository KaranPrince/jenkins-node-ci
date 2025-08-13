# Use Node.js LTS
FROM node:18

# Set working directory
WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy rest of the application
COPY . .

# Expose port
EXPOSE 3000

# Start app
CMD ["npm", "start"]
