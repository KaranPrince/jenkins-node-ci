# Use official Node.js LTS image
FROM node:18-alpine

# Create app directory
WORKDIR /usr/src/app

# Copy package.json and install dependencies
COPY package*.json ./
RUN npm install --only=production

# Copy app source
COPY app/ ./app/

# Copy index.js
COPY index.js .

# Expose port
EXPOSE 80

# Start the app
CMD ["node", "index.js"]
