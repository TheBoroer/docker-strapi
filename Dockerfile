FROM node:10.16.0-alpine

RUN echo http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && apk update && \
    apk add --no-cache bash \
    openssh-client \
    wget \
    curl \
    bc \
    gcc \
    python \
    python-dev \
    py-pip \
    openssl-dev \
    ca-certificates \
    git \
    make
    
RUN mkdir /app
WORKDIR /app

RUN echo "unsafe-perm = true" >> ~/.npmrc

RUN npm install -g strapi@3.0.0-beta.9

COPY start.sh ./
RUN chmod +x ./start.sh

EXPOSE 1337

COPY healthcheck.js ./
HEALTHCHECK --interval=15s --timeout=5s --start-period=30s \
      CMD node /app/healthcheck.js

CMD ["./start.sh"]
