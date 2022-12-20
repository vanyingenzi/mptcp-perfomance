
#------------- Variables
MAKE=$(shell which make)
PRINTF=$(shell which printf)
COLOR_ANNOUNCE='\033[0;36m'
NC='\033[0m'
PYTHON=$(shell which python3)
#------------- 

all: setup

# Install the required packages
setup: set-folders
	apt -y install mptcpize
	cd ./iperf && ./configure && $(MAKE)
	ln -s ./iperf/src/iperf3 ./scripts/iperf3
	chmod -R +x scripts/

check-mptcp:
	@(PRINTF) "Kernel version = `uname -r`"
	sysctl -a | grep mptcp
	ip mptcp limits show

set-folders:
	if [ -d "./logs/" ]; then\
		chmod -R +777 logs;\
	else\
		mkdir --mode=777 logs;\
	fi
	chmod -R +x scripts/
	chmod -R +x utils/

clean: clean-logs
	cd ./iperf && $(MAKE) clean
	rm ./scripts/iperf3 

clean-logs:
	if [ -d "./logs/" ]; then\
		rm -fr logs/*;\
		rmdir logs;\
	fi

run-tcp-baseline: 
	@$(PRINTF) "${COLOR_ANNOUNCE}------------------ TCP Baseline (w/ 2001:6a8:308f:9:0:82ff:fe68:e519) ------------------${NC}\n"
	./scripts/tcp_baseline_test.sh -d 2001:6a8:308f:9:0:82ff:fe68:e519 -p 80 -n 1
	@$(PRINTF) "${COLOR_ANNOUNCE}------------------ TCP Baseline (w/ 2001:6a8:308f:9:0:82ff:fe68:e55c) ------------------${NC}\n"
	./scripts/tcp_baseline_test.sh -d 2001:6a8:308f:9:0:82ff:fe68:e55c -p 80 -n 1
	@$(PRINTF) "${COLOR_ANNOUNCE}------------------ TCP Baseline (w/ 2001:6a8:308f:10:0:83ff:fe00:2) ------------------${NC}\n"
	./scripts/tcp_baseline_test.sh -d 2001:6a8:308f:10:0:83ff:fe00:2 -p 80 -n 1

visualise-tcp-baseline:
	@$(PYTHON) ./utils/json_throughput_plot.py ./utils/baseline_json_throughout_plot.json

run-aggregation-test:
	@$(PRINTF) "${COLOR_ANNOUNCE}------------------ Aggregation Test ------------------${NC}\n"
	./scripts/aggregation_test.sh -d 2001:6a8:308f:9:0:82ff:fe68:e519 -p 80 -n 3

visualise-aggregation-test:
	@$(PYTHON) ./utils/json_throughput_plot.py ./utils/aggregation_json_throughout_plot.json
