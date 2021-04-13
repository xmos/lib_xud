#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

import random
import xmostest
from  usb_packet import *
from usb_clock import Clock
from helpers import do_rx_test, packet_processing_time, get_dut_address
from helpers import choose_small_frame_size, check_received_packet, runall_rx

def do_test(arch, clk, phy, seed):
    rand = random.Random()
    rand.seed(seed)

    start_ep = 3
    
    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    data_val = 0;
    pkt_length = 20
    data_pid = 0x3 #DATA0 

    for pkt_length in range(10, 20):
        
        #Single EP:
        #317 lowest for valid data (SI)
        #337 for initial DI version
        
        #Multi EP:
        #177 lowest for valid data (DI)
        AppendInToken(packets, start_ep, inter_pkt_gap=177)
        packets.append(RxDataPacket(rand, data_start_val=data_val, length=pkt_length, pid=data_pid))
        packets.append(TxHandshakePacket())

        AppendInToken(packets, start_ep+1, inter_pkt_gap=177)
        packets.append(RxDataPacket(rand, data_start_val=data_val, length=pkt_length, pid=data_pid))
        packets.append(TxHandshakePacket())
       
        AppendInToken(packets, start_ep+2, inter_pkt_gap=177)
        packets.append(RxDataPacket(rand, data_start_val=data_val, length=pkt_length, pid=data_pid))
        packets.append(TxHandshakePacket())
      
        AppendInToken(packets, start_ep+3, inter_pkt_gap=177)
        packets.append(RxDataPacket(rand, data_start_val=data_val, length=pkt_length, pid=data_pid))
        packets.append(TxHandshakePacket())
       
        data_val = data_val + pkt_length
        data_pid = data_pid ^ 8

    do_rx_test(arch, clk, phy, packets, __file__, seed,
               level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
