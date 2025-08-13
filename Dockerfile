# Use official Node.js LTS image
FROM node:18-alpine

# Set working directory
WORKDIR /usr/src/app

# Copy package.json and install dependencies
COPY package.json package-lock.json* ./ 
RUN npm install --production

# Copy app code
COPY index.js ./ 
COPY app/ ./app

# Expose port
EXPOSE 80

# Run the Node.js server
CMD ["npm", "start"]
