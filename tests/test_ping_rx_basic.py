#!/usr/bin/env python
# Copyright (c) 2016-2019, XMOS Ltd, All rights reserved

# Basic check of PING functionality

import random
import xmostest
from  usb_packet import *
from usb_clock import Clock
from helpers import do_usb_test, runall_rx

def do_test(arch, clk, phy, data_valid_count, usb_speed, seed):
    rand = random.Random()
    rand.seed(seed)

    address = 1
    ep = 1

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    dataval = 0;

    # Ping EP 2, expect NAK
    AppendPingToken(packets, 2, address, data_valid_count=data_valid_count)
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count, pid=0x5a))

    # And again
    AppendPingToken(packets, 2, address, data_valid_count=data_valid_count)
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count, pid=0x5a))

    # Send packet to EP 1, xCORE should mark EP 2 as ready
    AppendOutToken(packets, ep, address, data_valid_count=data_valid_count)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=10, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))
    
    # Ping EP 2 again - expect ACK
    AppendPingToken(packets, 2, address, data_valid_count=data_valid_count, inter_pkt_gap=6000)
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    # And again..
    AppendPingToken(packets, 2, address, data_valid_count=data_valid_count)
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    # Send out to EP 2.. expect ack
    AppendOutToken(packets, 2,address, data_valid_count=data_valid_count,  inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=10, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    # Re-Ping EP 2, expect NAK
    AppendPingToken(packets, 2, address, data_valid_count=data_valid_count)
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count, pid=0x5a))

    # And again
    AppendPingToken(packets, 2, address, data_valid_count=data_valid_count)
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count, pid=0x5a))

    # Send a packet to EP 1 so the DUT knows it can exit.
    AppendOutToken(packets, ep, address, data_valid_count=data_valid_count)
    packets.append(TxDataPacket(rand, data_start_val=dataval+10, data_valid_count=data_valid_count, length=10, pid=0x3^8)) #DATA1
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    do_usb_test(arch, clk, phy, usb_speed, packets, __file__, seed,level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
