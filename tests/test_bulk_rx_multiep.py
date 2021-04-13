#!/usr/bin/env python
# Copyright 2019-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

import random
import xmostest
from  usb_packet import *
from usb_clock import Clock
from helpers import do_usb_test, runall_rx

def do_test(arch, clk, phy, data_valid_count, usb_speed, seed):
    rand = random.Random()
    rand.seed(seed)

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    address = 1
    data_val = 0;
    pkt_length = 20
    data_pid = 0x3 #DATA0 

    for pkt_length in range(10, 20):
    
        #min 237
        AppendOutToken(packets, 3, address, data_valid_count=data_valid_count, inter_pkt_gap=1)
        packets.append(TxDataPacket(rand, data_start_val=data_val, data_valid_count=data_valid_count, length=pkt_length, pid=data_pid)) #DATA0
        packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

        AppendOutToken(packets, 4, address, data_valid_count=data_valid_count, inter_pkt_gap=1)
        packets.append(TxDataPacket(rand, data_start_val=data_val, data_valid_count=data_valid_count, length=pkt_length, pid=data_pid)) #DATA0
        packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

        AppendOutToken(packets, 5, address, data_valid_count=data_valid_count, inter_pkt_gap=0)
        packets.append(TxDataPacket(rand, data_start_val=data_val, data_valid_count=data_valid_count, length=pkt_length, pid=data_pid)) #DATA0
        packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

        AppendOutToken(packets, 6, address, data_valid_count=data_valid_count, inter_pkt_gap=0)
        packets.append(TxDataPacket(rand, data_start_val=data_val, data_valid_count=data_valid_count, length=pkt_length, pid=data_pid)) #DATA0
        packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

        data_val = data_val + pkt_length
        data_pid = data_pid ^ 8

    do_usb_test(arch, clk, phy, usb_speed, packets, __file__, seed,
               level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
