#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import Pyxsim
from  usb_packet import *
import usb_packet
from helpers import do_usb_test, RunUsbTest
from usb_session import UsbSession
from usb_transaction import UsbTransaction
import pytest

def do_test(arch, clk, phy, data_valid_count, usb_speed, seed, verbose=False):

    ep = 1
    address = 1
    ied = 500
   
    trafficAddress1 = 0;
    trafficAddress2 = 127;
    trafficEp1 = 15;
    trafficEp2 = 0;

    session = UsbSession(bus_speed = usb_speed, run_enumeration = False, device_address = address)

    for pktLength in range(10, 20):
        
        session.add_event(UsbTransaction(session, deviceAddress=trafficAddress1, endpointNumber=trafficEp1, endpointType="BULK", direction= "OUT", dataLength=pktLength, 
            interEventDelay=ied))

        session.add_event(UsbTransaction(session, deviceAddress=address, endpointNumber=ep, endpointType="BULK", direction= "OUT", dataLength=pktLength, 
            interEventDelay=ied))

        session.add_event(UsbTransaction(session, deviceAddress=trafficAddress2, endpointNumber=trafficEp2, endpointType="BULK", direction= "OUT", dataLength=pktLength, 
            interEventDelay=ied))

        trafficEp1 = trafficEp1 - 1
        if(trafficEp1 < 0):
            trafficEp1 = 15
        
        trafficEp2 + trafficEp2 + 1
        if(trafficEp1 > 15):
            trafficEp1 = 0
    
    return do_usb_test(arch, clk, phy, usb_speed, [session], __file__, seed, level='smoke', extra_tasks=[], verbose=verbose)

def test_bulk_rx_traffic():
    for result in RunUsbTest(do_test):
        assert result

