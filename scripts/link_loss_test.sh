#!/bin/bash

# Special credit to https://blogs.igalia.com/dpino/2016/05/02/network-namespaces-ipv6/

NETSNAME="mptcp_net"

if [[ $EUID -ne 0 ]]; then
   echo "You must run this script as root."
   exit 1
fi

VIRTUAL_ETH_1_HOST=veth3
VIRTUAL_ETH_1_NAMESPACE=vneth3
VETH1_ADDR_HOST=fd00::1
VNETH1_ADDR_NAMESPACE=fd00::2

IP6TABLE_NAME=mptcp_test_nat


ip netns del ${NETSNAME}
ip netns add ${NETSNAME}

# Create a virtual ethernet interface pair
ip link add ${VIRTUAL_ETH_1_HOST} type veth peer name ${VIRTUAL_ETH_1_NAMESPACE} netns ${NETSNAME}

# Set up veths (host)
ip -6 addr add ${VETH1_ADDR_HOST}/64 dev ${VIRTUAL_ETH_1_HOST}
ip link set dev ${VIRTUAL_ETH_1_HOST} up

# Set up veths (namespace)
ip netns exec ${NETSNAME} ip link set dev lo up
ip netns exec ${NETSNAME} ip -6 addr add ${VNETH1_ADDR_NAMESPACE}/64 dev ${VIRTUAL_ETH_1_NAMESPACE}
ip netns exec ${NETSNAME} ip link set dev ${VIRTUAL_ETH_1_NAMESPACE} up

# Set up default gateway (namespace)
ip netns exec ${NETSNAME} ip -6 route add default dev ${VIRTUAL_ETH_1_NAMESPACE} via ${VETH1_ADDR_HOST}
# TODO add rule and table for the second address

# Set up a NAT
sysctl -w net.ipv6.conf.all.forwarding=1
# TODO first ensure that no tables exist already
ip6tables -t ${IP6TABLE_NAME} --flush

ip netns exec ${NETSNAME} /bin/bash --rcfile <(echo "PS1=\"ns-ipv6> \"")

ip netns delete ${NETSNAME}
ip link delete ${VIRTUAL_ETH_1_HOST}
