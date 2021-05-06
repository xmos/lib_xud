#!/usr/bin/env python
# Copyright 2019-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

# Same as simple RX bulk test but some invalid tokens also included

import random
from  usb_packet import *
from usb_clock import Clock
from helpers import do_usb_test, get_usb_clk_phy, runall_rx
from usb_clock import Clock
from usb_phy_utmi import UsbPhyUtmi
import Pyxsim
import pytest
import os

# Single, setup transaction to EP 0

def do_test(arch, clk, phy, data_valid_count, usb_speed, seed):
    rand = random.Random()
    rand.seed(seed)

    address = 1
    ep = 1
    framenumber = 52 # Note, for frame number 52 we expect A5 34 40 on the bus

    packets = []
    dataval = 0;

    # Start with a valid transaction */
    AppendOutToken(packets, ep, address, data_valid_count=data_valid_count)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=10, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    AppendSofToken(packets, framenumber, data_valid_count=data_valid_count)
    AppendSofToken(packets, framenumber+1, data_valid_count=data_valid_count) 
    AppendSofToken(packets, framenumber+2, data_valid_count=data_valid_count)
    AppendSofToken(packets, framenumber+3, data_valid_count=data_valid_count)
    AppendSofToken(packets, framenumber+4, data_valid_count=data_valid_count)

    #Finish with valid transaction 
    dataval += 10
    AppendOutToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=11, pid=0xb)) #DATA1
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    tester = do_usb_test(arch, clk, phy, usb_speed, packets, __file__, seed, level='smoke', extra_tasks=[])

    return tester

def test_sof_basic():
    random.seed(1)
    for result in runall_rx(do_test):
        assert result
