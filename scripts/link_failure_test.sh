#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "You must run this script as root."
   exit 1
fi

function Help {
    echo "Runs a MPTCP iPerf perfomance analysis with link failures." >&2
    echo >&2
    echo "Syntax: $0 [-d DEST] [-p PORT] [-n NUM] [-t DELAY] [-o OFFSET] [-h]" >&2
    echo "options:" >&2
    echo "d DEST    : DEST is the address of the Iperf server to connect to." >&2
    echo "p PORT    : PORT is the port of the Iperf server to connect to." >&2
    echo "n NUM     : NUM indicates the number of times we have to perfom the test for each mptcp endpoint." >&2
    echo "t DELAY   : DELAY indicates time of the link failure. This is repeated for each link." >&2
    echo "o OFFSET  : The amount of seconds from the start of the transfer to start simulating link failures. Default 30."
    echo "h : Prints this help." >&2
}

YELLOW=$(tput setaf 3)    
RED=$(tput setaf 1)
NC=$(tput sgr0)

function echo_command {
    printf "%s\n" "${YELLOW}${1}${NC}" >&2
}

function echo_error {
    printf "%s\n" "${RED}${1}${NC}" >&2
}

DEST_ADDRESS=""
DPORT=""
DELAY=""
NUMBER_OF_TIMES=""
OFFSET=30

while getopts "d:p:n:t:o:h" option; do
    case $option in
        d) 
            DEST_ADDRESS=${OPTARG} ;;
        p)
            DPORT=${OPTARG} ;;
        n)
            NUMBER_OF_TIMES=${OPTARG} ;;
        t)
            DELAY=${OPTARG} ;;
        o) 
            OFFSET=${OPTARG} ;;
        h)  # display Help
            Help
            exit ;;
        \?) # incorrect option
            echo "Error: Invalid option" >&2
            exit 1 ;;
    esac
done

# mandatory arguments
if [ ! "${DEST_ADDRESS}" ] || [ ! "${DPORT}" ] || [ ! "${NUMBER_OF_TIMES}" ] || [ ! "${DELAY}" ]; then
    echo "Arguments [-d DEST] [-p DPORT] [-n NUM] must be provided."
    Help
    exit 1
fi

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_mptcp_endpoints
#   DESCRIPTION:  Returns a list of all mptcp endpoint 
#-------------------------------------------------------------------------------
function get_interface_used_by_mptcp_endpoints {
    ip mptcp endpoint show | awk -F "dev" '{print $2}' | awk -F " " '{print $1}' | sort | uniq
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  simulate_link_failure
#   DESCRIPTION:  Shuts the L2 layer of the interface using ip link then restarts it.
#-------------------------------------------------------------------------------
function simulate_link_failure {
    echo_command "ip link set down ${1}"
    if ! ip link set down "${1}"; then 
        exit 1
    fi
    echo_command "sleep ${DELAY}"
    sleep "${DELAY}"
    echo_command "ip link set up ${1}"
    ip link set up "${1}"
}

DEST_FOLDER="./logs/link-failure"
[ ! -d "./logs/link-failure" ] && mkdir "./logs/link-failure"
[ ! -d "${DEST_FOLDER}" ] && mkdir "${DEST_FOLDER}"

for iter in $(seq 1 "${NUMBER_OF_TIMES}")
do
    IPERF_LOG_FILE="${DEST_FOLDER}/${iter}.json"
    [ -f "${IPERF_LOG_FILE}" ] && rm "${IPERF_LOG_FILE}"
    MONITOR_FILE="${DEST_FOLDER}/${iter}.txt" 
    [ -f "${MONITOR_FILE}" ] && rm "${MONITOR_FILE}"

    echo_command "ip mptcp monitor > ${MONITOR_FILE} &"
    ip mptcp monitor > "${MONITOR_FILE}" &
    monitor_pid=$!

    echo_command "./iperf/src/iperf3 -c ${DEST_ADDRESS} -J -6 -R -m -p ${DPORT} -t 120 --logfile ${IPERF_LOG_FILE}"
    ./iperf/src/iperf3 -c "${DEST_ADDRESS}" -J -6 -R -m -p "${DPORT}" -t 120 --logfile "${IPERF_LOG_FILE}" & # Launch Iperf
    iperf_pid=$!
    
    sleep "${OFFSET}"
    for interface in $(get_interface_used_by_mptcp_endpoints)
    do
        if ps -p ${iperf_pid} > /dev/null; then 
            simulate_link_failure "${interface}"
            sleep 30
        else 
            printf "%s\n" "Didn't perfom link simulation on interface : ${interface}, iPerf was done."
        fi
    done

    wait "${iperf_pid}"
    exit_code=$?

    kill -SIGINT "${monitor_pid}" > /dev/null

    [ "${exit_code}" != "0" ] && echo_error "An error occured during the last execution : ${exit_code}" && exit ${exit_code}
    echo_command "sleep 60 ..."
    sleep 60
done