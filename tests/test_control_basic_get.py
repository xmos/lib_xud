#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

import random
from usb_packet import *
import usb_packet
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


    ep = 0
    address = 1 

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    # SETUP transaction
    AppendSetupToken(packets, ep, address, data_valid_count=data_valid_count)
    packets.append(TxDataPacket(rand, data_valid_count=data_valid_count, length=8, pid=3))
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    # IN transaction
    # Note, quite big gap to avoid nak
    AppendInToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap = 10000)
    packets.append(RxDataPacket(rand, data_valid_count=data_valid_count, length=10, pid=0xb))
    packets.append(TxHandshakePacket(data_valid_count=data_valid_count))
 
    # Send 0 length OUT transaction 
    AppendOutToken(packets, ep, address, data_valid_count=data_valid_count)
    packets.append(TxDataPacket(rand, data_valid_count=data_valid_count, length=0, pid=PID_DATA1))
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    return do_usb_test(arch, clk, phy, usb_speed, packets, __file__, seed, level='smoke', extra_tasks=[])

def test_control_basic_get():
    random.seed(1)
    for result in runall_rx(do_test):
        assert result
