from scapy.all import sniff
from scapy.layers.l2 import Ether, CookedLinuxV2, CookedLinux
from scapy.layers.inet import IP, TCP
from scapy.layers.inet6 import IPv6
from typing import List, Set
from pcap_distribution import ProcessingPacket, ConnectionData, ConnectionDataDict, timebased_packets_comparator
import math

PCAP_FILE="./logs/tcpdump.pcap"

def process_pcap(file_name: str) -> List[ProcessingPacket]:
    packets = []       
    def per_packet_process(packet):
        ip_pkt  = packet[IPv6]
        tcp_pkt = ip_pkt[TCP]
        process_packet      = ProcessingPacket(     ip_pkt.src, 
                                                    ip_pkt.dst, 
                                                    tcp_pkt.sport, 
                                                    tcp_pkt.dport, 
                                                    float(packet.time * 1e6),
                                                    ip_pkt.plen * 8 # To convert to bits
                                                )
        packets.append(process_packet)

    sniff(offline=file_name, prn=per_packet_process)
    return packets

def per_connection_data(filename: str) -> Set[ConnectionData]:
    packets     = process_pcap(filename)
    connections = dict()
    for packet in packets:
        addresses = packet.get_addresses()
        if addresses not in connections:
            connections[addresses] = ConnectionData( packet.src_addr, packet.dest_addr, packet.src_port, packet.dest_port, addresses, [], [])
        connections[addresses].timestamps.append(packet.timestamp)
        connections[addresses].payload_len.append(packet.payload_len)
    return connections.values()

if __name__ == "__main__":
    print(len(per_connection_data(PCAP_FILE)))
