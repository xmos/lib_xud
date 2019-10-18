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

    ep_loopback = 3
    ep_loopback_kill = 2
    address = 1

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    dataval = 0;
    data_pid = usb_packet.PID_DATA0 

    # TODO randomise packet lengths and data
    for pkt_length in range(0, 20):
        
        AppendOutToken(packets, ep_loopback, address)
        packets.append(TxDataPacket(rand, data_start_val=dataval, length=pkt_length, pid=data_pid)) 
        packets.append(RxHandshakePacket())
   
        # 357 was min IPG supported on bulk loopback to not nak
        # For move from sc_xud to lib_xud (14.1.2 tools) had to increase this to 377 
        # Increased again due to setup/out checking 
        AppendInToken(packets, ep_loopback, address, inter_pkt_gap=417)
        packets.append(RxDataPacket(rand, data_start_val=dataval, length=pkt_length, pid=data_pid)) 
        packets.append(TxHandshakePacket())

        data_pid = data_pid ^ 8

    pkt_length = 10

    #Loopback and die..
    AppendOutToken(packets, ep_loopback_kill, address)
    packets.append(TxDataPacket(rand, length=pkt_length, pid=3)) #DATA0
    packets.append(RxHandshakePacket())
   
    AppendInToken(packets, ep_loopback_kill, address, inter_pkt_gap=400)
    packets.append(RxDataPacket(rand, length=pkt_length, pid=3)) #DATA0
    packets.append(TxHandshakePacket())

    do_usb_test(arch, clk, phy, packets, __file__, seed,
               level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
