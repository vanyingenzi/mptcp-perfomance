all: setup

# Install the required packages
setup: set-folders
	apt update
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
	chmod -R +x scripts/

clean:
	rm -fr logs/*
	rmdir logs

run-tcp-client: setup
	./scripts/client/tcp-client.sh