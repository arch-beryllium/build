#!/bin/bash
if [ "$(id -u)" -ne "0" ]; then
  echo "This script requires root."
  exit 1
fi

sysctl net.ipv4.ip_forward=1
iptables -P FORWARD ACCEPT
iptables -A POSTROUTING -t nat -j MASQUERADE -s 10.15.19.0/24
