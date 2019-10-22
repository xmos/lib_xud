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

    pid = PID_DATA0;

    trafficAddress1 = 0;
    trafficAddress2 = 127;

    trafficEp1 = 15;
    trafficEp2 = 0;

    for pktlength in range(10, 20):

        AppendOutToken(packets, trafficEp1, trafficAddress1, inter_pkt_gap=500)
        packets.append(TxDataPacket(rand, data_start_val=dataval, length=pktlength, pid=pid)) 

        AppendOutToken(packets, ep, address, inter_pkt_gap=500)
        packets.append(TxDataPacket(rand, data_start_val=dataval, length=pktlength, pid=pid)) 
        packets.append(RxHandshakePacket())
  
        AppendOutToken(packets, trafficEp2, trafficAddress2, inter_pkt_gap=500)
        packets.append(TxDataPacket(rand, data_start_val=dataval, length=pktlength, pid=pid)) 

        if(pid == usb_packet.PID_DATA1):
            pid = usb_packet.PID_DATA0;
        else:
            pid = usb_packet.PID_DATA1;

        dataval += pktlength

        trafficEp1 = trafficEp1 - 1
        if(trafficEp1 < 0):
            trafficEp1 = 15
        
        trafficEp2 + trafficEp2 + 1
        if(trafficEp1 > 15):
            trafficEp1 = 0

    do_usb_test(arch, clk, phy, packets, __file__, seed, level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
