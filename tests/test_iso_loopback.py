#!/usr/bin/env python

import random
import xmostest
from  usb_packet import *
from usb_clock import Clock
from helpers import do_usb_test, runall_rx

def do_test(arch, clk, phy, seed):
    
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
        
        AppendOutToken(packets, ep_loopback, address)
        packets.append(TxDataPacket(rand, data_start_val=dataval, length=pkt_length, pid=data_pid)) #DATA0
   
        #XXwas min IPG supported on iso loopback to not nak
        #This was 420, had to increase when moved to lib_xud (14.1.2 tools)
        # increased again from 437 when SETUP/OUT checking added
        # increaed from 477 when adding xs3
        AppendInToken(packets, ep_loopback, address, inter_pkt_gap=498)
        packets.append(RxDataPacket(rand, data_start_val=dataval, length=pkt_length, pid=data_pid)) #DATA0

        #No toggle for Iso

    pkt_length = 10

    #Loopback and die..
    AppendOutToken(packets, ep_loopback_kill, address)
    packets.append(TxDataPacket(rand, length=pkt_length, pid=3)) #DATA0
    packets.append(RxHandshakePacket())
   
    AppendInToken(packets, ep_loopback_kill, address, inter_pkt_gap=ipg)
    packets.append(RxDataPacket(rand, length=pkt_length, pid=3)) #DATA0
    packets.append(TxHandshakePacket())


    do_usb_test(arch, clk, phy, packets, __file__, seed,
               level='smoke', extra_tasks=[])

def runtest():
    random.seed(1)
    runall_rx(do_test)
