# mptcp-perfomance
This project is to test mptcp-net-next implementation.

## 1. Structure 
- `iperf` : This is a fork of an MPTCP capable implementation [iPerf3](https://github.com/pabeni/iperf/tree/mptcp).
- `logs` : The directory that will contain all the logs of the execution.
- `plots` : Directory containing plots generated.
- `scripts` : Bash scripts for multiple purposes.
- `utils` : Mainly consisted of python scripts to generate graphs and parse the logs in the `logs` directory.

## 2. Getting started 
To setup iPerf3 and create necessary directories we recommend to run :

```bash
make
```

## 3. Tests
### 3. 1. TCP Baseline 
A script to run TCP baseline test have been prepared to know more about the parameters run : 
```
./scripts/tcp_baseline_test.sh -h
```
### 3. 2. Aggregation
A script to run Mulitpath TCP test have been prepared to know more about the parameters run : 
```
./scripts/aggregation_test.sh -h
```
### 3. 3. Link failure
A script to run link failures test on Multipath TCP connections have been prepared to know more about the parameters run : 
```
./scripts/link_failure_test.sh -h
```
For each of the tests you can get inspired with how they are executed in the `Makefile`. Targets that run the tests are :
`run-aggregattion-test`, `run-tcp-baseline` and `run-link-failure-test`.