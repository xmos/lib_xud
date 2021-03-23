#!/usr/bin/env python

import random
import xmostest
from usb_packet import *
import usb_packet
from usb_clock import Clock
from helpers import do_usb_test, runall_rx

def do_test(arch, tx_clk, tx_phy, data_valid_count, usb_speed, seed):
    rand = random.Random()
    rand.seed(seed)

    ep = 0
    address = 1

    packets = []

    AppendSetupToken(packets, ep, address, data_valid_count=data_valid_count)
    packets.append(TxDataPacket(rand, data_valid_count=data_valid_count, length=8, pid=3))
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count, timeout=11))

    # Note, quite big gap to avoid NAL
    AppendOutToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap = 10000)
    packets.append(TxDataPacket(rand, data_valid_count=data_valid_count, length=10, pid=0xb, data_start_val=8))
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    #Expect 0-length
    AppendInToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap = 10000)
    packets.append(RxDataPacket(rand, data_valid_count=data_valid_count, length=0, pid=0xb))
    packets.append(TxHandshakePacket(data_valid_count=data_valid_count))

    do_usb_test(arch, tx_clk, tx_phy, usb_speed, packets, __file__, seed, level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
