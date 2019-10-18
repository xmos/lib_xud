#!/usr/bin/env python

import random
import xmostest
from  usb_packet import *
#import * AppendSetupToken, TxDataPacket, RxDataPacket, TokenPacket, RxHandshakePacket, TxHandshakePacket
from usb_clock import Clock
from helpers import do_usb_test, runall_rx

def do_test(arch, clk, phy, seed):
    rand = random.Random()
    rand.seed(seed)

    ep = 2
    address = 1

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    dataval = 0;

    # Note, quite big gap to allow checking.
    pid = PID_DATA0;

    for pktlength in range(10, 15):
        AppendOutToken(packets, ep, address, inter_pkt_gap=500)
        packets.append(TxDataPacket(rand, data_start_val=dataval, length=pktlength, pid=pid)) 
        dataval += pktlength

    do_usb_test(arch, clk, phy, packets, __file__, seed, level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
