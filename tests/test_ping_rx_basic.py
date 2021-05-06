#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

# Basic check of PING functionality

import random
import xmostest
from  usb_packet import *
#import * AppendSetupToken, TxDataPacket, RxDataPacket, TokenPacket, RxHandshakePacket, TxHandshakePacket
from usb_clock import Clock
from helpers import do_rx_test, packet_processing_time, get_dut_address
from helpers import choose_small_frame_size, check_received_packet, runall_rx


# Single, setup transaction to EP 0

def do_test(arch, clk, phy, seed):
    rand = random.Random()
    rand.seed(seed)

    dev_address = get_dut_address()
    ep = 1

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    dataval = 0;

    # Ping EP 2, expect NAK
    AppendPingToken(packets, 2)
    packets.append(RxHandshakePacket(pid=0x5a))

    # And again
    AppendPingToken(packets, 2)
    packets.append(RxHandshakePacket(pid=0x5a))


    # Send packet to EP 1, xCORE should mark EP 2 as ready
    AppendOutToken(packets, ep)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=10, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket())
    
    # Ping EP 2 again - expect ACK
    AppendPingToken(packets, 2, inter_pkt_gap=6000)
    packets.append(RxHandshakePacket())

    # And again..
    AppendPingToken(packets, 2)
    packets.append(RxHandshakePacket())

    # Send out to EP 2.. expect ack
    AppendOutToken(packets, 2, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=10, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket())

   # Re-Ping EP 2, expect NAK
    AppendPingToken(packets, 2)
    packets.append(RxHandshakePacket(pid=0x5a))

    # And again
    AppendPingToken(packets, 2)
    packets.append(RxHandshakePacket(pid=0x5a))



    do_rx_test(arch, clk, phy, packets, __file__, seed,
               level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
