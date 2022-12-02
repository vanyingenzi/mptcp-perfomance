import json
from dataclasses import dataclass
from typing import List
import matplotlib.pyplot as plt
import numpy as np

@dataclass
class IPerfIntervalThroughputData:
    intervals:          List[float]
    bits_per_second:    List[float]

LOG_FILE = "logs/iperf_server_output.json"

def per_interval_throughput(json_intervals) -> IPerfIntervalThroughputData:
    to_return = IPerfIntervalThroughputData([], [])
    for interval in json_intervals:
        to_return.intervals.append(interval["sum"]["end"])
        to_return.bits_per_second.append(interval["sum"]["bits_per_second"])
    return to_return

if __name__ == '__main__':
    with open(LOG_FILE) as file:
        log = json.load(file)
    extracted_data = per_interval_throughput(log["intervals"])
    print(f"Confidence interval : {np.percentile(extracted_data.bits_per_second, 2.5)} {np.percentile(extracted_data.bits_per_second, 97.5)}")
    print(f"Mean {np.mean(extracted_data.bits_per_second)}, Median: {np.median(extracted_data.bits_per_second)}")
    plt.plot(extracted_data.intervals, extracted_data.bits_per_second)
    plt.title("The throughput of the Iperf server")
    plt.xlabel("Timestamp")
    plt.ylabel("Throughput (bits/sec)")
    plt.show()
