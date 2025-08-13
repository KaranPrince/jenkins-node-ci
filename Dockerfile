FROM node:18-alpine

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install --production

COPY app ./app
COPY server.js ./

EXPOSE 80
CMD ["npm", "start"]
