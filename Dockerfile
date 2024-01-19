FROM alpine:3.19.0

# Define redis details
ARG REDIS_VERSION="7.2.4"
ARG REDIS_URL="http://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz"

# Install tools
RUN apk add --update \
    gcc \
    make \
    linux-headers \
    musl-dev \
    tar \
    openssl-dev \
    pkgconfig \
    bind-tools \
    curl \
    mysql-client \
    nmap-ncat \
    iptables \
    tcpdump \
    traceroute \
    wget

# Install redis-cli
RUN wget -O redis.tar.gz "${REDIS_URL}" \
  && mkdir -p /usr/src/redis \
  && tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 \
  && cd /usr/src/redis/src \
  && make BUILD_TLS=yes MALLOC=libc redis-cli \
  && cp redis-cli /usr/local/bin/ \
  && chmod +x /usr/local/bin/redis-cli \
  && rm -r /usr/src/redis

# Clean up
RUN apk del \
    gcc \
    linux-headers \
    make \
    musl-dev \
    openssl-dev \
    pkgconfig \
    tar \
  && rm -rf /var/cache/apk/*
