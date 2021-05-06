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

# Single, setup transaction to EP 0

def do_test(arch, tx_clk, tx_phy, data_valid_count, usb_speed, seed):
    rand = random.Random()
    rand.seed(seed)

    ep = 3
    address = 1

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    dataval = 0;

    AppendInToken(packets, ep, address, data_valid_count=data_valid_count)
    packets.append(RxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=10, pid=0x3)) #DATA0

    dataval += 10
    AppendInToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap=2000)
    packets.append(RxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=11, pid=0x3)) #DATA0

    dataval += 11
    AppendInToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap=2000)
    packets.append(RxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=12, pid=0x3)) #DATA0

    dataval += 12
    AppendInToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap=2000)
    packets.append(RxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=13, pid=0x3)) #DATA0

    dataval += 13
    AppendInToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap=2000)
    packets.append(RxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=14, pid=0x3)) #DATA0

    return do_usb_test(arch, tx_clk, tx_phy, usb_speed, packets, __file__, seed, level='smoke', extra_tasks=[])

def test_iso_tx_basic():
    random.seed(1)
    for result in runall_rx(do_test):
        assert result
