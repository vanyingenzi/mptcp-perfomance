
#------------- Variables
MAKE=$(shell which make)
PRINTF=$(shell which printf)
COLOR_ANNOUNCE=$(tput setaf 4)
NC=$(tput sgr0)
PYTHON=$(shell which python3)
#------------- 

all: setup

# Install the required packages
setup: set-folders
	apt -y install mptcpize
	cd ./iperf && ./configure && $(MAKE)
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

run-tcp-baseline: 
	@$(PRINTF) "%s\n" "${COLOR_ANNOUNCE}------------------ TCP Baseline (w/ 2001:6a8:308f:9:0:82ff:fe68:e519) ------------------${NC}"
	./scripts/tcp_baseline_test.sh -d 2001:6a8:308f:9:0:82ff:fe68:e519 -p 80 -n 15
	@$(PRINTF) "%s\n" "${COLOR_ANNOUNCE}------------------ TCP Baseline (w/ 2001:6a8:308f:9:0:82ff:fe68:e55c) ------------------${NC}"
	./scripts/tcp_baseline_test.sh -d 2001:6a8:308f:9:0:82ff:fe68:e55c -p 80 -n 15
	@$(PRINTF) "%s\n" "${COLOR_ANNOUNCE}------------------ TCP Baseline (w/ 2001:6a8:308f:10:0:83ff:fe00:2) ------------------${NC}"
	./scripts/tcp_baseline_test.sh -d 2001:6a8:308f:10:0:83ff:fe00:2 -p 80 -n 15

visualise-tcp-baseline:
	@$(PYTHON) ./utils/json_throughput_plot.py ./utils/baseline_json_throughput_plot.json

run-aggregation-test:
	@$(PRINTF) "%s\n" "${COLOR_ANNOUNCE}------------------ Aggregation Test ------------------${NC}"
	./scripts/aggregation_test.sh -d 2001:6a8:308f:9:0:82ff:fe68:e519 -p 80 -n 15

visualise-aggregation-test:
	@$(PYTHON) ./utils/json_throughput_plot.py ./utils/aggregation_json_throughput_plot.json

run-link-failure-test:
	@$(PRINTF) "%s\n" "${COLOR_ANNOUNCE}------------------ Link failure Test ------------------${NC}"
	./scripts/link_failure_test.sh -d 2001:6a8:308f:9:0:82ff:fe68:e519 -p 80 -n 1 -t 10

visualise-link-failure-test:
	@$(PYTHON) ./utils/json_throughput_plot.py ./utils/link_failure_throughput_plot.json

run-all: run-tcp-baseline run-aggregation-test run-link-failure-test