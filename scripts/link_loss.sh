#!/bin/bash

function Help {
   echo "Simulates temporal link loss" >&2
   echo >&2
   echo "Syntax: $0 [-i ETH] [-d DELAY] " >&2
   echo "i ETH      : ETH is the interface name." >&2
   echo "d DELAY    : The DELAY seconds of which the link is down." >&2
   echo "h          : Prints this help." >&2
}

unset -v DELAY
unset -v ETH

while getopts ":i:d:h" option; do
    case $option in
        h) # display Help
            Help
            exit;;
        d)
            DELAY=${OPTARG} ;;
        i)
            ETH=${OPTARG} ;;
        \?) # incorrect option
            echo "Error: Invalid option" >&2
            exit 1;;
    esac
done

shift "$(( OPTIND - 1 ))"

if [ -z "${DELAY}" ] || [ -z "${ETH}" ]; then
    echo "Missing -i or -d" >&2
    exit 1
fi

ip link set down ${ETH}
if [ "$?" != "0" ]; then 
    exit 1
fi
sleep ${DELAY}
ip link set up ${ETH}