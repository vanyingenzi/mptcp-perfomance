#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "You must run this script as root."
   exit 1
fi

function Help {
    echo "Runs a TCP Iperf perfomance analysis." >&2
    echo >&2
    echo "Syntax: $0 [-d DEST] [-p PORT] [-n NUM] [-h]" >&2
    echo "options:" >&2
    echo "d DEST : DEST is the address of the Iperf server to connect to." >&2
    echo "p PORT : PORT is the port of the Iperf server to connect to." >&2
    echo "n NUM  : NUM indicates the number of times we have to perfom the test."
    echo "h : Prints this help." >&2
}

DEST_ADDRESS=""
DPORT=""
BIND_ADDRESS=""
while getopts "d:b:p:h" option; do
    case $option in
        h)
            Help
            exit;;
        p) 
            DPORT=${OPTARG} ;;
        d)
            DEST_ADDRESS=${OPTARG} ;;
        b)
            BIND_ADDRESS=${OPTARG} ;;
        \?)
            echo "Error: Invalid option" >&2
            Help
            exit 1;;
    esac
done

# mandatory arguments
if [ ! "${DEST_ADDRESS}" ] || [ ! "${DPORT}" ]; then
    echo "Arguments [-d DEST] [-p DPORT] [-n NUM] must be provided."
    Help
    exit 1
fi

./iperf/src/iperf3 -c ${DEST_ADDRESS} -p ${DPORT}