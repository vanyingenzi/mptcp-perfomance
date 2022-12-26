import matplotlib.pyplot as plt
from pcap_distribution import per_connection_data as standard_per_connection
from pcap_CookedLinux_distribution import per_connection_data as cooked_linux_per_connection
import sys
from typing import Dict
import json
from collections import defaultdict
import os
import numpy as np


PLOT_JSON_FILE="./utils/aggregation_pcap_subflow_plot.json"

DefaultListDict = lambda: defaultdict(list)

def get_plot_configure(CONF_FILE):
    with open(CONF_FILE) as file:
        dct = json.load(file)
    return dct

def resample_data_by_interval(timestamps, payload_lens, interval=1000000):
    new_timestamps, new_payload_lens = [], []
    curr_index      = 0
    #sum_before      = sum(payload_lens) 
    start_timestamp = timestamps[0]
    while (curr_index < len(timestamps)):
        timestamp   = timestamps[curr_index]
        next_index  = curr_index
        data        = 0
        while (next_index < len(timestamps) and timestamps[next_index] <= timestamp + interval):
            data        += payload_lens[next_index]
            next_index  += 1
        new_timestamps.append((timestamps[next_index-1] - start_timestamp)/interval)
        new_payload_lens.append(data)
        curr_index  = next_index
    #assert sum(new_payload_lens) == sum_before
    return new_timestamps, new_payload_lens

def calculate_the_plot(PCAP_FILES):
    per_subflow = DefaultListDict()
    for PCAP_FILE in PCAP_FILES:
        data = cooked_linux_per_connection(PCAP_FILE)
        for idx, dataset in enumerate(data):
            new_timestamps, new_data = resample_data_by_interval(  dataset.timestamps, dataset.payload_len )
            if len(new_data) > 120:
                new_data = new_data[:120]                
            per_subflow[dataset.addresses].append(new_data)
    to_return = {}
    for key, value in per_subflow.items():
        to_return[key] = {"mean": np.average(value, axis=0), "median": np.median(value, axis=0), "min": np.amin(value, axis=0), "max": np.amax(value, axis=0) }
    return to_return


def handle_subplot(ax: plt.Axes, json_conf: Dict[str, any]):
    dct = DefaultListDict()
    files = [ os.path.join(json_conf["dir"], file) for file in os.listdir(json_conf["dir"]) if file[-4:] == "pcap" ]
    if "group" in json_conf:
        for filepath in files:
            file = os.path.basename(filepath)
            key = eval(json_conf["group"]["code"])
            dct[key].append(filepath)
    else: 
        dct[""] = files
    
    for key, values in dct.items():
        data = calculate_the_plot(values)
        for data_key, data_value in data.items():
            for calculation in json_conf["calculate"]:
                subflow_label = "<->".join(data_key)
                latest, = ax.plot(data_value[calculation], label=f"{calculation[0].upper()}{calculation[1:]} {subflow_label}")
        if "lines" in json_conf:
            if "x" in json_conf["lines"]:
                for line in json_conf["lines"]["x"]:
                    ax.axvline(x=line["value"], color=line["color"], linestyle="-." if "failure" in line["label"] else "-", label=line["label"])
            if "y" in json_conf["lines"]:
                for line in json_conf["lines"]["y"]:
                    ax.axhline(y=line["value"], color=line["color"], linestyle="-.", label=line["label"])
    ax.grid(True)
    ax.legend()
    ax.set(xlabel=json_conf["x_label"], ylabel=json_conf["y_label"], title=json_conf["title"])
    return ax.get_legend_handles_labels()



if __name__ == "__main__":
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
    xlim = plt.xlim()
    plt.xlim([xlim[0], 130])
    plt.show()