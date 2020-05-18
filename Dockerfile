FROM ubuntu:20.04

RUN apt-get update && apt-get install -y openresolv iptables iproute2 wireguard

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
