#!/usr/bin/env python

import random
import xmostest
from usb_packet import *
import usb_packet
from usb_clock import Clock
from helpers import do_usb_test, runall_rx

# Single, setup transaction to EP 0

def do_test(arch, clk, phy, seed):
    rand = random.Random()
    rand.seed(seed)


    ep = 0
    address = 1 

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    # SETUP transaction
    AppendSetupToken(packets, ep, address)
    packets.append(TxDataPacket(rand, length=8, pid=3))
    packets.append(RxHandshakePacket())

    # IN transaction
    # Note, quite big gap to avoid nak
    AppendInToken(packets, ep, address, inter_pkt_gap = 10000)
    packets.append(RxDataPacket(rand, length=10, pid=0xb))
    packets.append(TxHandshakePacket())
 
    # Send 0 length OUT transaction 
    AppendOutToken(packets, ep, address)
    packets.append(TxDataPacket(rand, length=0, pid=PID_DATA1))
    packets.append(RxHandshakePacket())

    do_usb_test(arch, clk, phy, packets, __file__, seed, level='smoke', extra_tasks=[])


def runtest():
    random.seed(1)
    runall_rx(do_test)
