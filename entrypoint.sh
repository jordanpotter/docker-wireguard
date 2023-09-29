#!/bin/ash

set -e

default_route_ip=$(ip route | grep default | awk '{print $3}')
if [[ -z "$default_route_ip" ]]; then
	echo "No default route configured" >&2
	exit 1
fi

configs=`find /etc/wireguard -type f -printf "%f\n"`
if [[ -z "$configs" ]]; then
	echo "No configuration file found in /etc/wireguard" >&2
	exit 1
fi

config=`echo $configs | head -n 1`
interface="${config%.*}"

if [[ "$(cat /proc/sys/net/ipv4/conf/all/src_valid_mark)" != "1" ]]; then
	echo "sysctl net.ipv4.conf.all.src_valid_mark=1 is not set" >&2
	exit 1
fi

# The net.ipv4.conf.all.src_valid_mark sysctl is set when running the container, so don't have WireGuard also set it
sed -i "s:sysctl -q net.ipv4.conf.all.src_valid_mark=1:echo Skipping setting net.ipv4.conf.all.src_valid_mark:" /usr/bin/wg-quick

# Start WireGuard
wg-quick up $interface

# IPv4 kill switch: traffic must be either (1) to the WireGuard interface, (2) marked as a WireGuard packet, (3) to a local address, or (4) to the container network
container_ipv4_network="$(ip -o addr show dev eth0 | awk '$3 == "inet" {print $4}')"
container_ipv4_network_rule=$([ ! -z "$container_ipv4_network" ] && echo "! -d $container_ipv4_network" || echo "")
iptables -I OUTPUT ! -o $interface -m mark ! --mark $(wg show $interface fwmark) -m addrtype ! --dst-type LOCAL $container_ipv4_network_rule -j REJECT

# IPv6 kill switch: traffic must be either (1) to the WireGuard interface, (2) marked as a WireGuard packet, (3) to a local address, or (4) to the container network
container_ipv6_network="$(ip -o addr show dev eth0 | awk '$3 == "inet6" {print $4}')"
if [[ "$container_ipv6_network" ]]; then
	container_ipv6_network_rule=$([ ! -z "$container_ipv6_network" ] && echo "! -d $container_ipv6_network" || echo "")
	ip6tables -I OUTPUT ! -o $interface -m mark ! --mark $(wg show $interface fwmark) -m addrtype ! --dst-type LOCAL $container_ipv6_network_rule -j REJECT
else
	echo "IPv6 interface not found, skipping IPv6 kill switch" >&2
fi

# Allow traffic to local subnets
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
