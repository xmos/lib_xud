#!/usr/bin/env python

import random
import xmostest
from  usb_packet import *
from usb_clock import Clock
from helpers import do_usb_test, runall_rx

def do_test(arch, clk, phy, data_valid_count, usb_speed, seed):
    rand = random.Random()
    rand.seed(seed)

    ep = 3
    address = 1

    packets = []

    data_val = 0;
    pkt_length = 20
    data_pid = 0x3 #DATA0 

    for pkt_length in range(10, 20):

        # < 17 fails
        AppendOutToken(packets, ep, address, inter_pkt_gap=20)
        packets.append(TxDataPacket(rand, data_start_val=data_val, data_valid_count=data_valid_count, length=pkt_length, pid=data_pid)) #DATA0

        AppendInToken(packets, ep, address, inter_pkt_gap=58)
        packets.append(RxDataPacket(rand, data_start_val=data_val, data_valid_count=data_valid_count, length=pkt_length, pid=data_pid))

        data_val = data_val + pkt_length
        #data_pid = data_pid ^ 8

    do_usb_test(arch, clk, phy, usb_speed, packets, __file__, seed, level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
