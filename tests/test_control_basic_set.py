#!/usr/bin/env python

import random
import xmostest
from usb_packet import *
import usb_packet
from usb_clock import Clock
from helpers import do_usb_test, runall_rx

def do_test(arch, tx_clk, tx_phy, seed):
    rand = random.Random()
    rand.seed(seed)

    ep = 0
    address = 1

    packets = []

    AppendSetupToken(packets, ep, address)
    packets.append(TxDataPacket(rand, length=8, pid=3))
    packets.append(RxHandshakePacket(timeout=11))

    # Note, quite big gap to avoid NAL
    AppendOutToken(packets, ep, address, inter_pkt_gap = 10000)
    packets.append(TxDataPacket(rand, length=10, pid=0xb, data_start_val=8))
    packets.append(RxHandshakePacket())

    #Expect 0-length
    AppendInToken(packets, ep, address, inter_pkt_gap = 10000)
    packets.append(RxDataPacket(rand, length=0, pid=0xb))
    packets.append(TxHandshakePacket())

    do_usb_test(arch, tx_clk, tx_phy, packets, __file__, seed, level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
