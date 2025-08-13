# Use Node.js LTS
FROM node:18

# Set working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package.json package-lock.json* ./
RUN npm install

# Copy the rest of the code
COPY . .

# Expose app port
EXPOSE 3000

# Run the server.js from /app/app folder
CMD ["node", "app/server.js"]
