FROM node:18-alpine

WORKDIR /usr/src/app

# copy package files (root)
COPY package*.json ./

# install production deps
RUN npm ci --omit=dev || npm install --only=production

# optional: add curl for healthcheck inside container
RUN apk add --no-cache curl

# copy the app folder (server.js and index.html live under app/)
COPY app ./app

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://localhost:3000/ || exit 1

CMD ["node", "app/server.js"]
