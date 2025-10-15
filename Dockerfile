FROM node:6.11-0-alpine

WORKDIR /app

COPY . /app/

RUN npm config set registry http://nexus.daocloud.io/repository/daocloud-npm
RUN npm install

EXPOSE 3000

CMD npm start