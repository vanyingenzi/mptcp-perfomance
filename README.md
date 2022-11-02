# mptcp-perfomance
This repository contains scripts to set and test Multipath TCP connections. We use `iPerf3` implementations to simulate both our servers and clients.

## Quick run

## Servers
Within the *scripts/* directory you will multiple bash scripts launching iPerf3 servers with different configurations. It is important to note that we run the servers with `nohup` in order to achieve the daemon-like option. This a work around an issue faced with `-D` option of iPerf3.

- **tcp-server.sh** : A TCP server running with default configurations.

## Client

- **tcp-client.sh** : A TCP client that runs for 60 seconds. 

## Path Managers