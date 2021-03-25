#!/usr/bin/env python
# Copyright (c) 2016-2019, XMOS Ltd, All rights reserved

import random
import xmostest
from usb_packet import *
import usb_packet
from usb_clock import Clock
from helpers import do_usb_test, runall_rx

# Single, setup transaction to EP 0

def do_test(arch, clk, phy, data_valid_count, usb_speed, seed):
    rand = random.Random()
    rand.seed(seed)


    ep = 0
    address = 1 

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    # SETUP transaction
    AppendSetupToken(packets, ep, address, data_valid_count=data_valid_count)
    packets.append(TxDataPacket(rand, data_valid_count=data_valid_count, length=8, pid=3))
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    # IN transaction
    # Note, quite big gap to avoid nak
    AppendInToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap = 10000)
    packets.append(RxDataPacket(rand, data_valid_count=data_valid_count, length=10, pid=0xb))
    packets.append(TxHandshakePacket(data_valid_count=data_valid_count))
 
    # Send 0 length OUT transaction 
    AppendOutToken(packets, ep, address, data_valid_count=data_valid_count)
    packets.append(TxDataPacket(rand, data_valid_count=data_valid_count, length=0, pid=PID_DATA1))
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    do_usb_test(arch, clk, phy, usb_speed, packets, __file__, seed, level='smoke', extra_tasks=[])


def runtest():
    random.seed(1)
    runall_rx(do_test)
