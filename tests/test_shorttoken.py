#!/usr/bin/env python
# Copyright 2019-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

import xmostest
from usb_packet import TxPacket, USB_PID 
from helpers import do_usb_test, RunUsbTest
from usb_session import UsbSession
from usb_transaction import UsbTransaction

def do_test(arch, clk, phy, data_valid_count, usb_speed, seed, verbose=False):

    address = 1
    ep = 1

    session = UsbSession(bus_speed=usb_speed, run_enumeration=False, device_address = address)

    # Start with a valid transaction */
    session.add_event(UsbTransaction(session, deviceAddress=address, endpointNumber=ep, endpointType="BULK", direction= "OUT", dataLength=10))

    # tmp hack for xs2 - for xs2 the shim will throw away the short token and it will never be seen by the xCORE
    if arch == 'xs3':
        # Create a short token, only PID and 2nd byte 
        shorttoken = TxPacket(pid=USB_PID["OUT"], data_bytes = [0x81], data_valid_count=data_valid_count, interEventDelay=100)
        session.add_event(shorttoken)

    #Finish with valid transaction 
    session.add_event(UsbTransaction(session, deviceAddress=address, endpointNumber=ep, endpointType="BULK", direction= "OUT", dataLength=11, interEventDelay=6000))

    do_usb_test(arch, clk, phy, usb_speed, [session], __file__, seed, level='smoke', extra_tasks=[])

def runtest():
    RunUsbTest(do_test)
