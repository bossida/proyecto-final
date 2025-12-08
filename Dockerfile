FROM node:18-alpine
WORKDIR /tpfinal
COPY ./app/package*.json ./
RUN npm install
COPY ./app/index.js ./
EXPOSE 3000
CMD ["node", "index.js"]
