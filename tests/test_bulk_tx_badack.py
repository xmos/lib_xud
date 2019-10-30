#!/usr/bin/env python
import random
import xmostest
from  usb_packet import *
import usb_packet
from usb_clock import Clock
from helpers import do_usb_test, runall_rx


def do_test(arch, tx_clk, tx_phy, seed):
    rand = random.Random()
    rand.seed(seed)

    ep = 1
    address = 1

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    dataval = 0;

    pid = PID_DATA0;

    pktlength = 10

    for i in range(0, 4):

        if(i == 2):
            AppendInToken(packets, ep, address, inter_pkt_gap=4000)
            packets.append(RxDataPacket(rand, data_start_val=dataval, length=pktlength, pid=pid)) #DATA1
            packets.append(TxHandshakePacket(pid=0xff))

        AppendInToken(packets, ep, address, inter_pkt_gap=4000)
        packets.append(RxDataPacket(rand, data_start_val=dataval, length=pktlength, pid=pid)) #DATA1
        packets.append(TxHandshakePacket())
        
        if(pid == usb_packet.PID_DATA1):
            pid = usb_packet.PID_DATA0;
        else:
            pid = usb_packet.PID_DATA1;

        dataval += pktlength
        pktlength += 1

    # Note, quite big gap to allow checking.
    do_usb_test(arch, tx_clk, tx_phy, packets, __file__, seed,
               level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
