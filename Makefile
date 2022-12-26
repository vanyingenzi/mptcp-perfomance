
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

run-aggregation-fullmesh-test:
	@$(PRINTF) "%s\n" "${COLOR_ANNOUNCE}------------------ Aggregation Test ------------------${NC}"
	./scripts/aggregation_test.sh -d 2001:6a8:308f:9:0:82ff:fe68:e519 -p 80 -n 15 -f ./logs/aggregation_fullmesh

visualise-aggregation-fullmesh-test-throughput:
	@$(PYTHON) ./utils/json_throughput_plot.py ./utils/aggregation_fullmesh_json_throughput_plot.json

visualise-aggregation-fullmesh-test-bandwith-usage:
	@$(PYTHON) ./utils/pcap_plot.py ./utils/aggregation_fullmesh_pcap_subflow_plot.json

run-aggregation-nofullmesh-test:
	@$(PRINTF) "%s\n" "${COLOR_ANNOUNCE}------------------ Aggregation Test ------------------${NC}"
	./scripts/aggregation_test.sh -d 2001:6a8:308f:9:0:82ff:fe68:e519 -p 80 -n 15 -f ./logs/aggregation_nofullmesh

visualise-aggregation-nofullmesh-test-throughput:
	@$(PYTHON) ./utils/json_throughput_plot.py ./utils/aggregation_nofullmesh_json_throughput_plot.json

visualise-aggregation-nofullmesh-test-bandwith-usage:
	@$(PYTHON) ./utils/pcap_plot.py ./utils/aggregation_nofullmesh_pcap_subflow_plot.json

run-link-failure-fullmesh-test:
	@$(PRINTF) "%s\n" "${COLOR_ANNOUNCE}------------------ Link failure Test ------------------${NC}"
	./scripts/link_failure_test.sh -d 2001:6a8:308f:9:0:82ff:fe68:e519 -p 80 -n 15 -t 10 -o 30 -f ./logs/link-failure-fullmesh

visualise-link-failure-fullmesh-test-throughput:
	@$(PYTHON) ./utils/json_throughput_plot.py ./utils/link_failure_fullmesh_throughput_plot.json

visualise-link-failure-fullmesh-test-bandwith-usage:
	@$(PYTHON) ./utils/pcap_plot.py ./utils/link_failure_fullmesh_pcap_subflow_plot.json

run-link-failure-nofullmesh-test:
	@$(PRINTF) "%s\n" "${COLOR_ANNOUNCE}------------------ Link failure Test ------------------${NC}"
	./scripts/link_failure_test.sh -d 2001:6a8:308f:9:0:82ff:fe68:e519 -p 80 -n 15 -t 10 -o 30 -f ./logs/link-failure-nofullmesh

visualise-link-failure-nofullmesh-test-throughput:
	@$(PYTHON) ./utils/json_throughput_plot.py ./utils/link_failure_nofullmesh_throughput_plot.json

visualise-link-failure-nofullmesh-test-bandwith-usage:
	@$(PYTHON) ./utils/pcap_plot.py ./utils/link_failure_nofullmesh_pcap_subflow_plot.json