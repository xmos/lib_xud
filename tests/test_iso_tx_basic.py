#!/usr/bin/env python

import random
import xmostest
from  usb_packet import *
from usb_clock import Clock
from helpers import do_usb_test, runall_rx


# Single, setup transaction to EP 0

def do_test(arch, tx_clk, tx_phy, data_valid_count, usb_speed, seed):
    rand = random.Random()
    rand.seed(seed)

    ep = 3
    address = 1

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    dataval = 0;

    AppendInToken(packets, ep, address, data_valid_count=data_valid_count)
    packets.append(RxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=10, pid=0x3)) #DATA0

    dataval += 10
    AppendInToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap=2000)
    packets.append(RxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=11, pid=0x3)) #DATA0

    dataval += 11
    AppendInToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap=2000)
    packets.append(RxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=12, pid=0x3)) #DATA0

    dataval += 12
    AppendInToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap=2000)
    packets.append(RxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=13, pid=0x3)) #DATA0

    dataval += 13
    AppendInToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap=2000)
    packets.append(RxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=14, pid=0x3)) #DATA0

    do_usb_test(arch, tx_clk, tx_phy, usb_speed, packets, __file__, seed, level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
