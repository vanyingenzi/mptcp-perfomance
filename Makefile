
#------------- Variables
MAKE=$(shell which make)
ECHO=$(shell which echo)
COLOR_ANNOUNCE='\033[0;36m'
NC='\033[0m'
#------------- 

all: setup

# Install the required packages
setup: set-folders
	apt -y install mptcpize
	chmod -R +x scripts/
	cd ./iperf && ./configure && $(MAKE)
	rm ./scripts/iperf3 && ln -s ./iperf/src/iperf3 ./scripts/iperf3


check-mptcp:
	@echo "Kernel version = `uname -r`"
	sysctl -a | grep mptcp
	ip mptcp limits show

set-folders:
	if [ -d "./logs/" ]; then\
		chmod -R +777 logs;\
	else\
		mkdir --mode=777 logs;\
	fi
	chmod -R +x scripts/

clean:
	if [ -d "./logs/" ]; then\
		rm -fr logs/*;\
		rmdir logs;\
	fi
	cd ./iperf && $(MAKE) clean

run-tcp-baseline: 
	@$(ECHO) -e "${COLOR_ANNOUNCE}------------------ TCP Baseline ------------------${NC}"
	./scripts/tcp_baseline.sh -d tfe-ingenzi-mbogne.info.ucl.ac.be -p 80