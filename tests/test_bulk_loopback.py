#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

import random
from  usb_packet import *
import usb_packet
from helpers import do_usb_test, get_usb_clk_phy, runall_rx
from usb_clock import Clock
from usb_phy_utmi import UsbPhyUtmi
import Pyxsim
import pytest
import os

def do_test(arch, clk, phy, data_valid_count, usb_speed, seed):
    
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
        
        AppendOutToken(packets, ep_loopback, address, data_valid_count=data_valid_count)
        packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=pkt_length, pid=data_pid)) 
        packets.append(RxHandshakePacket(data_valid_count=data_valid_count))
   
        # 357 was min IPG supported on bulk loopback to not nak
        # For move from sc_xud to lib_xud (14.1.2 tools) had to increase this to 377 
        # Increased again due to setup/out checking 
        AppendInToken(packets, ep_loopback, address, data_valid_count=data_valid_count, inter_pkt_gap=417)
        packets.append(RxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=pkt_length, pid=data_pid)) 
        packets.append(TxHandshakePacket(data_valid_count=data_valid_count))

        data_pid = data_pid ^ 8

    pkt_length = 10

    #Loopback and die..
    AppendOutToken(packets, ep_loopback_kill, address, data_valid_count=data_valid_count)
    packets.append(TxDataPacket(rand, data_valid_count=data_valid_count, length=pkt_length, pid=3)) #DATA0
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))
   
    AppendInToken(packets, ep_loopback_kill, address, data_valid_count=data_valid_count, inter_pkt_gap=400)
    packets.append(RxDataPacket(rand, data_valid_count=data_valid_count, length=pkt_length, pid=3)) #DATA0
    packets.append(TxHandshakePacket(data_valid_count=data_valid_count))

    return do_usb_test(arch, clk, phy, usb_speed, packets, __file__, seed,
               level='smoke', extra_tasks=[])

def test_bulk_loopback():
    random.seed(1)
    for result in runall_rx(do_test):
        assert result