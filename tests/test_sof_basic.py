#!/usr/bin/env python

# Same as simple RX bulk test but some invalid tokens also included

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
    framenumber = 52 # Note, for frame number 52 we expect A5 34 40 on the bus

    packets = []
    dataval = 0;

    # Start with a valid transaction */
    AppendOutToken(packets, ep, address)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=10, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket())

    AppendSofToken(packets, framenumber)
    AppendSofToken(packets, framenumber+1) 
    AppendSofToken(packets, framenumber+2)
    AppendSofToken(packets, framenumber+3)
    AppendSofToken(packets, framenumber+4)

    #Finish with valid transaction 
    dataval += 10
    AppendOutToken(packets, ep, address, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=11, pid=0xb)) #DATA1
    packets.append(RxHandshakePacket())

    do_usb_test(arch, clk, phy, packets, __file__, seed, level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
