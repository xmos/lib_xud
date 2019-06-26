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

    packets = []
    dataval = 0;


    # Start with a valid transaction */
    AppendOutToken(packets, ep, address)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=10, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket())

    # tmp hack for xs2 - for xs2 the shim will throw away the short token and it will never be seen by the xCORE

    if arch == 'xs3':
        # Create a short token, only PID and 2nd byte 
        shorttoken = TxPacket(pid=0xe1, data_bytes = [0x81], inter_pkt_gap=100)
        packets.append(shorttoken)

    #Finish with valid transaction 
    dataval += 10
    AppendOutToken(packets, ep, address, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=11, pid=0xb)) #DATA1
    packets.append(RxHandshakePacket())

    do_usb_test(arch, clk, phy, packets, __file__, seed, level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
