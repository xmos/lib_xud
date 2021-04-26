#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

import random
import xmostest
from  usb_packet import *
import usb_packet
from usb_clock import Clock
# from helpers import do_usb_test, runall_rx
from helpers import do_usb_test, get_usb_clk_phy
from usb_clock import Clock
# from usb_phy import UsbPhy
from usb_phy_shim import UsbPhyShim
from usb_phy_utmi import UsbPhyUtmi
import pytest
from xmostest import outcapture
import os

ARCHITECTURE_CHOICES = ['xs2', 'xs3']
BUSSPEED_CHOICES = ['FS', 'HS']
args = {'arch':'xs3'}
tester_list = []

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

    tester = do_usb_test(arch, clk, phy, usb_speed, packets, __file__, seed,
               level='smoke', extra_tasks=[])
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
    binary = '{testname}/bin/{arch}/{testname}_{arch}.xe'.format(testname=testname, arch=args.get('arch'))
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
    remove_element = [index for index, element in enumerate(caps) if element.strip() == binary]
    if caps[-1] == '':
        caps = caps[:-1]
    result = []
    if len(remove_element) > 1:
        i = 0
        while(i<len(remove_element)):
            if i+1 == len(remove_element):
                re_cap = caps[remove_element[i]+1:]
            else:
                re_cap = caps[remove_element[i]+1:remove_element[i+1]]
            result.append(tester_list[i]._run(re_cap)) 
            i += 1
    else:
        caps = caps[remove_element[0]:]
        result.append(tester_list[0]._run(caps)) 
    return result


def test_bulk_loopback(runall_rx):
    random.seed(1)
    for result in runall_rx:
        assert result