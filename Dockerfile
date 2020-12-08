FROM ubuntu:20.04

RUN apt-get update \
 && apt-get install -y --no-install-recommends openresolv iptables iproute2 wireguard \
 && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
