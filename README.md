# Debugger

A simple docker image that provides the tools: **curl**, **dig**, **iptables**, **mysql**, **ncat**, **redis-cli**, **tcpdump**, **traceroute**, **wget**, **smtp-cli**

## Usage

### Docker

```bash
$ docker run -it --rm gizzmoasus/debugger:1.2.0 nslookup kelcode.co.uk
Server:         000.000.000.000
Address:        000.000.000.000#53

Non-authoritative answer:
Name:   kelcode.co.uk
Address: ###.###.###.###
```

### Kubernetes

Create a simple deployment as follows:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: debugger
spec:
  containers:
  - name: debugger
    image: gizzmoasus/debugger:latest
    command:
      - sleep
      - "infinity"
    imagePullPolicy: Always
  restartPolicy: Always
```

Apply this to your cluster `$ kubectl apply -f debugger.yaml --namespace=testing` and check it's running with `$ kubectl get pods`.

```bash
$ k get pods --namespace=testing
NAME                                 READY   STATUS    RESTARTS      AGE
debugger                             1/1     Running   0             68s
```

You can now use the tools as normal i.e.

```bash
$ kubectl exec -it debugger -- nslookup kelcode.co.uk
Server:         000.000.000.000
Address:        000.000.000.000#53

Non-authoritative answer:
Name:   kelcode.co.uk
Address: ###.###.###.###

$ kubectl exec -it debugger -- dig kelcode.co.uk

; <<>> DiG 9.18.19 <<>> kelcode.co.uk
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 27610
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;kelcode.co.uk.                 IN      A

;; ANSWER SECTION:
kelcode.co.uk.          60      IN      A       ###.###.###.###

$ k exec -it debugger -- redis-cli -h redis.redis.svc.cluster.local -p 6379 -a $PASSWORD ping
PONG
```

## Dockerfile

```dockerfile
FROM alpine:3.20.3

# Define redis and smtp-cli details
ARG REDIS_VERSION="7.4.1"
ARG REDIS_URL="http://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz"
ARG SMTP_CLI_VERSION="v3.10"
ARG SMTP_CLI_URL="https://github.com/mludvig/smtp-cli/archive/refs/tags/${SMTP_CLI_VERSION}.tar.gz"
ARG PERL_MODULES="IO::Socket::SSL Net::SSLeay IO::Socket::INET6 Socket6 Digest::HMAC Term::ReadKey MIME::Lite File::LibMagic Digest::HMAC_MD5 Net::DNS"

# Create a non-root user with specific UID (1001)
RUN addgroup -S appgroup && adduser -S -u 1001 -G appgroup appuser

# Install build and runtime dependencies
RUN apk add --no-cache \
    gcc \
    make \
    linux-headers \
    musl-dev \
    tar \
    openssl-dev \
    pkgconfig \
    perl-dev \
    file-dev \
    zlib-dev \
    bind-tools \
    curl \
    mysql-client \
    nmap-ncat \
    iptables \
    perl \
    tcpdump \
    traceroute \
    wget \
    libmagic \
    openssl

# Install cpanminus for installing Perl modules
RUN curl -L https://cpanmin.us | perl - App::cpanminus

# Install Perl modules
RUN cpanm --notest ${PERL_MODULES}

# Install redis-cli
RUN wget -O redis.tar.gz "${REDIS_URL}" \
  && mkdir -p /usr/src/redis \
  && tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 \
  && cd /usr/src/redis/src \
  && make BUILD_TLS=yes MALLOC=libc redis-cli \
  && cp redis-cli /usr/local/bin/ \
  && chmod +x /usr/local/bin/redis-cli \
  && rm -rf /usr/src/redis

# Install smtp-cli
RUN wget -O smtp-cli.tar.gz "${SMTP_CLI_URL}" \
  && mkdir -p /usr/src/smtp-cli \
  && tar -xzf smtp-cli.tar.gz -C /usr/src/smtp-cli --strip-components=1 \
  && cd /usr/src/smtp-cli/ \
  && cp smtp-cli /usr/local/bin/ \
  && chmod +x /usr/local/bin/smtp-cli \
  && rm -rf /usr/src/smtp-cli

# Change ownership of binaries to the non-root user
RUN chown appuser:appgroup /usr/local/bin/redis-cli /usr/local/bin/smtp-cli

# Clean up
RUN apk del \
    gcc \
    make \
    linux-headers \
    musl-dev \
    openssl-dev \
    pkgconfig \
    perl-dev \
    file-dev \
    zlib-dev \
  && rm -rf /root/.cpanm /var/cache/apk/*

# Switch to the non-root user
USER 1001

```

Total size: **106.89MiB**

## Changelog

2024-10-11:

* Added smtp-cli (https://github.com/mludvig/smtp-cli)
* Switched to a non-root image
* Updated deps for alpine (3.20.3) and redis (7.4.1)

