from scapy.utils import RawPcapReader
from scapy.layers.l2 import Ether
from scapy.layers.inet import IP, TCP
from scapy.layers.inet6 import IPv6
from dataclasses import dataclass, field
from typing import List, Set, Tuple
from functools import cmp_to_key
from collections import defaultdict

PCAP_FILE="./logs/test.pcap"

@dataclass
class TransportConnection:
    src_addr:       str
    dest_addr:      str
    src_port:       int
    dest_port:      int

    def __hash__(self) -> int:
        list_arg = [self.src_addr, self.dest_addr]
        list_arg.sort()
        return hash(tuple(list_arg))

    def get_addresses(self) -> Tuple[str, str]:
        list_arg = [self.src_addr, self.dest_addr]
        list_arg.sort()
        return tuple(list_arg)

@dataclass
class ProcessingPacket(TransportConnection):
    timestamp:      int
    payload_len:    int

@dataclass
class ConnectionData(TransportConnection):
    timestamps:     List[int]
    payload_len:    List[int]

ConnectionDataDict = lambda: defaultdict(ConnectionData)

def timebased_packets_comparator(this: ProcessingPacket, other: ProcessingPacket) -> int:
    if (this.sec != other.sec):
        return this.sec - other.sec
    return this.usec - other.usec

def process_pcap(file_name: str) -> List[ProcessingPacket]:
    packets = []        
    for (pkt_data, pkt_metadata,) in RawPcapReader(file_name):
        
        ether_pkt = Ether(pkt_data)
        if 'type' not in ether_pkt.fields:  continue
        if ether_pkt.type != 0x86dd:        continue # disregard non-IPv6 packets

        ip_pkt              = ether_pkt[IPv6]
        tcp_pkt             = ip_pkt[TCP]

        process_packet      = ProcessingPacket(     ip_pkt.src, 
                                                    ip_pkt.dst, 
                                                    tcp_pkt.sport, 
                                                    tcp_pkt.dport, 
                                                    (pkt_metadata.sec * 1000000) + pkt_metadata.usec,
                                                    len(tcp_pkt.payload)
                                                )
        
        packets.append(process_packet)
    packets.sort(key=lambda x: x.timestamp)
    return packets

def per_connection_data(filename: str) -> Set[ConnectionData]:
    packets     = process_pcap(filename)
    connections = dict()
    for packet in packets:
        addresses = packet.get_addresses()
        if addresses not in connections:
            connections[addresses] = ConnectionData(packet.src_addr, packet.dest_addr, packet.src_port, packet.dest_port, [], [])
        connections[addresses].timestamps.append(packet.timestamp)
        connections[addresses].payload_len.append(packet.payload_len)
    return connections.values()

if __name__ == "__main__":
    print(len(per_connection_data(PCAP_FILE)))
