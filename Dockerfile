# This uses the regular node image, which is based on Debian
FROM node:10.4
RUN apt-get update && apt-get install -y \
    build-essential

ENV NODE_ENV="production"
WORKDIR /home/node

COPY dist/planet9-linux bootstrap.sh LICENSES package* ./
COPY --chown=node config* ./config/

RUN sh bootstrap.sh

USER node
EXPOSE 8080

ENTRYPOINT [ "./planet9-linux" ]
