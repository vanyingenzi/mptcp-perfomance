import json
from dataclasses import dataclass
from typing import List
import pandas as pd
import seaborn as sns
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.pyplot import figure

figure(figsize=(21, 6), dpi=80)

sns.set_theme()

@dataclass
class IPerfIntervalThroughputData:
    intervals:          List[float]
    bits_per_second:    List[float]


C2S_LOG_FILES = [
    "logs/backup/c2s/1/iperf_server_output.json",
    "logs/backup/c2s/2/iperf_server_output.json",
    "logs/backup/c2s/3/iperf_server_output.json", 
    "logs/backup/c2s/4/iperf_server_output.json"
]

S2C_LOG_FILES = [
    "logs/backup/s2c/1/iperf_server_output.json",
    "logs/backup/s2c/2/iperf_server_output.json",
    "logs/backup/s2c/3/iperf_server_output.json",
    "logs/backup/s2c/4/iperf_server_output.json"
]

def get_mean_min_max(LOG_FILES):
    y = []
    for LOG_FILE in LOG_FILES:
        with open(LOG_FILE) as file:
            log = json.load(file)
        extracted_data = per_interval_throughput(log["intervals"])
        if (len(extracted_data.bits_per_second) > 120):
            extracted_data.bits_per_second = extracted_data.bits_per_second[:120]
        y.append(extracted_data.bits_per_second)
    return np.average(y, axis=0), np.median(y, axis=0), np.amin(y, axis=0), np.amax(y, axis=0)

def per_interval_throughput(json_intervals) -> IPerfIntervalThroughputData:
    to_return = IPerfIntervalThroughputData([], [])
    for interval in json_intervals:
        to_return.intervals.append(interval["sum"]["end"])
        to_return.bits_per_second.append(interval["sum"]["bits_per_second"])
    return to_return

if __name__ == '__main__':
    x = np.arange(1, 121)
    c2s_mean, c2s_median, c2s_min, c2s_max = get_mean_min_max(C2S_LOG_FILES)
    plt.plot(x, c2s_mean, label="Average client to Server", color="blue")
    plt.plot(x, c2s_median, linestyle='dashed', label="Median client to Server", color="blue")
    plt.fill_between(x, c2s_min, c2s_max, alpha=0.2, facecolor="blue", edgecolor="blue")
    s2c_mean, s2c_median, s2c_min, s2c_max = get_mean_min_max(S2C_LOG_FILES)
    plt.plot(x, s2c_mean, label="Average Server to Client", color="orange")
    plt.plot(x, s2c_median, linestyle='dashed', label="Median Server to Client", color="orange")
    plt.fill_between(x, s2c_min, s2c_max, alpha=0.2, facecolor="orange", edgecolor="orange")
    plt.legend()
    plt.title("The average throughput during the transfer")
    plt.ylabel("Throughput (bits/sec)")
    plt.xlabel("Time[s]")
    print(f"{np.mean(c2s_mean)} {np.mean(s2c_mean)}" )
    plt.show()
