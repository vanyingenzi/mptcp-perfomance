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
import random

DefaultListDict = lambda: defaultdict(list)

PLOT_JSON_FILE = "./utils/aggregation_json_throughout_plot.json"

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
    return {"mean": np.average(y, axis=0), "median": np.median(y, axis=0), "min": np.amin(y, axis=0), "max": np.amax(y, axis=0) }

def per_interval_throughput(json_intervals) -> IPerfIntervalThroughputData:
    to_return = IPerfIntervalThroughputData([], [])
    for interval in json_intervals:
        to_return.intervals.append(interval["sum"]["end"])
        to_return.bits_per_second.append(interval["sum"]["bits_per_second"])
    return to_return

def handle_subplot(ax: plt.Axes, json_conf: Dict[str, any]):
    dct = DefaultListDict()
    files = [ os.path.join(json_conf["dir"], file) for file in os.listdir(json_conf["dir"]) if file[-4:] == "json" ]
    if "group" in json_conf:
        for filepath in files:
            file = os.path.basename(filepath)
            key = eval(json_conf["group"]["code"])
            dct[key].append(filepath)
    else: 
        dct[""] = files
        
    for key, values in dct.items():
        data = calculate_the_plot(values)
        for calculation in json_conf["calculate"]:
            latest, = ax.plot(data[calculation], label=f"{calculation[0].upper()}{calculation[1:]} {key}")
        if "fill" in json_conf and json_conf["fill"]:
            color = latest.get_color() if len(json_conf["calculate"]) == 1 else "#A555EC"
            ax.fill_between(latest.get_xdata(), data["min"], data["max"], alpha=0.2, facecolor=color, edgecolor=color, label=f"Min-Max Region {key}")
        if "lines" in json_conf:
            if "x" in json_conf["lines"]:
                for line in json_conf["lines"]["x"]:
                    ax.axvline(x=line["value"], color=line["color"], linestyle="-.")
                    ax.annotate(line["label"], xy=(line["value"], line["value"]), xytext=(line["value"]-5, data["max"][random.randint(0, len(data["max"]))]))
            if "y" in json_conf["lines"]:
                for line in json_conf["lines"]["y"]:
                    ax.axhline(y=line["value"], color=line["color"], linestyle="-.")
    ax.grid(True)
    ax.legend()
    ax.set(xlabel=json_conf["x_label"], ylabel=json_conf["y_label"], title=json_conf["title"])

if __name__ == '__main__':
    if len(sys.argv) == 2:
        PLOT_JSON_FILE = sys.argv[1]
    PLOT_JSON = get_plot_configure(PLOT_JSON_FILE)
    if len(PLOT_JSON["subplots"]) == 1:
        fig, ax = plt.subplots(1, 1, sharex=True, sharey=True, figsize=(21, 6), dpi=80)
        handle_subplot(ax, PLOT_JSON["subplots"][0])
    elif len(PLOT_JSON["subplots"]) > 2:
        fig, axes = plt.subplots(1, len(PLOT_JSON["subplots"]), sharex=True, sharey=True, figsize=(21, 6), dpi=80)
        for idx, subplot_conf in enumerate(PLOT_JSON["subplots"]):
            handle_subplot(axes[idx], subplot_conf)
        fig.suptitle(PLOT_JSON["title"])        
    plt.show()