import json
from dataclasses import dataclass
from typing import List
import pandas as pd
import seaborn as sns
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.pyplot import figure

from collections import defaultdict
sns.set_theme()

@dataclass
class IPerfIntervalThroughputData:
    intervals:          List[float]
    bits_per_second:    List[float]


C2S_LOG_DIRS = [
    "logs/backup/c2s/1/",
    "logs/backup/c2s/2/",
    "logs/backup/c2s/3/", 
    "logs/backup/c2s/4/"
]

S2C_LOG_DIRS = [
    "logs/backup/s2c/1/",
    "logs/backup/s2c/2/",
    "logs/backup/s2c/3/",
    "logs/backup/s2c/4/"
]

DictData = lambda: defaultdict(list)

def get_subflows_established(log_file):
    with open(log_file) as file:
        txt = file.read()
    return txt.count("ESTABLISHED")

def get_subflows_n_throughput(DIRS):
    dct = DictData()
    for DIR in DIRS:
        with open(f"{DIR}iperf_server_output.json") as file:
            log = json.load(file)
        extracted_data = per_interval_throughput(log["intervals"])
        if (len(extracted_data.bits_per_second) > 120):
            extracted_data.bits_per_second = extracted_data.bits_per_second[:120]
        dct[get_subflows_established(f"{DIR}monitor.txt")].append(np.mean(extracted_data.bits_per_second))
    return dct

def per_interval_throughput(json_intervals) -> IPerfIntervalThroughputData:
    to_return = IPerfIntervalThroughputData([], [])
    for interval in json_intervals:
        to_return.intervals.append(interval["sum"]["end"])
        to_return.bits_per_second.append(interval["sum"]["bits_per_second"])
    return to_return

def plot_corr(ax, title, color, LOGS_DIRS):
    dct = get_subflows_n_throughput(LOGS_DIRS)
    data = []
    for key, value in dct.items():
        data.append((key, value))
    data.sort(key=lambda x:x[0])
    violins = ax.violinplot([entry[1] for entry  in data], showmeans=False, showmedians=True)
    for violin in violins['bodies']:
        violin.set_facecolor(color)
        violin.set_edgecolor(color)
    ax.set(ylabel='Throughout (bits/sec)', xlabel="# of established subflows", title=title)
    ax.yaxis.grid(True)
    ax.set_xticks([y+1 for y in range(len(data))], labels=[entry[0] for entry  in data])

if __name__ == '__main__':
    x   = np.arange(1, 121)
    fig, axes = plt.subplots(1, 2, sharex=False, sharey=True, figsize=(21, 6), dpi=80)
    plot_corr(axes[0], "[Client to server]", "blue", C2S_LOG_DIRS)
    plot_corr(axes[1], "[Server to client]", "orange", S2C_LOG_DIRS)
    fig.suptitle("The throughput compared to the number of subflows established")
    plt.show()