#!/usr/bin/env python

import random
import xmostest
from  usb_packet import *
import usb_packet
from usb_clock import Clock
from helpers import do_usb_test, runall_rx


# Single, setup transaction to EP 0

def do_test(arch, tx_clk, tx_phy, seed):
    rand = random.Random()
    rand.seed(seed)

    dev_address = 1
    ep = 1

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    dataval = 0;
    
    # Good OUT transaction
    AppendOutToken(packets, ep, dev_address)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=10, pid=usb_packet.PID_DATA0)) 
    packets.append(RxHandshakePacket())

    # Note, quite big gap to allow checking.
    
    # Another good OUT transaction
    dataval += 10
    AppendOutToken(packets, ep, dev_address, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=11, pid=usb_packet.PID_DATA1)) 
    packets.append(RxHandshakePacket())

    dataval += 11
    AppendOutToken(packets, ep, dev_address, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=12, bad_crc=True, pid=usb_packet.PID_DATA0))
    # Bad CRC - dont expect ACK
    #packets.append(RxHandshakePacket())

    #Due to bad CRC, XUD will not ACK and expect a resend of the same packet - so dont change PID
    dataval += 12
    AppendOutToken(packets, ep, dev_address, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=13, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket())

    # PID toggle as normal
    dataval += 13
    AppendOutToken(packets, ep, dev_address, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, length=14, pid=0xb)) #DATA1
    packets.append(RxHandshakePacket())


    do_usb_test(arch, tx_clk, tx_phy, packets, __file__, seed,
               level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
