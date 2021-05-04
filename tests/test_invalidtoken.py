#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

# Same as simple RX bulk test but some invalid tokens also included

import random
from  usb_packet import *
from usb_clock import Clock
from helpers import do_usb_test, get_usb_clk_phy
from usb_clock import Clock
from usb_phy_utmi import UsbPhyUtmi
import Pyxsim
import pytest
import os

ARCHITECTURE_CHOICES = ['xs2', 'xs3']
BUSSPEED_CHOICES = ['FS', 'HS']
args = {'arch':'xs3'}
tester_list = []


# Single, setup transaction to EP 0

def do_test(arch, clk, phy, data_valid_count, usb_speed, seed):
    rand = random.Random()
    rand.seed(seed)

    address = 1
    ep = 1

    # The inter-frame gap is to give the DUT time to print its output
    packets = []

    dataval = 0;

    # Reserved PID
    packets.append(TokenPacket( 
        data_valid_count=data_valid_count,
        inter_pkt_gap=2000, 
        pid=0x0,
        address=address, 
        endpoint=ep))
    
    # Valid IN but not for us..
    packets.append(TokenPacket( 
        data_valid_count=data_valid_count,
        inter_pkt_gap=200, 
        pid=0x69,
        address=address+1, 
        endpoint=ep,
        valid=False))   #Note, the valid is the valid flag for xs2

  # Valid OUT but not for us..
    packets.append(TokenPacket( 
        data_valid_count=data_valid_count,
        inter_pkt_gap=200, 
        pid=0xe1,
        address=address+1, 
        endpoint=ep,
        valid=False))

    AppendOutToken(packets, ep, address, data_valid_count=data_valid_count)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=10, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    # Valid SETUP but not for us..
    packets.append(TokenPacket( 
        data_valid_count=data_valid_count,
        inter_pkt_gap=200, 
        pid=0x2d,
        address=address+2, 
        endpoint=ep,
        valid=False))

    # Note, quite big gap to allow checking.
    
    dataval += 10
    AppendOutToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=11, pid=0xb)) #DATA1
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    # Valid PING but not for us..
    packets.append(TokenPacket( 
        data_valid_count=data_valid_count,
        inter_pkt_gap=200, 
        pid=0xb4,
        address=address+3, 
        endpoint=ep,
        valid=False))

    dataval += 11
    AppendOutToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=12, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    dataval += 12
    AppendOutToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=13, pid=0xb)) #DATA1
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))

    dataval += 13
    AppendOutToken(packets, ep, address, data_valid_count=data_valid_count, inter_pkt_gap=6000)
    packets.append(TxDataPacket(rand, data_start_val=dataval, data_valid_count=data_valid_count, length=14, pid=0x3)) #DATA0
    packets.append(RxHandshakePacket(data_valid_count=data_valid_count))


    tester = do_usb_test(arch, clk, phy, usb_speed, packets, __file__, seed, level='smoke', extra_tasks=[])

    return tester

def run_on(**kwargs):

    for name,value in kwargs.items():
        arg_value = args.get(name)
        if arg_value is not None and value != arg_value:
            return False

    return True

@pytest.fixture
def runall_rx(capfd):
    testname,extension = os.path.splitext(os.path.basename(__file__))
    seed = random.randint(0, sys.maxsize)

    data_valid_count = {'FS': 39, "HS": 0}

    for _arch in ARCHITECTURE_CHOICES:
        for _busspeed in BUSSPEED_CHOICES:
            if run_on(arch=_arch):
                if run_on(busspeed=_busspeed):
                    (clk_60, usb_phy) = get_usb_clk_phy(verbose=False, arch=_arch)
                    tester_list.append(do_test(_arch, clk_60, usb_phy, data_valid_count[_busspeed], _busspeed, seed))
    captured = capfd.readouterr()
    caps = captured.out.split("\n")
    
    return Pyxsim.run_tester(caps,tester_list)


def test_invalidtoken(runall_rx):
    random.seed(1)
    for result in runall_rx:
        assert result
