#!/bin/bash

# Launches standard Iperf3 server at a given port with a screen
BIND_HOST=130.104.229.25

Help()
{
   echo "Launches a iPerf3 server at a given port" >&2
   echo >&2
   echo "Syntax: $0 -p PORT_NUMBER -l LOG_FILE -B HOST" >&2
   echo "options:" >&2
   echo "p PORT_NUMBER  : Launches server at port PORT_NUMBER." >&2
   echo "l LOG_FILE     : File to write logs." >&2
   echo "b HOST         : The incoming interface. Default localhost." >&2
   echo "h              : Prints this help." >&2
}

while getopts ":p:l:b:h" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      p)
         PORT_NUMBER=${OPTARG} ;;
      b)
         BIND_HOST=${OPTARG} ;;
      l)
         LOG_FILE=${OPTARG} ;;
      \?) # incorrect option
         echo "Error: Invalid option" >&2
         exit 1;;
   esac
done

if [ $OPTIND -eq 1 ]; then 
   Help;
   exit 1; 
fi

shift $((OPTIND - 1))

if [ -z "$LOG_FILE" ] || [ -z "$PORT_NUMBER" ]; then
   echo "Missing -p or -l arguments. Please run :" >&2
   echo "$0 -h" >&2
   echo "For more information." >&2
   exit 1
fi

# Launches the iPerf Server 
touch ${LOG_FILE}
nohup iperf3 -s -J -B ${BIND_HOST} -p ${PORT_NUMBER} --logfile ${LOG_FILE} 2>&1 1>/dev/null &

echo "Launched the server process"
exit 0