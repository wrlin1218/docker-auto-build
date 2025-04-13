FROM alpine:latest

ARG VERSION

WORKDIR /realm

RUN apk add --no-cache && \
    mkdir -p /etc/realm

COPY realm /usr/local/bin/realm
RUN chmod +x /usr/local/bin/realm

ENTRYPOINT ["/usr/local/bin/realm", "-c", "/etc/realm/config.toml"]