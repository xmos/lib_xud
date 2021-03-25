#!/usr/bin/env python
# Copyright (c) 2016-2019, XMOS Ltd, All rights reserved

import random
import xmostest
from  usb_packet import *
from usb_clock import Clock
from helpers import do_usb_test, runall_rx

def do_test(arch, clk, phy, data_valid_count, usb_speed, seed):
    
    rand = random.Random()
    rand.seed(seed)

    address = 1

    ep_loopback = 3
    ep_loopback_kill = 2

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    dataval = 0;
    data_pid = 0x3 #DATA0 

    ipg = 6000

    for pkt_length in range(200, 204):
        
        AppendOutToken(packets, ep_loopback, address, data_valid_count=data_valid_count)
        packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=pkt_length, pid=data_pid)) #DATA0
   
        #XXwas min IPG supported on iso loopback to not nak
        #This was 420, had to increase when moved to lib_xud (14.1.2 tools)
        # increased again from 437 when SETUP/OUT checking added
        # increaed from 477 when adding xs3
        AppendInToken(packets, ep_loopback, address, data_valid_count=data_valid_count, inter_pkt_gap=498)
        packets.append(RxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=pkt_length, pid=data_pid)) #DATA0

        #No toggle for Iso

    pkt_length = 10

    #Loopback and die..
    AppendOutToken(packets, ep_loopback_kill, address, data_valid_count=data_valid_count)
    packets.append(TxDataPacket(rand, data_valid_count=data_valid_count, length=pkt_length, pid=3)) #DATA0
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))
   
    AppendInToken(packets, ep_loopback_kill, address, data_valid_count=data_valid_count, inter_pkt_gap=ipg)
    packets.append(RxDataPacket(rand, data_valid_count=data_valid_count, length=pkt_length, pid=3)) #DATA0
    packets.append(TxHandshakePacket(data_valid_count=data_valid_count))


    do_usb_test(arch, clk, phy, usb_speed, packets, __file__, seed,
               level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
