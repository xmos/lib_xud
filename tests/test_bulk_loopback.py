#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

import random
import xmostest
from  usb_packet import *
import usb_packet
from usb_clock import Clock
# from helpers import do_usb_test, runall_rx
from helpers import do_usb_test
from usb_clock import Clock
# from usb_phy import UsbPhy
# from usb_phy_shim import UsbPhyShim
from usb_phy_utmi import UsbPhyUtmi
import pytest
# import xmostest.outcapture
from xmostest import outcapture

ARCHITECTURE_CHOICES = ['xs2', 'xs3']
BUSSPEED_CHOICES = ['FS', 'HS']
args = {'arch':'xs3'}
result = []

# @pytest.fixture
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

    res = do_usb_test(arch, clk, phy, usb_speed, packets, __file__, seed,
               level='smoke', extra_tasks=[])
    global result
    result.append(res)
    

def get_usb_clk_phy(verbose=True, test_ctrl=None, do_timeout=True,
                       complete_fn=None, expect_loopback=False,
                       dut_exit_time=350000, arch='xs2'):

    if arch=='xs2':
        clk = Clock('XS1_USB_CLK', Clock.CLK_60MHz)
        phy = UsbPhyUtmi('XS1_USB_RXD',
                         'XS1_USB_RXA', #rxa
                         'XS1_USB_RXV', #rxv
                         'XS1_USB_RXE', #rxe
                         'tile[0]:XS1_PORT_8A', #txd
                         'tile[0]:XS1_PORT_1K', #txv
                         'tile[0]:XS1_PORT_1H', #txrdy
                         'XS1_USB_LS0', 
                         'XS1_USB_LS1',
                         clk,
                         verbose=verbose, test_ctrl=test_ctrl,
                         do_timeout=do_timeout, complete_fn=complete_fn,
                         expect_loopback=expect_loopback,
                         dut_exit_time=dut_exit_time)
 
    elif arch=='xs3':
        clk = Clock('XS1_USB_CLK', Clock.CLK_60MHz)
        phy = UsbPhyUtmi('XS1_USB_RXD',
                         'XS1_USB_RXA', #rxa
                         'XS1_USB_RXV', #rxv
                         'XS1_USB_RXE', #rxe
                         'tile[0]:XS1_PORT_8A', #txd
                         'tile[0]:XS1_PORT_1K', #txv
                         'tile[0]:XS1_PORT_1H', #txrdy
                         'XS1_USB_LS0', 
                         'XS1_USB_LS1',
                         clk,
                         verbose=verbose, test_ctrl=test_ctrl,
                         do_timeout=do_timeout, complete_fn=complete_fn,
                         expect_loopback=expect_loopback,
                         dut_exit_time=dut_exit_time)

    else:
        raise ValueError("Invalid architecture: " + arch)
        
    return (clk, phy)

def run_on(**kwargs):

    for name,value in kwargs.items():
        arg_value = args.get(name)
        if arg_value is not None and value != arg_value:
            return False

    return True

# @pytest.fixture
def runall_rx():
   
    # seed = args.seed if args.seed else random.randint(0, sys.maxsize)
    seed = random.randint(0, sys.maxsize)

    data_valid_count = {'FS': 39, "HS": 0}

    for _arch in ARCHITECTURE_CHOICES:
        for _busspeed in BUSSPEED_CHOICES:
            if run_on(arch=_arch):
                if run_on(busspeed=_busspeed):
                    (clk_60, usb_phy) = get_usb_clk_phy(verbose=False, arch=_arch)
                    do_test(_arch, clk_60, usb_phy, data_valid_count[_busspeed], _busspeed, seed)

# def runtest():
#     random.seed(1)
#     outcapture.init_output_redirection()
#     runall_rx(do_test)

if __name__ == "__main__":
    random.seed(1)
    # outcapture.init_output_redirection()
    runall_rx()
    # outcapture.complete_output_redirection()
    # for result, product, group, test in result:
    #     if result == True:
    #         s = "%s::%s::%s"%(product, group, test)
    #         print(("{:<%d} {}"%80).format(s, 'PASS'))

# def test_bulk_loop(runall_rx):
#     random.seed(1)
#     outcapture.init_output_redirection()
#     runall_rx()
#     outcapture.complete_output_redirection()
#     for result, product, group, test in result:
#         # if result == True:
#         #     s = "%s::%s::%s"%(product, group, test)
#         #     print(("{:<%d} {}"%80).format(s, 'PASS'))
#         assert result