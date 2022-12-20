import matplotlib.pyplot as plt
from pcap_distribution import per_connection_data as standard_per_connection
from pcap_CookedLinux_distribution import per_connection_data as cooked_linux_per_connection

PCAP_FILE="./logs/temporal_loss.pcap"

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

if __name__ == "__main__":
    data = cooked_linux_per_connection(PCAP_FILE)
    for idx, dataset in enumerate(data):
        new_timestamps, new_data = resample_data_by_interval(  dataset.timestamps, dataset.payload_len )
        plt.plot( new_timestamps, new_data, label=f"flow ({idx+1}) : {dataset.src_addr}<->{dataset.dest_addr}" )
    
    plt.title("The throughput for each MPTCP subflow as seen by TCPDump")
    plt.ylabel("Throughput (bits/sec)")
    xlim = plt.xlim()
    plt.xlim([xlim[0], 130])
    plt.xlabel("Timestamp")
    plt.legend()
    plt.show()