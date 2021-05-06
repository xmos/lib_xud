#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

import random
from  usb_packet import *
import usb_packet
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

    dev_address = 1
    ep = 1

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    dataval = 0;
    
    # Good OUT transaction
    AppendOutToken(packets, ep, dev_address, data_valid_count=data_valid_count)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=10, pid=usb_packet.PID_DATA0)) 
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    # Note, quite big gap to allow checking.
    
    # Another good OUT transaction
    dataval += 10
    AppendOutToken(packets, ep, dev_address, data_valid_count=data_valid_count, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=11, pid=usb_packet.PID_DATA1)) 
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    dataval += 11
    AppendOutToken(packets, ep, dev_address, data_valid_count=data_valid_count, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=12, bad_crc=True, pid=usb_packet.PID_DATA0))
    # Bad CRC - dont expect ACK
    #packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    #Due to bad CRC, XUD will not ACK and expect a resend of the same packet - so dont change PID
    dataval += 12
    AppendOutToken(packets, ep, dev_address, data_valid_count=data_valid_count, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=13, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    # PID toggle as normal
    dataval += 13
    AppendOutToken(packets, ep, dev_address, data_valid_count=data_valid_count, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=14, pid=0xb)) #DATA1
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))


    tester = do_usb_test(arch, tx_clk, tx_phy, usb_speed, packets, __file__, seed,
               level='smoke', extra_tasks=[])
    
    return tester

def test_bulk_rx_basic_badcrc32():
    random.seed(1)
    for result in runall_rx(do_test):
        assert result
