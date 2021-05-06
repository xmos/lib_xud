#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

import random
from  usb_packet import *
from usb_clock import Clock
from helpers import do_usb_test, get_usb_clk_phy, runall_rx
from usb_clock import Clock
from usb_phy_utmi import UsbPhyUtmi
import Pyxsim
import pytest
import os

def do_test(arch, clk, phy, data_valid_count, usb_speed, seed):
    rand = random.Random()
    rand.seed(seed)

    start_ep = 3
    
    # The inter-frame gap is to give the DUT time to print its output
    packets = []
    address = 1

    data_val = 0;
    pkt_length = 20
    data_pid = 0x3 #DATA0 

    ipg = 200

    for pkt_length in range(10, 20):
        
        #Single EP:
        #317 lowest for valid data (SI)
        #337 for initial DI version
        
        #Multi EP:
        #177 lowest for valid data (DI)
        AppendInToken(packets, start_ep, address, data_valid_count=data_valid_count, inter_pkt_gap=ipg)
        packets.append(RxDataPacket(rand, data_start_val=data_val, data_valid_count=data_valid_count, length=pkt_length, pid=data_pid))
        packets.append(TxHandshakePacket(data_valid_count=data_valid_count))

        AppendInToken(packets, start_ep+1, address, data_valid_count=data_valid_count, inter_pkt_gap=ipg)
        packets.append(RxDataPacket(rand, data_start_val=data_val, data_valid_count=data_valid_count, length=pkt_length, pid=data_pid))
        packets.append(TxHandshakePacket(data_valid_count=data_valid_count))
       
        AppendInToken(packets, start_ep+2, address, data_valid_count=data_valid_count, inter_pkt_gap=ipg)
        packets.append(RxDataPacket(rand, data_start_val=data_val, data_valid_count=data_valid_count, length=pkt_length, pid=data_pid))
        packets.append(TxHandshakePacket(data_valid_count=data_valid_count))
      
        AppendInToken(packets, start_ep+3, address, data_valid_count=data_valid_count, inter_pkt_gap=ipg)
        packets.append(RxDataPacket(rand, data_start_val=data_val, data_valid_count=data_valid_count, length=pkt_length, pid=data_pid))
        packets.append(TxHandshakePacket(data_valid_count=data_valid_count))
       
        data_val = data_val + pkt_length
        data_pid = data_pid ^ 8

    return do_usb_test(arch, clk, phy, usb_speed, packets, __file__, seed, level='smoke', extra_tasks=[])

def test_bulk_tx_multiep():
    random.seed(1)
    for result in runall_rx(do_test):
        assert result
