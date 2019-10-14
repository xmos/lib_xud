#!/usr/bin/env python

import random
import xmostest
from  usb_packet import *
import usb_packet
from usb_clock import Clock
from helpers import do_usb_test, runall_rx

def do_test(arch, clk, phy, seed):
    rand = random.Random()
    rand.seed(seed)

    ep = 1
    address = 1

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    dataval = 0;

    AppendOutToken(packets, ep, address)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=10, pid=0x3, inter_pkt_gap = 400)) #DATA0
    packets.append(RxHandshakePacket(timeout=100))

    # Note, quite big gap to allow checking.
   
    pid = PID_DATA1; #DATA1

    for pktlength in range(10, 19):

        AppendOutToken(packets, ep, address, inter_pkt_gap=6000)
        packets.append(TxDataPacket(rand, data_start_val=dataval, length=pktlength, pid=pid)) 
        packets.append(RxHandshakePacket())
   
        if(pid == usb_packet.PID_DATA1):
            pid = usb_packet.PID_DATA0;
        else:
            pid = usb_packet.PID_DATA1;

    do_usb_test(arch, clk, phy, packets, __file__, seed, level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
