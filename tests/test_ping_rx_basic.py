#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

# Basic check of PING functionality

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

    address = 1
    ep = 1

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    dataval = 0;

    # Ping EP 2, expect NAK
    AppendPingToken(packets, 2, address, data_valid_count=data_valid_count)
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count, pid=0x5a))

    # And again
    AppendPingToken(packets, 2, address, data_valid_count=data_valid_count)
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count, pid=0x5a))

    # Send packet to EP 1, xCORE should mark EP 2 as ready
    AppendOutToken(packets, ep, address, data_valid_count=data_valid_count)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=10, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))
    
    # Ping EP 2 again - expect ACK
    AppendPingToken(packets, 2, address, data_valid_count=data_valid_count, inter_pkt_gap=6000)
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    # And again..
    AppendPingToken(packets, 2, address, data_valid_count=data_valid_count)
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    # Send out to EP 2.. expect ack
    AppendOutToken(packets, 2,address, data_valid_count=data_valid_count,  inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=10, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    # Re-Ping EP 2, expect NAK
    AppendPingToken(packets, 2, address, data_valid_count=data_valid_count)
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count, pid=0x5a))

    # And again
    AppendPingToken(packets, 2, address, data_valid_count=data_valid_count)
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count, pid=0x5a))

    # Send a packet to EP 1 so the DUT knows it can exit.
    AppendOutToken(packets, ep, address, data_valid_count=data_valid_count)
    packets.append(TxDataPacket(rand, data_start_val=dataval+10, data_valid_count=data_valid_count, length=10, pid=0x3^8)) #DATA1
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    return do_usb_test(arch, clk, phy, usb_speed, packets, __file__, seed,level='smoke', extra_tasks=[])

def test_ping_rx_basic():
    random.seed(1)
    for result in runall_rx(do_test):
        assert result
