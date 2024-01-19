# Debugger

A simple docker image that provides the tools: **curl**, **dig**, **iptables**, **mysql**, **ncat**, **redis-cli**, **tcpdump**, **traceroute**, **wget**

## Usage

### Docker

```bash
$ docker run -it --rm gizzmoasus/debugger:1.2.0 nslookup kelcode.co.uk
Server:         192.168.65.7
Address:        192.168.65.7#53

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
Server:         10.96.0.10
Address:        10.96.0.10#53

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
```

Total size: **94.09MiB**