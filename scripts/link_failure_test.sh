#!/bin/bash

function Help {
    echo "Runs a MPTCP iPerf perfomance analysis with link failures." >&2
    echo >&2
    echo "Syntax: $0 [-d DEST] [-p PORT] [-n NUM] [-t DELAY] [-h]" >&2
    echo "options:" >&2
    echo "d DEST : DEST is the address of the Iperf server to connect to." >&2
    echo "p PORT : PORT is the port of the Iperf server to connect to." >&2
    echo "n NUM  : NUM indicates the number of times we have to perfom the test for each mptcp endpoint." >&2
    echo "t DELAY : DELAY indicates time of the link failure will perfom this for each link." >&2
    echo "h : Prints this help." >&2
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