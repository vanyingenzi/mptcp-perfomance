import json
from dataclasses import dataclass
from typing import List
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.pyplot import figure
import sys
import os
from typing import Dict
from collections import defaultdict

DefaultListDict = lambda: defaultdict(list)

PLOT_JSON_FILE = "./utils/json_throughout_plot.json"

@dataclass
class IPerfIntervalThroughputData:
    intervals:          List[float]
    bits_per_second:    List[float]


def get_plot_configure(CONF_FILE):
    with open(CONF_FILE) as file:
        dct = json.load(file)
    return dct

def calculate_the_plot(LOG_FILES):
    y = []
    for LOG_FILE in LOG_FILES:
        with open(LOG_FILE) as file:
            log = json.load(file)
        extracted_data = per_interval_throughput(log["intervals"])
        if (len(extracted_data.bits_per_second) > 120):
            extracted_data.bits_per_second = extracted_data.bits_per_second[:120]
        y.append(extracted_data.bits_per_second)
    return {"mean": np.average(y, axis=0), "meadian": np.median(y, axis=0), "min": np.amin(y, axis=0), "max": np.amax(y, axis=0) }

def per_interval_throughput(json_intervals) -> IPerfIntervalThroughputData:
    to_return = IPerfIntervalThroughputData([], [])
    for interval in json_intervals:
        to_return.intervals.append(interval["sum"]["end"])
        to_return.bits_per_second.append(interval["sum"]["bits_per_second"])
    return to_return

def handle_subplot(ax: plt.Axes, json_conf: Dict[str, any]):
    dct = DefaultListDict()
    files = [ os.path.join(subplot_conf["dir"], file) for file in os.listdir(subplot_conf["dir"]) if file[-4:] == "json" ]
    if "group" in json_conf:
        for filepath in files:
            file = os.path.basename(filepath)
            key = eval(subplot_conf["group"]["code"])
            dct[key].append(filepath)
    else: 
        dct[subplot_conf["calculate"]] = files

    for key, values in dct.items():
        data = calculate_the_plot(values)
        ax.plot(data[subplot_conf["calculate"]], label=key)
        ax.legend()
    ax.set(xlabel=subplot_conf["x_label"], ylabel=subplot_conf["y_label"], title=subplot_conf["title"])

if __name__ == '__main__':
    if len(sys.argv) == 2:
        PLOT_JSON_FILE = sys.argv[1]
    PLOT_JSON = get_plot_configure(PLOT_JSON_FILE)
    if len(PLOT_JSON["subplots"]) <= 1:
        figure(figsize=(21, 6), dpi=80)
    else:
        fig, axes = plt.subplots(1, len(PLOT_JSON["subplots"]), sharex=True, sharey=True, figsize=(21, 6), dpi=80)
        for idx, subplot_conf in enumerate(PLOT_JSON["subplots"]):
            handle_subplot(axes[idx], subplot_conf)
        fig.suptitle(PLOT_JSON["title"])
    plt.show()