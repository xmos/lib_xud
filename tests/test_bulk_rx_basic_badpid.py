#!/usr/bin/env python

# Rx out of seq (but valid.. ) data PID

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

    ipg = 500

    AppendOutToken(packets, ep, address)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=10, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket())
    
    dataval += 10
    AppendOutToken(packets, ep, address, inter_pkt_gap=ipg)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=11, pid=0xb)) #DATA1
    packets.append(RxHandshakePacket())

    #Pretend the ACK went missing. Re-send same packet. xCORE should ACK but throw pkt away
    AppendOutToken(packets, ep, address, inter_pkt_gap=ipg)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=11, pid=0xb)) #DATA1
    packets.append(RxHandshakePacket())

    dataval += 11
    AppendOutToken(packets, ep, address, inter_pkt_gap=ipg)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=12, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket())

    dataval += 12
    AppendOutToken(packets, ep, address, inter_pkt_gap=ipg)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=13, pid=0xb)) #DATA1
    packets.append(RxHandshakePacket())

    dataval += 13
    AppendOutToken(packets, ep, address, inter_pkt_gap=ipg)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=14, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket())

    do_usb_test(arch, clk, phy, packets, __file__, seed, level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
