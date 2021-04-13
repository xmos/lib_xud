#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

import random
import xmostest
from  usb_packet import *
#import * AppendSetupToken, TxDataPacket, RxDataPacket, TokenPacket, RxHandshakePacket, TxHandshakePacket
from usb_clock import Clock
from helpers import do_rx_test, packet_processing_time, get_dut_address
from helpers import choose_small_frame_size, check_received_packet, runall_rx


# Single, setup transaction to EP 0

def do_test(arch, tx_clk, tx_phy, seed):
    rand = random.Random()
    rand.seed(seed)

    dev_address = get_dut_address()
    ep = 2

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    dataval = 0;

    AppendInToken(packets, ep)
    packets.append(RxDataPacket(rand, data_start_val=dataval, length=10, pid=0x3)) #DATA0
    packets.append(TxHandshakePacket())

    dataval += 10
    AppendInToken(packets, ep, inter_pkt_gap=5000)
    packets.append(RxDataPacket(rand, data_start_val=dataval, length=11, pid=0xb)) #DATA1
    packets.append(TxHandshakePacket())

    #pretend CRC got broken on way to host and dont send ACK
    dataval += 11
    AppendInToken(packets, ep, inter_pkt_gap=5000)
    packets.append(RxDataPacket(rand, data_start_val=dataval, length=12, pid=0x3)) #DATA0
    #packets.append(TxHandshakePacket())

    #xCore should resend same packet again..
    AppendInToken(packets, ep, inter_pkt_gap=5000)
    packets.append(RxDataPacket(rand, data_start_val=dataval, length=12, pid=0x3)) #DATA0
    packets.append(TxHandshakePacket())

    dataval += 12
    AppendInToken(packets, ep, inter_pkt_gap=5000)
    packets.append(RxDataPacket(rand, data_start_val=dataval, length=13, pid=0xb)) #DATA1
    packets.append(TxHandshakePacket())

    dataval += 13
    AppendInToken(packets, ep, inter_pkt_gap=5000)
    packets.append(RxDataPacket(rand, data_start_val=dataval, length=14, pid=0x3)) #DATA0
    packets.append(TxHandshakePacket())

    # Note, quite big gap to allow checking.
    do_rx_test(arch, tx_clk, tx_phy, packets, __file__, seed,
               level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
