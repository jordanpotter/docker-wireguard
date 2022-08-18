#!/bin/bash

set -e

default_route_ip=$(ip route | grep default | awk '{print $3}')
if [[ -z "$default_route_ip" ]]; then
    echo "No default route configured" >&2
    exit 1
fi

configs=`find /etc/wireguard -type f -printf "%f\n"`
if [[ -z "$configs" ]]; then
    echo "No configuration files found in /etc/wireguard" >&2
    exit 1
fi

config=`echo $configs | head -n 1`
interface="${config%.*}"

if [[ "$(cat /proc/sys/net/ipv4/conf/all/src_valid_mark)" != "1" ]]; then
    echo "sysctl net.ipv4.conf.all.src_valid_mark=1 is not set" >&2
    exit 1
fi

# The net.ipv4.conf.all.src_valid_mark sysctl is set when running the Docker container, so don't have WireGuard also set it
sed -i "s:sysctl -q net.ipv4.conf.all.src_valid_mark=1:echo Skipping setting net.ipv4.conf.all.src_valid_mark:" /usr/bin/wg-quick
wg-quick up $interface

# IPv4 kill switch: traffic must be either (1) to the WireGuard interface, (2) marked as a WireGuard packet, (3) to a local address, or (4) to the Docker network
docker_network="$(ip -o addr show dev eth0 | awk '$3 == "inet" {print $4}')"
docker_network_rule=$([ ! -z "$docker_network" ] && echo "! -d $docker_network" || echo "")
iptables -I OUTPUT ! -o $interface -m mark ! --mark $(wg show $interface fwmark) -m addrtype ! --dst-type LOCAL $docker_network_rule -j REJECT

# IPv6 kill switch: traffic must be either (1) to the WireGuard interface, (2) marked as a WireGuard packet, (3) to a local address, or (4) to the Docker network
docker6_network="$(ip -o addr show dev eth0 | awk '$3 == "inet6" {print $4}')"
if [[ "$docker6_network" ]]; then
    docker6_network_rule=$([ ! -z "$docker6_network" ] && echo "! -d $docker6_network" || echo "")
    ip6tables -I OUTPUT ! -o $interface -m mark ! --mark $(wg show $interface fwmark) -m addrtype ! --dst-type LOCAL $docker6_network_rule -j REJECT
else
    echo "Skipping IPv6 kill switch setup since IPv6 interface was not found" >&2
fi

# Support LOCAL_NETWORK environment variable, which was replaced by LOCAL_SUBNETS
if [[ -z "$LOCAL_SUBNETS" && "$LOCAL_NETWORK" ]]; then
    LOCAL_SUBNETS=$LOCAL_NETWORK
fi

# Support LOCAL_SUBNET environment variable, which was replaced by LOCAL_SUBNETS (plural)
if [[ -z "$LOCAL_SUBNETS" && "$LOCAL_SUBNET" ]]; then
    LOCAL_SUBNETS=$LOCAL_SUBNET
fi

# Hack to allow upstream port forwarding through a VPN provider
if [[ -z "$PORT_FORWARD_DEST" && "$PORT_FORWARD_TO" ]]; then
    echo "Doing port forward from port ${PORT_FORWARD_TO} to destination port ${PORT_FORWARD_DEST}" >&2
    iptables -t nat -I PREROUTING -p tcp --dport $PORT_FORWARD_DEST -j REDIRECT --to $PORT_FORWARD_TO
fi

for local_subnet in ${LOCAL_SUBNETS//,/$IFS}
do
    echo "Allowing traffic to local subnet ${local_subnet}" >&2
    ip route add $local_subnet via $default_route_ip
    iptables -I OUTPUT -d $local_subnet -j ACCEPT
done

shutdown () {
    wg-quick down $interface
    exit 0
}

trap shutdown SIGTERM SIGINT SIGQUIT

sleep infinity &
wait $!
