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

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    dataval = 0;

    # Reserved PID
    packets.append(TokenPacket( 
        inter_pkt_gap=2000, 
        pid=0x0,
        address=address, 
        endpoint=ep))
    
    # Valid IN but not for us..
    packets.append(TokenPacket( 
        inter_pkt_gap=200, 
        pid=0x69,
        address=address+1, 
        endpoint=ep,
        valid=False))   #Note, the valid is the valid flag for xs2

  # Valid OUT but not for us..
    packets.append(TokenPacket( 
        inter_pkt_gap=200, 
        pid=0xe1,
        address=address+1, 
        endpoint=ep,
        valid=False))

    AppendOutToken(packets, ep, address)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=10, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket())

    # Valid SETUP but not for us..
    packets.append(TokenPacket( 
        inter_pkt_gap=200, 
        pid=0x2d,
        address=address+2, 
        endpoint=ep,
        valid=False))

    # Note, quite big gap to allow checking.
    
    dataval += 10
    AppendOutToken(packets, ep, address, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=11, pid=0xb)) #DATA1
    packets.append(RxHandshakePacket())

    # Valid PING but not for us..
    packets.append(TokenPacket( 
        inter_pkt_gap=200, 
        pid=0xb4,
        address=address+3, 
        endpoint=ep,
        valid=False))

    dataval += 11
    AppendOutToken(packets, ep, address, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=12, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket())

    dataval += 12
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
