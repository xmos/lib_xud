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
    ep = 1

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    dataval = 0;

    AppendOutToken(packets, ep)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=10, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket())

    # Assert RxError during packet
    dataval += 10
    AppendOutToken(packets, ep, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=11, pid=0xb, rxe_assert_time=5)) #DATA1
    
    # xCORE should ignore the packet and not handshake...
    #packets.append(RxHandshakePacket())

    # Re-send..
    AppendOutToken(packets, ep, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=11, pid=0xb, rxe_assert_time=0)) #DATA1
    packets.append(RxHandshakePacket())

    dataval += 11
    AppendOutToken(packets, ep, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=12, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket(timeout=9))

    dataval += 12
    AppendOutToken(packets, ep, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=13, pid=0xb, rxe_assert_time=1)) #DATA1
    #packets.append(RxHandshakePacket())

    #resend
    AppendOutToken(packets, ep, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=13, pid=0xb)) #DATA1
    packets.append(RxHandshakePacket())


    dataval += 13
    AppendOutToken(packets, ep, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=14, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket())


    do_rx_test(arch, tx_clk, tx_phy, packets, __file__, seed,
               level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
