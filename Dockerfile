FROM node:18-alpine

WORKDIR /usr/src/app

# copy only package files first for better caching
COPY package*.json ./

# install prod deps
RUN npm ci --omit=dev || npm install --only=production

# add curl for container healthcheck
RUN apk add --no-cache curl

# copy server and static assets
COPY server.js ./server.js
COPY app ./app

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://localhost:3000/ || exit 1

CMD ["node", "server.js"]
