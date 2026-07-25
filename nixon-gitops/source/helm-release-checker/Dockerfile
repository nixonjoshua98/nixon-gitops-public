FROM alpine:3

ARG HELM_VERSION=v4.2.3

RUN apk add --no-cache bash ca-certificates curl jq tar \
    && curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" -o /tmp/helm.tgz \
    && tar -xzf /tmp/helm.tgz -C /tmp \
    && mv /tmp/linux-amd64/helm /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && rm -rf /tmp/helm.tgz /tmp/linux-amd64

WORKDIR /app

COPY main.sh /app/main.sh

RUN chmod +x /app/main.sh

ENTRYPOINT ["/app/main.sh"]