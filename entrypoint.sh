#!/bin/bash

set -e

interfaces=`find /etc/wireguard -type f`
if [[ -z $interfaces ]]; then
    echo "No interface found in /etc/wireguard" >&2
    exit 1
fi

interface=`echo $interfaces | head -n 1`

wg-quick up $interface

shutdown () {
    wg-quick down $interface
    exit 0
}

trap shutdown SIGTERM SIGINT SIGQUIT

sleep infinity &
wait $!
