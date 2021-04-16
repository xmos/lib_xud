#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import xmostest
from helpers import do_usb_test, RunUsbTest
from usb_session import UsbSession
from usb_transaction import UsbTransaction

def do_test(arch, clk, phy, data_valid_count, usb_speed, seed, verbose=False):
   
    ep = 2
    address = 1
    start_length = 10
    end_length = 14
    
    session = UsbSession(bus_speed=usb_speed, run_enumeration=False, device_address=address)

    for pktLength in range(10, end_length+1):
        session.add_event(UsbTransaction(session, deviceAddress=address, endpointNumber=ep, endpointType="ISO", direction= "OUT", dataLength=pktLength))

    do_usb_test(arch, clk, phy, usb_speed, [session], __file__, seed, level='smoke', extra_tasks=[], verbose=verbose)

def runtest():
    RunUsbTest(do_test)


