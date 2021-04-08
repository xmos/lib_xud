#!/usr/bin/env python
import xmostest
from  usb_packet import TokenPacket, USB_PID
from helpers import do_usb_test, RunUsbTest
from usb_session import UsbSession
from usb_transaction import UsbTransaction

def do_test(arch, clk, phy, data_valid_count, usb_speed, seed, verbose=False):

    address = 1
    ep = 1

    # The large inter-event delay is to give the DUT time to perform checking
    ied = 500

    session = UsbSession(bus_speed = usb_speed, run_enumeration = False, device_address = address)

    for length in range(10, 15):

        session.add_event(UsbTransaction(session, deviceAddress = address, endpointNumber=ep, endpointType="BULK", direction= "OUT", dataLength=length, interEventDelay=ied))
        
        # Simulate missing data payload 
        if length == 11:
            session.add_event(TokenPacket(endpoint=ep, address = address, pid=USB_PID["OUT"]))

    do_usb_test(arch, clk, phy, usb_speed, [session], __file__, seed, level='smoke', extra_tasks=[], verbose=verbose)

def runtest():
    RunUsbTest(do_test)
