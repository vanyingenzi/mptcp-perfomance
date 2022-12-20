#!/bin/bash
function Help {
    echo "Runs a MPTCP iPerf perfomance analysis." >&2
    echo >&2
    echo "Syntax: $0 [-d DEST] [-p PORT] [-n NUM] [-h]" >&2
    echo "options:" >&2
    echo "d DEST : DEST is the address of the Iperf server to connect to." >&2
    echo "p PORT : PORT is the port of the Iperf server to connect to." >&2
    echo "n NUM  : NUM indicates the number of times we have to perfom the test for each mptcp endpoint." >&2
    echo "h : Prints this help." >&2
}

YELLOW='\033[0;33m'     
RED='\033[0;31m'
NC='\033[0m'
DEST_ADDRESS=""
DPORT=""
BIND_ADDRESS=""
NUMBER_OF_TIMES="1"


function echo_command {
    printf "${YELLOW}${1}${NC}\n" >&2
}

function echo_error {
    printf "${RED}${1}${NC}\n" >&2
}


while getopts "d:b:p:n:h" option; do
    case $option in
        h)
            Help
            exit;;
        p) 
            DPORT=${OPTARG} ;;
        n)
            NUMBER_OF_TIMES=${OPTARG} ;;
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

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_mptcp_endpoints
#   DESCRIPTION:  Returns a list of all mptcp endpoint 
#-------------------------------------------------------------------------------
function get_mptcp_endpoints {
    echo `ip mptcp endpoint | awk -F " " '{print $1}'`
}

DEST_FOLDER="./logs/aggregation"
[ ! -d "./logs/aggregation" ] && mkdir "./logs/aggregation"
[ ! -d ${DEST_FOLDER} ] && mkdir ${DEST_FOLDER}


for iter in $(seq 1 ${NUMBER_OF_TIMES})
do
    TARGET_FILE="${DEST_FOLDER}/${iter}.json"
    [ -f ${TARGET_FILE} ] && rm ${TARGET_FILE}
    echo_command "./iperf/src/iperf3 -c ${DEST_ADDRESS} -J -m -p ${DPORT} -t 2 --logfile ${TARGET_FILE}"
    ./iperf/src/iperf3 -c ${DEST_ADDRESS} -J -m -p ${DPORT}-t 10 --logfile ${TARGET_FILE}
    exit_code=$?
    [ "${exit_code}" != "0" ] && echo_error "An error occured during the last execution : ${exit_code}" && exit ${exit_code}
    echo_command "sleep 60 ..."
    sleep 60
done