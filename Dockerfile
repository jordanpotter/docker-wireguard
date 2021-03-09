FROM alpine:3.12.1

RUN apk add --no-cache \
      openresolv iptables ip6tables iproute2 wireguard-tools \
      findutils # Needed for find's -printf flag

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
