#!/bin/bash

# Launches standard Iperf3 client
SERVER_HOST="tfe-ingenzi-mbogne.info.ucl.ac.be"
SERVER_PORT=80

Help()
{
   echo "Launches a iPerf3 client" >&2
   echo >&2
   echo "Syntax: $0 -s SERVER_NAME -p PORT_NUMBER" >&2
   echo "options:" >&2
   echo "p PORT_NUMBER  : Launches server at port PORT_NUMBER." >&2
   echo "s HOST         : The incoming interface. Default localhost." >&2
   echo "h              : Prints this help." >&2
}

while getopts ":p:s:h" option; do
    case $option in
        h) # display Help
            Help
            exit;;
        p)
            SERVER_PORT=${OPTARG} ;;
        s)
            SERVER_HOST=${OPTARG} ;;
        \?) # incorrect option
            echo "Error: Invalid option" >&2
            exit 1;;
    esac
done

# Launches the iperf3 client

# 1. In client -> server
iperf3 -c ${SERVER_HOST} -p ${SERVER_PORT} -t 30
# 2. In server -> client
iperf3 -c ${SERVER_HOST} -p ${SERVER_PORT} -R -t 30

exit $?