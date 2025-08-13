# Use official Node.js image
FROM node:18

# Create app directory
WORKDIR /usr/src/app

# Copy package.json and install dependencies
COPY app/package*.json ./
RUN npm install

# Copy the rest of the application files
COPY app/ .

# Expose the app port to 3000
EXPOSE 3000

# Start the app
CMD ["node", "server.js"]
