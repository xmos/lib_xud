#!/usr/bin/env python
import xmostest
from helpers import do_usb_test, RunUsbTest
from usb_session import UsbSession
from usb_transaction import UsbTransaction

def do_test(arch, clk, phy, data_valid_count, usb_speed, seed, verbose=False):

    ep = 3 # Note this is a starting EP
    address = 1
    ied = 200

    session = UsbSession(bus_speed = usb_speed, run_enumeration = False, device_address = address)

    for pktLength in range(10, 20):
        session.add_event(UsbTransaction(session, deviceAddress =address, endpointNumber=ep, endpointType="BULK", direction= "IN", dataLength=pktLength, interEventDelay=ied))
        session.add_event(UsbTransaction(session, deviceAddress =address, endpointNumber=ep+1, endpointType="BULK", direction= "IN", dataLength=pktLength, interEventDelay=ied))
        session.add_event(UsbTransaction(session, deviceAddress =address, endpointNumber=ep+2, endpointType="BULK", direction= "IN", dataLength=pktLength, interEventDelay=ied))
        session.add_event(UsbTransaction(session, deviceAddress =address, endpointNumber=ep+3, endpointType="BULK", direction= "IN", dataLength=pktLength, interEventDelay=ied))
        
    do_usb_test(arch, clk, phy, usb_speed, [session], __file__, seed, level='smoke', extra_tasks=[], verbose=verbose)

def runtest():
    RunUsbTest(do_test)
