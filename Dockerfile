FROM ubuntu:latest

RUN apt-get update && apt-get install -y software-properties-common openresolv iptables iproute2
RUN add-apt-repository ppa:wireguard/wireguard && apt-get update && apt-get install -y wireguard-tools

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
