##!/usr/bin/env python
import xmostest
from  usb_packet import *
import usb_packet
from helpers import do_usb_test, RunUsbTest
from usb_session import UsbSession
from usb_transaction import UsbTransaction

def do_test(arch, clk, phy, data_valid_count, usb_speed, seed, verbose=False):

    address = 1

    session = UsbSession(bus_speed = usb_speed, run_enumeration = False, device_address = address)

    for pktLength in range(10, 20):
        
        session.add_event(UsbTransaction(session, deviceAddress = address, endpointNumber=3, endpointType="BULK", direction= "OUT", dataLength=pktLength))
        session.add_event(UsbTransaction(session, deviceAddress = address, endpointNumber=4, endpointType="BULK", direction= "OUT", dataLength=pktLength))
        session.add_event(UsbTransaction(session, deviceAddress = address, endpointNumber=5, endpointType="BULK", direction= "OUT", dataLength=pktLength))
        session.add_event(UsbTransaction(session, deviceAddress = address, endpointNumber=6, endpointType="BULK", direction= "OUT", dataLength=pktLength))
    
    do_usb_test(arch, clk, phy, usb_speed, [session], __file__, seed, level='smoke', extra_tasks=[], verbose=verbose)

def runtest():
    RunUsbTest(do_test)
