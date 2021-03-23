#!/usr/bin/env python

# Same as simple RX bulk test but some invalid tokens also included

import random
import xmostest
from  usb_packet import *
from usb_clock import Clock
from helpers import do_usb_test, runall_rx


# Single, setup transaction to EP 0

def do_test(arch, clk, phy, data_valid_count, usb_speed, seed):
    rand = random.Random()
    rand.seed(seed)

    address = 1
    ep = 1

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    dataval = 0;

    # Reserved PID
    packets.append(TokenPacket( 
        data_valid_count=data_valid_count,
        inter_pkt_gap=2000, 
        pid=0x0,
        address=address, 
        endpoint=ep))
    
    # Valid IN but not for us..
    packets.append(TokenPacket( 
        data_valid_count=data_valid_count,
        inter_pkt_gap=200, 
        pid=0x69,
        address=address+1, 
        endpoint=ep,
        valid=False))   #Note, the valid is the valid flag for xs2

  # Valid OUT but not for us..
    packets.append(TokenPacket( 
        data_valid_count=data_valid_count,
        inter_pkt_gap=200, 
        pid=0xe1,
        address=address+1, 
        endpoint=ep,
        valid=False))

    AppendOutToken(packets, ep, address, data_valid_count=data_valid_count)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=10, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    # Valid SETUP but not for us..
    packets.append(TokenPacket( 
        data_valid_count=data_valid_count,
        inter_pkt_gap=200, 
        pid=0x2d,
        address=address+2, 
        endpoint=ep,
        valid=False))

    # Note, quite big gap to allow checking.
    
    dataval += 10
    AppendOutToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=11, pid=0xb)) #DATA1
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    # Valid PING but not for us..
    packets.append(TokenPacket( 
        data_valid_count=data_valid_count,
        inter_pkt_gap=200, 
        pid=0xb4,
        address=address+3, 
        endpoint=ep,
        valid=False))

    dataval += 11
    AppendOutToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=12, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    dataval += 12
    AppendOutToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=13, pid=0xb)) #DATA1
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    dataval += 13
    AppendOutToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=14, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))


    do_usb_test(arch, clk, phy, usb_speed, packets, __file__, seed, level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
