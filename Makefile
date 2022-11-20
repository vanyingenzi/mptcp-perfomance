all: setup

# Install the required packages
setup: set-folders
	apt -y install iperf3
	apt -y install mptcpize
	chmod -R +x scripts/

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
	if [ ! -d "../iperf/src/iperf3" ]; then\
		echo "Seems that iperf3 is not set at the expected directory.";\
		exit 1;\
	fi
	chmod -R +x scripts/
	chmod -R +x scripts/

clean:
	rm -fr logs/*
	rmdir logs

run-clients: setup
	@echo "Running the standard TCP Client"
	./scripts/client/tcp-client.sh -p 80
	@echo "Running the mptcpized standard TCP Client"
	mptcpize run ./scripts/client/tcp-client.sh -p 443