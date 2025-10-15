FROM 10.29.230.150:31381/library/m.daocloud.io/docker.io/node:6.11.0-alpine

WORKDIR /app
COPY . /app/

RUN npm config set registry http://nexus.daocloud.io/repository/daocloud-npm \
 && npm install

EXPOSE 3000
CMD ["npm","start"]
