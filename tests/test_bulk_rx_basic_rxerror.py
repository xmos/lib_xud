#!/usr/bin/env python

import random
import xmostest
from  usb_packet import *
from usb_clock import Clock
from helpers import do_usb_test, runall_rx

# Single, setup transaction to EP 0

def do_test(arch, clk, phy, seed):
    rand = random.Random()
    rand.seed(seed)

    address = 1
    ep = 1

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    dataval = 0;

    AppendOutToken(packets, ep, address)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=10, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket())

    # Assert RxError during packet
    dataval += 10
    AppendOutToken(packets, ep, address, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=11, pid=0xb, rxe_assert_time=5)) #DATA1
    
    # xCORE should ignore the packet and not handshake...
    #packets.append(RxHandshakePacket())

    # Re-send..
    AppendOutToken(packets, ep, address, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=11, pid=0xb, rxe_assert_time=0)) #DATA1
    packets.append(RxHandshakePacket())

    dataval += 11
    AppendOutToken(packets, ep, address, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=12, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket())

    dataval += 12
    AppendOutToken(packets, ep, address, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=13, pid=0xb, rxe_assert_time=1)) #DATA1
    #packets.append(RxHandshakePacket())

    #resend
    AppendOutToken(packets, ep, address, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=13, pid=0xb)) #DATA1
    packets.append(RxHandshakePacket())

    dataval += 13
    AppendOutToken(packets, ep, address, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=14, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket())

    do_usb_test(arch, clk, phy, packets, __file__, seed, level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
