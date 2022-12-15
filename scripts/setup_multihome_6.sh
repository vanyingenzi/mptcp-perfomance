#!/bin/bash

DEBUG=0
QUIET=0

if [[ $EUID -ne 0 ]]; then
   echo "You must run this script as root."
   exit 1
fi

function Help {
   echo "Sets up multihoming on a linux host" >&2
   echo >&2
   echo "Syntax: $0 [OPTIONS] " >&2
   echo "options:" >&2
   echo "d : Launches in debug mode." >&2
   echo "q : Doesn't print the commands exeuted" >&2
   echo "h : Prints this help." >&2
}

while getopts ":dqh" option; do
    case $option in
        h) # display Help
            Help
            exit;;
        d)
            DEBUG=1 ;;
        q)
            QUIET=1 ;;
        \?) # incorrect option
            echo "Error: Invalid option" >&2
            exit 1;;
    esac
done

function echo_debug {
    if [ "${DEBUG}" == "1" ]; then
        echo -e "$1" >&2
    fi
}

function echo_command {
    if [ "${QUIET}" == "0" ]; then
        echo -e "${YELLOW}${1}${NC}" >&2
    fi
}

YELLOW='\033[0;33m'     
NC='\033[0m'

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  getInterfaces
#   DESCRIPTION:  Lists out the current interfaces
#-------------------------------------------------------------------------------
function get_interfaces {
    echo `ls /sys/class/net`
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_addr_4_interface
#   DESCRIPTION:  Lists Ipv6 address gloabal dynamic with prefixes for a given interface
#-------------------------------------------------------------------------------
function get_addr_4_interface {
    echo `ip -6 addr show dev $1 | grep "global dynamic" | awk -F "scope" '{print $1}'| awk -F " " '{print $2}'`
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_gateway
#   DESCRIPTION:  Returns the gateway of a certain interface.
#-------------------------------------------------------------------------------
function get_gateway {
    gateway_for_interface=`ip -6 route | grep via | grep $1 | awk -F "dev" '{print $1}' | awk -F "via " '{print $2}'`
    if [ "${gateway_for_interface}" == "" ]; then 
        echo `ip -6 route | grep -m 1 via | awk -F "dev" '{print $1}' | awk -F "via " '{print $2}'`
    else 
        echo ${gateway_for_interface}
    fi
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_next_table_number
#   DESCRIPTION:  Returns an available number for a route table
#-------------------------------------------------------------------------------
function get_next_table_number {
    current_max_table=`ip -6 rule show all | grep lookup | sed 's/.*\(lookup.*\)/\1/g' | grep -Eo '[0-9]+' | awk '{for(i=1;i<=NF;i++) if($i>maxval) maxval=$i;}; END { print maxval;}'`
    if [ "${current_max_table}" == "" ]; then
        echo "1"
    else 
        let current_max_table=current_max_table+1
        echo ${current_max_table}
    fi
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_address_without_prefix
#   DESCRIPTION:  Removes the perfix from an IP address
#-------------------------------------------------------------------------------
function get_address_without_prefix {
    echo "$1" | awk -F "/" '{print $1}'
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_interface_status
#   DESCRIPTION:  Returns the status of the interface
#-------------------------------------------------------------------------------
function get_interface_status {
    echo `cat /sys/class/net/${1}/operstate`
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_up_interfaces
#   DESCRIPTION:  Perfoms a check up to see if it's multihoming host
#-------------------------------------------------------------------------------
function get_up_interfaces {
    COUNT=0
    for interface in $(get_interfaces); do
        if [ "${interface}" != "lo" ] && [ "$(get_interface_status ${interface})" == "up" ]; then
            let COUNT=COUNT+1
        fi
    done
    echo_debug "The number of up interfaces (except local) $COUNT"
    echo $COUNT
}

if [ $(get_up_interfaces) -lt "2" ]; then
    echo "The number of up interfaces is lower than 2 ... not a multihomed environment." >&2
    exit 1
fi

echo_command "ip mptcp endpoint flush"
ip mptcp endpoint flush
ENDPOINT_ID=1

for interface in $(get_interfaces); do
    addresses=$(get_addr_4_interface ${interface})
    gateway=$(get_gateway ${interface})
    if [ "${addresses}" != "" ] && [ "${gateway}" != "" ]; then
        echo_debug "${interface}"
        echo_debug "\t Gateway : ${gateway}"
        table_number=$(get_next_table_number)
        echo_debug "\t Table number : ${table_number}"
        for address_prefix in ${addresses}; do 
            echo_debug "\t Address : ${address_prefix}"
            echo_command "ip -6 rule add from $(get_address_without_prefix ${address_prefix}) table ${table_number}"
            ip -6 rule add from $(get_address_without_prefix ${address_prefix}) table ${table_number}
            echo_command "ip -6 route add ${address_prefix} dev ${interface} scope link table ${table_number}"
            ip -6 route add ${address_prefix} dev ${interface} scope link table ${table_number}
            echo_command "ip mptcp endpoint add $(get_address_without_prefix ${address_prefix}) id ${ENDPOINT_ID} dev ${interface} subflow signal"
            ip mptcp endpoint add $(get_address_without_prefix ${address_prefix}) id ${ENDPOINT_ID} dev ${interface} subflow signal
            let ENDPOINT_ID=ENDPOINT_ID+1
        done
        echo_command "ip -6 route add default via ${gateway} dev ${interface} table ${table_number}"
        ip -6 route add default via ${gateway} dev ${interface} table ${table_number}
        echo_debug "-----"
    fi
done

echo_command "ip mptcp limits set add_addr_accepted 8 subflows 8"
ip mptcp limits set add_addr_accepted 8 subflows 8