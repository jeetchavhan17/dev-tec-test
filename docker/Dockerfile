# docker/Dockerfile
FROM node:18-alpine

WORKDIR /usr/src/app

COPY app/package.json ./
RUN npm install --production

COPY app/ ./

ENV PORT=3000
EXPOSE 3000

CMD ["node", "server.js"]

